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

# MVP EKS AMI Builder

Reference: Adapted from https://github.com/awslabs/amazon-eks-ami 

This repository contains code for a minimal viable prototype to build a custom Amazon Machine Image (AMI) based on RHEL 8 that is leveraged 
in deploying EKS cluster nodes.

## 1. Running the build.
To run the script make sure that Packer is installed onto the system. The preflight check of the distroctl script will automatically install Packer onto the user. If the user would like to install packer manually see https://developer.hashicorp.com/packer/downloads.

Also make sure that the AWS environment veriables are properly set. To do so use the commands:
```
export AWS_ACCESS_KEY_ID=<aws key>
export AWS_SECRET_ACCESS_KEY=<aws secret>
export AWS_DEFAULT_REGION=<aws region>
```

Then run the command: `packer build amazon-eks-node-rhel8.json`

The AMI will then build and at the end a message should be displayed showing information on the created AMI. The whole process may take up to 20 minutes.

The AMI will also be viewable from the Amazon console. To find the image look for images->AMIs within the ec2 section of the console.

## 2. Build File

The build template file, "amazon-eks-node-rhel8.json", details the variables and steps used to build the AMI.
The tables below shows the files, fields, and their significance in the build process. See the Packer Docs for more details on template files. https://developer.hashicorp.com/packer/docs.

### Variables field
The Variables defined in the "variables" field are used in other parts of the build process and are called upon in other parts of the template. They contain information such as properties of the built AMI (target_ami_name or volume_type), or values for binary version that will be used by the script (kubernetes_version or kustomize_version).

|Variables | Description |
|------------| ---------- |
|aws_region| AWS region where the ami will reside.|
|ami_description| Description for the AMI.|
|bin_arch| The archtitechture of the AMI (amd64, arm64 etc.). Used when downloading binaries onto the AMI.|
|build_version_kubernetes| Build version of Kubernetes to be used on the AMI.|
|cni_plugin_version| Version of CNI Plugin to be used on the AMI.|
|ecr_credential_provider_version| Version of ECR Credential provider to be used on the AMI.|
|flux_ver| Version of Flux to be used on the AMI.|
|helm_ver| Version of Helm to be used on the AMI.|
|iam_auth_ver| Version of IAM Auth to be used on the AMI.|
|instance_type| Instance type for the AMI (m5.xlarge, t2.large, etc.).|
|kubectl_ver| Version of Kubectl to be used on the AMI.|
|kubernetes_aws_bin_version| Version of Kubernetes to be used on the AMI. Pulled from AWS.|
|kubernetes_version| Version of Kubernetes to be used on the AMI. Also used to dictate the Kubelet version, as these two versions must match.|
|kustomize_version| Version of Kustomize to be used on the AMI.|
|root_volume_size| Root volume size, i.e. the disk space for the AMI.|
|data_volume_size| Data volume size, i.e. the 2nd disk space for the AMI.|
|sha_cni_plugins| SHA checksum used to verify CNI Plugin.|
|sha_ecr_credential_provider| SHA checksum used to verify the ECR Cred Provider.|
|sha_flux| SHA checksum used to verify Flux.|
|sha_helm| SHA checksum used to verify Helm.|
|sha_iam_auth| SHA checksum used to verify
|sha_kubectl| SHA checksum used to verify Kubectl.|
|sha_kubelet| SHA checksum used to verify Kubelet.|
|sha_kustomize| SHA checksum used to verify Kustomize.|
|source_ami_owner| Account ID of the source AMI owner.|
|source_ami_owner_govcloud| Account ID of the source AMI owner in gov cloud.|
|source_ami_ssh_user| ssh user name used to ssh into the source AMI.|
|source_ami_arch| Architecture of the source AMI.|
|source_ami_name| Image name of the source AMI.|
|target_ami_name| Image name of the created AMI.|
|volume_type| Volume type of the created AMI.|

### Builders field
The "builders" field contains information on the source AMI to build from, as well as disk allocation and metadata of the created AMI. 

|Fields | Description |
|------------| ---------- |
|type| Type of source image.|
|region| AWS region of source image.|
|source_ami_filter| Filter used to identify the source image of the AMI.|
|instance_type| Instance type of the created AMI. |
|ssh_username| ssh user name of the source AMI. |
|ssh_pty| ssh with pty enabled. |
|subnet_id| Subnets associated withe created AMI.|
|launch_block_device_mappings| Details the disk volumes to be associated with the created AMI.|
|ami_block_device_mappings| Details the disk volumes to be associated with the created AMI.|
|aws_polling| Set polling setting for the created AMI.|
|tags| Tags to be associated with the created AMI.|
|ami_name| AMI name of the created image.|
|ami_description| Description of the created AMI.|
|ami_virtualization_type| Virtualization type of the created AMI.|
|security_group_ids| Security groups to be associated with the created AMI.|
|run_tags| Run tags to be associated with the created AMI.|

### Provisioners field
Provisioners are processes done onto the source AMI to create the new AMI. These things include moving/downloading files, changing settings, and running scripts. One may refer to the Packer docs for full details on the provisioners https://developer.hashicorp.com/packer/docs/provisioners. Only two types of provisioners are used to create the AMI within this project.

- Shell provisioners - Run shell commands within the AMI. The commands can be defined in "inline" where the commands are written directly into the template file. Commands can also point to a shell script using the "scripts" field. Any environment variables can be defined under the "environment_vars" field.

- File provisioners - Used to move files within the AMI. The "source" field points to the source file. The "source" location is taken relative to the build location i.e. if the source is "./files/bin" and the user is running the Packer build from the "/home/user/" directory, the source file will be "/home/user/files/bin". The "target" field points to the target location of the file within the created AMI.

### Post Processors
Post processors define actions taken after AMI build is completed. Only one post processor is used in this project. See Packer Docs for full details on post processors https://developer.hashicorp.com/packer/docs/post-processors.

- Manifest - Outputs the build infomation onto a file. File location is defined by the "output" field. The "strip_path" field will write only filename without the path to the manifest file if it is true.


