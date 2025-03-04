#!/bin/sh

#set -o pipefail
#set -o nounset
#set -o errexit
set -x

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}
err_report() {
    echo "Exited with error on line $1"
}
trap 'err_report $LINENO' ERR

IFS=$'\n\t'

function print_help {
    echo "usage: $0 [options]"
    echo "Bootstraps a node into a RKE2 cluster"
    echo ""
    echo "-h,--help print this help"
    echo "--type Type of node to bootstrap server, agent or leader (default: agent)"
    echo "--server_url server_url"
    echo "--token token"
    echo "--bucket bucket"
}

POSITIONAL=()
TYPE="agent"
CCM="true"
SERVER_URL=""
server_url=""
bucket=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            print_help
            exit 1
            ;;
        --type)
            TYPE="$2"
            shift
            shift
            ;;
        --server_url)
            server_url="$2"
            shift
            shift
            ;;
        --token)
            token="$2"
            shift
            shift
            ;;
        --bucket)
            bucket="$2"
            shift
            shift
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done


set +u
set -- "${POSITIONAL[@]}" # restore positional parameters
set -u

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}
upload() {
  # Wait for kubeconfig to exist, then upload to s3 bucket
  retries=10

  while [ ! -f /etc/rancher/rke2/rke2.yaml ]; do
    sleep 10
    if [ "$retries" = 0 ]; then
      fatal "Failed to create kubeconfig"
    fi
    ((retries--))
  done

  # Replace localhost with server url and upload to s3 bucket
  sed "s/127.0.0.1/${server_url}/g" /etc/rancher/rke2/rke2.yaml | aws s3 cp - "s3://${bucket}/rke2.yaml" --content-type "text/yaml"
}


# The most simple "leader election" you've ever seen in your life
elect_leader() {
  # Fetch other running instances in ASG
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  instance_id=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
  asg_name=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$instance_id" --query 'AutoScalingInstances[*].AutoScalingGroupName' --output text)
  instances=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name" --query 'AutoScalingGroups[*].Instances[?HealthStatus==`Healthy`].InstanceId' --output text)

  # Simply identify the leader as the first of the instance ids sorted alphanumerically
  leader=$(echo $instances | tr ' ' '\n' | sort -n | head -n1)

  info "Current instance: $instance_id | Leader instance: $leader"

  if [ "$instance_id" = "$leader" ]; then
    TYPE="leader"
    info "Electing as cluster leader"
  else
    info "Electing as joining server"
  fi
}

identify() {
  # Default to server
  TYPE="server"
  http_code=0
  supervisor_status=0

  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  curl  -vsk  https://internal-demo-lztpn-1019475120.us-east-1.elb.amazonaws.com:9345/ping
  if [ $? -ne 0 ]; then 
    echo "The command failed with exit status $?" 
    elect_leader
  else 
  supervisor_status=$(curl --write-out '%%{http_code}' -sk --output /dev/null https://${server_url}:9345/ping)

  if [ "$supervisor_status" -ne 200 ]; then
    info "API server unavailable, performing simple leader election"
    elect_leader
  else
    info "API server available, identifying as server joining existing cluster"
  fi
  fi 
}

cp_wait() {
  while true; do
    supervisor_status=$(curl --write-out '%{http_code}' -sk --output /dev/null https://${server_url}:9345/ping)
    if [ "$supervisor_status" -eq 200 ]; then
      info "Cluster is ready"

      # Let things settle down for a bit, not required
      # TODO: Remove this after some testing
      sleep 10
      break
    fi
    info "Waiting for cluster to be ready..."
    sleep 10
  done
}

leader_wait() {
  export PATH=$PATH:/var/lib/rancher/rke2/bin
  export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

  while true; do
    info "$(timestamp) Waiting for kube-apiserver..."
    if timeout 1 bash -c "true <>/dev/tcp/localhost/6443" 2>/dev/null; then
        break
    fi
    echo "Waiting for api server to come up"
    sleep 5
  done


  nodereadypath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
  until kubectl get nodes --selector='node-role.kubernetes.io/master' -o jsonpath="$nodereadypath" | grep -E "Ready=True"; do
    info "$(timestamp) Waiting for servers to be ready..."
    sleep 5
  done

  info "$(timestamp) all kube-system deployments are ready!"
}

{
echo $TYPE
echo $token
echo $server_url
if [  $TYPE != "agent" ]; then
identify
fi
echo $TYPE
if [  $TYPE = "leader" ]; then
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
token: ${token}
disable-cloud-controller: true
disable: rke2-ingress-nginx
tls-san:
  - ${server_url}
EOF
    cat /etc/rancher/rke2/config.yaml
    systemctl enable rke2-server
    systemctl daemon-reload
    systemctl start rke2-server
    leader_wait
    cat  /etc/rancher/rke2/rke2.yaml
    upload
fi
if [  $TYPE = "server" ]; then
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
server: https://${server_url}:9345
token: ${token}
disable-cloud-controller: true
disable: rke2-ingress-nginx
tls-san:
  - ${server_url}
EOF
    cat /etc/rancher/rke2/config.yaml
    cp_wait
    systemctl enable rke2-server
    systemctl daemon-reload
    systemctl start rke2-server
fi
if [  $TYPE = "agent" ]; then
  cat <<EOF > "/etc/rancher/rke2/config.yaml"
server: https://${server_url}:9345
token: ${token}
disable-cloud-controller: true
disable: rke2-ingress-nginx
tls-san:
  - ${server_url}
EOF
    cat /etc/rancher/rke2/config.yaml
    cp_wait
    systemctl enable rke2-agent
    systemctl daemon-reload
    systemctl start rke2-agent
fi
}
