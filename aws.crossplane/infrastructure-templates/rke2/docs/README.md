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
# FILE: README.md
# CLASSIFICATION: Unclassified
# Karpagam Balan (kbalan@mitre.org)
# CREATED: January, 2024
# DESCRIPTION: Documentation
###################################################################################################################
-->

# MVP RKE2 Crossplane Template

# AWS RKE2 Kubernetes Cluster Automation over MITRE AWS Xcloud Environment

This repository contains a Platform One Big Bang ready custom reference RKE2 
Platform Prototype Configuration employing [Crossplane](https://crossplane.io/)
for use in MITRE AWS xcloud environments.

This repository also contains prototype code to build a custom Amazon machine image (AMI) based on RHEL 8 that is leveraged 
in deploying RKE2 cluster nodes

Note this automation leverages the networking resources setup by default in the XCLOUD environment and specificallythe followinng resources

- Generic VPC
- Generic MITRE-Only Public Subnet (in three AZs) 
- Generic MITRE Baseline SG (henceforward referred to as SG1)
- Generic MITRE Web SG (henceforward referred to as SG2)
- Generic MITRE All SG (henceforward referred to as SG3)

The user needs to create an additional Security Group that allows all intra-subnet traffic. Going forward this security group will be referred to as "P1 Intra".


This platform provides IaC to provision a Highly Available RKE2 cluster (master and worker nodes) , and a bastion host to connect to nodes — composed using  Crossplane capabilities

## 1. Overview

The reference architecture for the deployment is included in the docs folder.

## 2. Prerequisites and Assumptions for Running Deployment
- Administrative access to an AWS gov cloud account is required
- The following urls need to be whitelisted for access

https://fluxcd.io/
https://get.rke2.io
https://releases.crossplane.io/
https://releases.hashicorp.com/
https://github.com
https://kind.sigs.k8s.io
https://dl.k8s.io
https://registry1.dso.mil
https://repo1.dso.mil
Docker.io
*.amazonaws.com
https://get.rke2.io

- A SG needs to exist allowing all intra subnet traffic between the MITRE-Only Public subnets (henceforward referred to as "P1 Intra" Security Group)
- These steps should be run on a Linux based host (tested on Ubuntu, Amazon Linux, and RHEL) with access to the AWS account where the cluster is to be deployed (recommended to have 4 vCPUs and 16GB of memory)
- User has programmatic administrative access to the AWS account. Note - This requires an InfoSec Waiver.
- There is no network restrictions imposed for ingress into and egress from the account. This means that the account has no restrictions overlayed on the initial AWS account setup that restricts ingress or egress traffic.
- Elastic Container Registry (ECR) is the registry to be used to host artifacts (such as crossplane templates) and container images (Code changes maybe necessary to accomodate other registries)
- User must have Iron Bank (registry1.dso.mil) credentials

## 3. Quick Install
This section goes over the steps for a first time deployment using the distroctl script.

The `distroctl` script is used to deploy the RKE2 cluster.
It has the capability to do various operations associated with the deployment including: checking if prerequisites are met, preparing a configuration file, creating and uploading packages for deployment, running the deployment, and more.
For more details on the script, its behavior, and it's capabilities please look at [Section 3](#3-about-the-deployment-process) and [Section 4](#4-reference) in this readme file.

The steps below will walk the user through a basic deployment of a RKE2 cluster using this script.
The whole deployment process can take approximately 25 minutes.

### 3.1 Setup

The script can be run from any linux machine that can access the AWS environment. For those who cannot or do not want to run the script on their local machine, this section will go over the steps to set up a VM, an ssh key, and move the files onto the VM. Those who are familiar with the process or already have a machine available to them may skip to section 3.2.

- Log onto the AWS console via the browser.
- Under Services search for "EC2" and go to the EC2 dashboard.
- Find the "Launch Instance" button and click it.
- The AWS console will then walk you through the instance creation process. The creation process may differ depending on how their AWS system is configured. Make sure that the following are addressed during the creation process.
	- Choose an AMI for the instance (the script should work with nearly all AMIs, but a recent version of Amazon Linux is recommended).
	- When choosing an instance type a "large" or "xlarge" instance type is recommended.
	- For storage it is recommended for the system to have at least 30 GB.
  - For subnet use one of the MITRE-Only Public subnet
  - Creatte a new security group that will usually allow for allintra subnet traffic (P1 Intra).
  - For Security Groups to attach to the instance, choose SG1,SG2,SG3 and P1 Intra 
	- Make sure an ssh key is chosen. The user will be prompted for a ssh key right after clicking the "Launch" button. The user may choose an existing key if they have one, or they may create a new one from the prompt window. If one does create a new key, be sure to download the key.
  - The instance should be created and will appear in the list of instances in the AWS console. After a minute the instance will become active and will be assigned public IP.
  - One can now ssh into the VM using the command `ssh -i <path-to-ssh-key> <username>@<instance-public-ip>`. The username is defined by the AMI chosen, For most AMIs the user name is "ec2-user" or "ubuntu" for ubuntu AMIs.
  - One can also transfer files onto the VM with the command `scp -i <path-to-ssh-key> <file(s)-to-transfer> <username>@<instance-public-ip>:<location-to-send-files>`. For location to send files it is recommended to use "~" as the location. "~" is the home directory where the user will be first sent to upon ssh-ing into the VM.


### 3.2 Run the script
Get all the files in this repository into the machine from which the dpeloyment will be run.
Use the deploy command on distroctl to begin the deployment.
```
./distroctl deploy
```
At this point distroctl will check for prerequisites and will alert the user if any are not met. The user may be asked to input information such as AWS and Iron Bank Credentials. simply input these values if prompted.

### 3.3 Configure the Deployment
- Assuming no configuration file is given, the script will prompt the user to generate a new configuration file.
- The script will walk the user through choosing their configuration and generating the corresponding configuration file.
- It is recommended to choose the default options for the values prompted.
- When prompted for the ssh key, the ssh key should be one's personal AWS generated ssh key. If the user does not have a key, a new pem key will be generated by the script.
- Once the proper input are given the script will build and Amazon Machine Image (AMI) for the deployment this may take 20 minutes.
- The script will also upload the crossplane template onto ECR
- Finally the script will generate a `crossplane-values.yaml` file. This file contains all the configurations needed for deployment. This file can also be used for future deployments using the `-v` option when running the script.

### 3.4 Let the Deployment Run
Once the configuration is set the script will proceed to deploy the bootstrap cluster. Crossplane will be installed onto the bootstrap cluster. Crossplane will then manage the AWS resources and deploy the RKE2 cluster. This step may take aroud 10 minutes.

### 3.5 Verify Installation

If successful, the KinD cluster should be up with crossplane installed onto the cluster, and crossplane will have begun the creation process for the AWS resources. The user will be able to use `kubectl get managed` to see the resources managed by crossplane. The deployment will be complete when all resources are marked as synced and ready.

Additionally, for reference, all logs will be output to a log file "output.log" in the same directory as the distroctl script. The AMI build logs will output to a file "ami_build.log" in the rke2-ami directory.


# 4. About the Deployment Process

### 4.1 Deployment of Clusters
The deployment creates atleast two clusters. A bootstrap cluster and a RKE2 cluster. The bootstrap cluster is created locally on a docker container through kind (https://kind.sigs.k8s.io).
Crossplane is installed onto the bootstrap cluster. Crossplane is used to manage resources in AWS. These AWS resources are used to create the RKE2 cluster in the AWS environment. The configurations and settings for the deployed RKE2 cluster is determined by the contents of the crossplane-values.yaml file.

### 4.2 Packages Created for Deployment

#### 4.2.1 The Crossplane Template
The script uses a crossplane template to deploy the RKE2 clustere. The crossplane template sets the parameters for the RKE2 cluster. 

The template needs to be uploaded only once into an environment. The script will upload this package into ECR at which point they may be used repeatedly for future deployments.
If one wishes to reuse already uploaded packages, the user must provide a valid crossplane values file, along with defining the CROSSPLANE_COMPOSITE value in distroctl.

The package may be created and uploaded by using "upload_crossplane_template" command. [See 5.2 for more on the commands](#52-running-the-script)

#### 4.2.2 The AMI
The script also has the ability to create an Amazon Machine Image (AMI) during the deployment process. These AMIs are used by the RKE2 worker nodes and the bastion server that are created during deployment. AWS provided release specific RKE2 optimized AMI can also be used with this deployment.

The AMI used by the deployment is defined the crossplane values files. Upon generating a new crossplane values file an AMI will also be generated. The AMI id will automatically be put into the generated file. Once an AMI is created, it may be reused for subsequent deployments.

For detailed reference on building the custom RHEL AMI, please refer to additional documentation in the docs folder.

### 4.3 Verifying/Modifying/Deleting the Deployment
Upon completion of a deployment kubectl may be used to interact with the bootstrap cluster. The progress of the RKE2 cluster deployment can be seen through the bootstrap cluster.
If the deployment is successful, we expect to see managed resources' "SYNCED" to be true. It may take some time (around 5-10 minutes) for all resources to be synced.
Once all resources are synced the cluster will begin to be created. This may take another 10 minutes, for a total of 20 minutes. To access the created cluster download the rke2.yaml file from the newly created S3 bucket and use it as the config file for kubectl commands.

The user may also modify the existing deployment to make changes to the deployed infrastructure. To do so the user would update the crossplane values file to contain the new infrastructure that would like to be deployed. Once the proper modifications to the file are made the infrastructure can be updated by using the command `./distroctl deploy_infrastucture -c <crossplane values file>`. [See 5.1 for more on the crossplane values file](#51-crossplane-values-file)

To delete the deployment one must first remove all the AWS resources created for the deployment. This can be done using the command `kubectl delete RKE2Cluster.rke2.platformone.io <deployment-name>`. Once the resources are taken down, the bootstrap cluster may also be brought down.


### 4.3 Software installed by the script
The script will automatically search for and install the applications listed below:
- crank (https://docs.crossplane.io/v1.11/)
- porter (https://getporter.org/)
- kubectl (https://kubernetes.io/docs/reference/kubectl/kubectl/)
- Docker (https://www.docker.com)
  - While it is possible to install docker through this script, it is recommended that the user installs it separately because installation methods for docker can vary greatly between linux distros.
- flux (https://fluxcd.io/)
- helm (https://helm.sh/)
- kustomize (https://kustomize.io)
- yq (https://github.com/mikefarah/yq)
 

## 5. Reference

### 5.1 Crossplane Values File
The crossplane values file is a file used to configure the infrastructure brought up by crossplane. These values need to be populated for the deployment to run. The user may provide a crossplane values file using the `-c` option at runtime. If no crossplane values file is provided, distroctl will generate a default file based on prompts submitted by the user. The user may also generate a default crossplane values file using the command `./distroctl generate_crossplane_values_file` which can then be modified and used for deployments.

By default the generated crossplane values file will use the vpcCidr 10.9.(0-80).0/20 as well as a node count of 8 with a size "large". A new AMI will also be created during this generation process. The AMI ID will be used as the AMI in the file. If the user would like to use a different vpcCidr space, node configuration, or AMI for their deployment, they must create and provide their own crossplane values file using the `-c` option.

The crossplane values file contains two main fields which can be filled to detail the deployed infrastructure, uxp and RKE2Cluster. The uxp field details a complete deployment, including subnets, security groups, bastion server, etc. The RKE2Cluster field will detail only an RKE2 cluster and its associated node group(s). If the user is using the RKE2Cluster field they will have to provide subnet and security group IDs for the cluster. It is recommended to use the subnets/security groups created from the uxp portion of the deployment.

See the file `examples/crossplane-values.yaml.example` to see what a crossplane-values files looks like and what fields are available to user.

The user may use the command `./distroctl deploy_infrastucture -c <crossplane values file>` to create/update infrastructure deployed onto the environment. Note that this command will only work if crossplane is already set up on the system. Additionally the deployed infrastructure will synced with the given crossplane file. I.e. if any deployed resources are no longer detailed in the crossplane values file, those resources will ne removed upon applying the file.

### 5.2 Running the Script
The general format for running the script is as follows:
```
./distroctl <command> <options>
```

| Command           | Description                                                                                                                                                                                                                                                                                                                                                                |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| preflight_check   | Runs a check for prerequisites and configurations, and alerts the user if they are not met. It will install various authomatically onto the system if they are not detected.                 |
| configure_check   | Check to see if the given crossplane-values.yaml file is correct. If a file isn ot given or found it will prompt the user an option to generate the file.                                                                                                                                                          |
| read_config       | Reads the configuration file and checks for errors. If any errors are found it will alert the user. Use the -c option to choose the configuration file. If a file is not given it will default to RKE2-deploy.config                                                                                                                                                        |
| upload_crossplane_template    | Creates and uploads the crossplane template.                                                                   |
| generate_crossplane_values_file | Creates the default crossplane values file (crossplane_values.yaml). This file is used to determine the cluster's properties when it is created by crossplane. If no crossplane values file is found during the deployment, the script will generate a default file using this functionality.                                                                            |
| build_ami | Builds and upload AMI onto AWS                                                                            |
| validate_crossplane_values_file | Will validate a given crossplane values files to see if any important values are missing or invalid.                                                                            |
| deploy_cluster    | Will deploy the bootstrap KinD cluster. This will not install crossplane onto the cluster for deploy any infrastructure on RKE2.                                                                                                                                                                       |
| deploy_crossplane | Will install crossplane onto the bootstrap cluster. This will not work if a cluster does not exist. This will not deploy any infrastructure on RKE2. This command has four steps. "bootstrap", "crossplane", "providers", and "configurations". The user can choose which of these steps to run by adding it as an argument. If none of the steps are given it will run all four steps by default. See the options table for more details.                          |
| deploy_infrastructure | Will deploy infrastructure onto RKE2 as defined by the crossplane values file. This will not work if Kind cluster does not exist or if crossplane has not been set up on the cluster.                                                                                                                                                                        |
| deploy            | Will run a full deployment, including a check for all prerequisites, creation of the KinD cluster, installation of crossplane onto the KinD cluster, and deployment of infrastructure on RKE2.                                                                                                                      |

| Options | Description                                                                                                                                                                                   |
|---------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| -c \<file\>     | Crossplane values file option. Determines the location of the crossplane values file used in deployment. Defaults to "crossplane-values.yaml". If the file does not exist the user will be prompted to generate a new one at runtime.|                                  
| -s      | Activates silent mode. Most messages will be hidden from the console if this mode is activated. Console message will still be recorded onto the output log file.|                                  
| --values \<file\>     | Values file option. Used to give a values file during the installation of crossplane onto the bootstrap cluster (i.e. the deploy_crossplane command, crossplane step). |                                  
| --template \<template location\>     | Crossplane template option. Points to a crossplane template. The script will upload/use a template by default if one is not provided. Only used during the configuration of crossplane onto the bootstrap cluster (i.e. the deploy_crossplane command, configurations step). |                                  
| bootstrap      | Bootstrap option. Used with the deploy_crossplane command to run the installation of the crossplane bootstrap on the bootstrap cluster (e.g. `./distroctl deploy_crossplane bootstrap`).|                                  
| crossplane      | Crossplane option. Used with the deploy_crossplane command to install crossplane on the bootstrap cluster. The crossplane bootstrap must be set up on the bootstrap cluster before this can run. Can take a --values option to define a values file. (e.g. `./distroctl deploy_crossplane crossplane --values values-file.yaml`).|                                  
| providers      | Providers option. Used with the deploy_crossplane command to install providers onto crossplane. Crossplane must be installed on the bootstrap cluster before this can run. (e.g. `./distroctl deploy_crossplane providers`).|                                  
| configurations      | Configurations option. Configures crossplane with a crossplane template. Crossplane providers must be set up before this can run. If no template is provided it will use default values to look for a template. Can take a --template option to define a values file. (e.g. `./distroctl deploy_crossplane configurations --template ecr.amazonaws.com:template:1.0`)|                                  


### 5.4 Cloud Resources
This deployment will create AWS cloud resources. These resources can be used as infrastructure for a Big Bang deployment. To check to see what resources are being managed by the deployment use the command `kubectl get managed`. When a deployment is fully complete and successful, the user should see that all managed resources are both synced and ready.

| Resource Name | Description |
|-------------------|--------------------------------|
|attachment| Attachment of instances to Elastic Load Balancer |
|autoscalinggroup 1| Master Node Autoscaling Group |
|autoscalinggroup 2| Worker Node Autoscaling Group |
|instance| Bastion server EC2 instance. |
|launchtemplate 1| Master Node Launch Template|
|launchtemplate 2| Worker Node Launch Template |
|elb| Elastic Load Balancer for accessing cluster |
|instanceprofile| Bastion Instance Profile|
|rolepolicyattachment| Role Policy Attachmentwith IAM policy |
|role| IAM role to attach to nodes  |
|key| KMS key for encryption |
|bucketpublicaccessblock| S3 Bucket Policy |
|bucket| S3 Bucket to store kubeconfig |



## 6. Files and Directory Structure
Note: This diagram is to give the user an overview of how the directories/files are structured. This diagram is not comprehensive and will not contain all files and directories.

```
├── bootstrap-manifest/ (Template files used to help define the infrastructure during the RKE2 deployment.)
│   └── infrastructure/
│       └── templates/
│
│── docs/ (Holds all the documentation files)
│
├── distroctl (Main script used for deployment)
│
├── examples/ (Example files for reference)
│
├── rke2-xr/ (This directory contains the crossplane template files for RKE2 deployment)
│   ├── bastion/ (Template files relating to the bastion server)
│   ├── RKE2/ (Template files relating to the RKE2 cluster)
│   ├── network/ (Template files relating to the network rules)
│   ├── platform/ (Template files relating to VMs and cluster contents)
│   └── crossplane.yaml (Main template file for the crossplane template.)
│
└── rke2-ami/ (Files necessary for the building of an AMI for the RKE2 cluster)
    ├── files/ (Files used to build the AMI. Mostly contains files that will be copied over into the AMI)
    │
    ├── scripts/ (Scripts that will be run on the AMI during the build process)
    └── packer.json (Configuration file used by packer to build the AMI)
```

