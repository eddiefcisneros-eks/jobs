<!---
#################################################################################################################
# The overall classification of this file is UNCLASSIFIED.
#
# NOTICE: This software was produced for the U. S. Government under Contract
# No. FA8702-19-C-0001, and is subject to the Rights in Noncommercial Computer
# Software and Noncommercial Computer Software Documentation Clause DFARS
# 252.227-7014 (FEB 2014)
#
# (c) 2023 The MITRE Corporation
#
# PROJECT: MVP - Prototype RKE2 Platform Automation over MITRE AWS xcloud environmant as a base infrastructure for
# Big Bang deployment
# CLASSIFICATION: Unclassified
# Karpagam Balan (kbalan@mitre.org)
# CREATED: January, 2024
# DESCRIPTION: Documentation
###################################################################################################################
-->

# 1. Frequently Asked Questions

## Terraform vs Crossplane

Both Terraform and Crossplane are tools that are extensively used by the community to deploy and maintain infrastructure as code. 
The primary difference between the two is that Terraform is largely employed from outside the cluster while Crossplane is 
natively integrated with the Kubernetes ecosystem and leverages the Kubernetes control logic to maintain desired state. While both
offer robust mechanisms to compose complex infrastructure patterns, with Crossplane the built-in capabilities of the Kubernetes engine can 
be immediately leveraged, for example to provide robust rbac controls over deployed resources, expose self-serve platform apis and integrate with other 
cloud native / Big Bang tools such as Kyverno and OPA Gatekeeper.


# 2. Troubleshooting

### Error during deployment involving 401 unauthorized
   - The Iron Bank credentials may not have been correct.
   - To get username and password
      - In a web browser go to https://registry1.dso.mil
      - Login via OIDC provider
      - In the top right of the page, click your name, and then User Profile
      - Your username is labeled “Username”
      - Your password is labeled “CLI secret”
   - Another possiblity is that the AWS user account does not have sufficient permissions. Please contact your AWS admin to resolve this issue.

### 2.2 Deployment is stuck on "Waiting for providers to be ready." or "Waiting for configuration to be ready.".
   - Values used in crossplane values file are likely to have been incorrect or invalid. To correct invalid values given, the user may retry parts of the deployment process. For example, if the deployment is stuck on "Waiting for configuration to be ready." the configuration template given during the crossplane configuration step was likely invalid. The user may fix the configuration and use the command `./distroctl deploy_crossplane configurations --template <config-template-location>` to attempt to set the configurations again.
   
### 2.3 Cluster nodes will not come up. The nodes display an "InvalidDiskCapacity" in the AWS console.
   - This is likely due to an arror in the eks-ami/files/bin/imds file. The file may contain carriage return characters which breaks the file. This may occur when transferring file from a windows file to a linux one. A new AMI may need to be built in this case.

### 2.4 The script says that Docker appears to not be running even though it is installed.
   - Even if Docker is installed a restart or relogin may need to occur for Docker to become available.
   - The Docker service may not have been started. Use the following commands to start the docker service: `sudo systemctl start docker` and `sudo systemctl enable docker`
   - Additionally, the current user may not have access to docker. To give your user access to docker use the commands: `sudo groupadd docker` and `sudo usermod -aG docker $USER`


# 3. Other Useful How Tos

### 3.1 How to get an Amazon access key
   - Log onto the Amazon console via the web browser
   - Click on the account menu in the upper-right (has your username on it)
   - Click "Security Credentials"
   - In the "Access Keys" section click "Create access key"
   - Follow the instructions until the access key is created.

### 3.2 How to get Iron Bank credentials
   - In a web browser go to https://registry1.dso.mil
   - Login via OIDC provider
   - In the top right of the page, click your name, and then User Profile
   - Your username is labeled “Username”
   - Your password is labeled “CLI secret”
	
### 3.3 How to check the status of the KinD cluster
   - The KinD cluster runs as a docker container. Using `docker ps` will show active containers. The KinD cluster should have the name "node"
   - The script will automatically update the kubectl config to point to the KinD cluster when it is spun up. Using `kubectl` with it's associated commands will allow the user access into the KinD cluster. (See https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands for more info on kubectl).
   - If for some reason the kubeconfig is not configured properly the user may get the kubeconfig with the command `kind get kubeconfig --name <cluster-name>`. Where the cluster name is the name of the KinD cluster. By default the name is "management".
     - Kubectl will look for the kubeconfig file at ~/.kube/config by default. One can use copy the kubeconfig onto that location, alternatively add the option "--kubeconfig <kubeconfig-file>" to all the kubectl commands.
