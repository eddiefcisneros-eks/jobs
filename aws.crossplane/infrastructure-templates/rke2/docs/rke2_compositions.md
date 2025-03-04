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


# MVP RKE2 Crossplane Composition

# Crossplane Composite Resource reference

## This repository contains Prototype Crossplane Composite Resource Templates to deploy RKE2 cluster and associated infrastructure over an existing MITRE AWS xCloud Account 

### The following composite resources are defined in the template
- rke2clusters.rke2.platformone.io


### The following claims are defined in the template
- rke2ciclusters.rke2.platformone.io

# Composite Resources

## 1. RKE2Cluster Composite Resource 

### The following are the input parameters for this composite resource


| Field           | Description |
| -----------------  | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| parameters.imageId   | Required. Type: string. AMI id of the image to be used on worker nodes. This is the AMI id of a custom image 
| parameters.nodes.count | Required. Type: integer. Desireds number of worker nodes to deploy (Note: maximum nuber of nodes for small deployment is 25, medium size deployment is 50, and a large deployment is 100) |
| parameters.nodes.size | Required. Type: string. Allowed values are small, medium and large. Small will deploy m5.large instances, medium will deploy m5.2xlarge instances and large will deploy m5.8xlarge instances |
| parameters.volumeSize | Optional. Type: integer. Size of the second volume that is to be attached to the node instances. Defaults to 60G |
| parameters.keyName | Required. Type: string. Key pair name to be used at launch time for worker node instances. |
| parameters.subnetIds | Required. Type: Array of strings. Array of subnet Ids into which the nodes  are provisioned |
| parameters.securityGroupIds | Required. Type: array of strings. Array of Security Group Ids to associate with the nodes|
| parameters.region | Required. Type: string. The region into where the cluster is being deployed |
| parameters.token | Required. Type: string. Token used by the RKE2 cluster control plane |



# Composite Resource Claims

## 1. RKE2CiCluster Composite Resource Claim

The RKE2CiCluster Claim provisions a claim of the RKE2Cluster Composite Resource. 

# Notes

## Crossplane deployment

The helm chart that installs crossplane can be found here https://repo1.dso.mil/big-bang/product/community/crossplane. Valid repo1 and IB credentials are required inorder to dpeloy the chart. Crossplane can be deployed as a package wrapper around Big Bang. An example addition to the BigBang deployment configuration values could be.
```
packages:
  crossplane:
    enabled: true
    namespace:
      name: crossplane-system
    git:
      repo: "https://repo1.dso.mil/big-bang/product/community/crossplane.git"
      tag: "1.14.5-bb.0"
      path: "chart"
    values:
      resourcesCrossplane:
        limits:
          # -- CPU resource limits for Crossplane.
          cpu: 1
          # -- Memory resource limits for Crossplane.
          memory: 1Gi
        requests:
          # -- CPU resource requests for Crossplane.
          cpu: 100m
          # -- Memory resource requests for Crossplane.
          memory: 256Mi
      provider:
        packages:
        - xpkg.upbound.io/upbound/provider-aws-autoscaling:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-iam:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-ec2:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-s3:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-elb:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-kms:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-cloudwatchlogs:v0.47.1
        - xpkg.upbound.io/upbound/provider-aws-iam:v0.47.1
        - xpkg.upbound.io/upbound/provider-family-aws:v0.47.1
        - xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.9.0
       
 ```
The above installs Crossplane 1.14.5-bb.0 into an existing cluster. Additionly a list of providers are installed which allow for resource creation on the AWS cloud and on the target RKE2 kubernetes cluster. Distroctl automates deployment of Crossplane onto a KinD cluster on the bootstrap EC2 instance and leverages the manifests from the bootstrap-manifests folder of this repository. 


## Crossplane RBAC with Claims

Crossplane Claims are namespaced. To restrict access to the cluster resources and the managed resources provisioned by Crossplane in response to the Claim deployment, annotations in the namespace manifest and Kubernetes native RBAC resources may be leveraged. For example:
```
---
apiVersion: v1
kind: Namespace
metadata:
  name: example
  labels:
    app.kubernetes.io/name: example
  annotations:
    rbac.crossplane.io/rke2ciclusters.rke2.platformone.io: xrd-claim-accepted
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: example-sa
  namespace: example-namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: example-role
  namespace: example-namespace
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: example-rolebinding
  namespace: example-namespace
roleRef:
  apiGroup: ""
  kind: Role
  name: example-role
subjects:
- kind: ServiceAccount
  name: example-sa
  namespace: example-namespace
---
apiVersion: rbac.authorization.k8s.io/v1

kind: RoleBinding
metadata:
  name: example-rolebinding-crossplane-edit
  namespace: example-namespace
roleRef:
  apiGroup: ""
  kind: Role
  name: "crossplane-edit"
subjects:
- kind: ServiceAccount
  name: example-sa
  namespace: example-namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: example-cluster-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: "crossplane-view"
subjects:
- kind: ServiceAccount
  name: example-sa
  namespace: example-namespace
```

## GitOps with Crossplane

An example of RKE2 cluster provisioning with helm charts can be found in the examples directory. Flux or ArgoCD can further be used to automate deployment with GitOps processes. When using Argocd, the Argocd configmap needs to have the following resource trackingmethod enabled.
```
  application.resourceTrackingMethod: annotation
```

## Integration with Kyverno

Since infrastructure resources are Kubernetes API objects, Kyverno can be leveraged to validate or mutate resource configurations and enforce policies.

 
## Status of deployment

To view the status of all the composite resources deployed in the cluster
```
kubectl get composite
```

To view the status of all the managed resources deployed in the cluster
```
kubectl get managed
```

To view the status of all the claims deployed in the cluster
```
kubectl get claim -A
```
When the RKE2 cluster is deployed successfully and all resources are in teh "READY" state, the kubeconfig for the deployed RKE2 cluster is written into the provisioned S3 bucket in the file named "rke2.yaml". This file can be downloaded and used as kubeconfig along with kubectl commands to operate the cluster,








