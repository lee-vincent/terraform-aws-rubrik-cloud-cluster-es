# Rubrik Cloud Cluster ES on AWS Deployment Example

## Quick Start Example Summary

This quick start example first deploys the required (and fully confgured) AWS infrastructure to support a Rubrik Cloud Cluster ES deployment, and an Amazon Linux workload EC2 instance that will be backed up by the cluster. This example then deploys, bootstraps, and configures Rubrik Cloud Cluster ES into the AWS infrastructure, and automatically configures the cluster to perform backups on the workload EC2 instance.

## Infrastructure that will be Deployed (and cost you money)

- VPC (us-east-1a)
- Subnets
    - public
        - 1 x Bastion Instance (t3.large)
        - NAT Gateway
    - rubrik (private)
        - 3 x Rubrik Instances (m5.4xlarge)
    - workload (private)
        - 1 x Workload Instance (t3.large)
- Security group allowing SSH from your personal IP address to the Bastion Instance
- S3 endpoint & S3 bucket

## <font color="red">**_Warning_**</font>

> The below terraform input variables located in <font color="cyan">variables.tf</font>
> are extremely sensitive and should have their values set in a way that will not expose them
> in any terraform state files or public code repositories.
> 
> There are many ways to accomplish this including secrets managers like [HashiCorp Vault][vault],
> HashiCorp Terraform Cloud [sensitive workspace specific variables][tfcloud], and locally exported
> [TF_VAR_name environment variables][TF_VAR_] which is the method used in this quick start example.
> 
> - aws_key_pub
> - aws_key
> - rubrik_support_password
> - 

> and the IP address in locals

## Step-by-Step Instructions


configure aws cli credentials and env vars
confiure tf_vars_


export AWS_ACCOUNT_ID='0000000000'
export AWS_PROFILE='aws-profile-name'
export TF_VAR_rubrik_support_password='password'
export TF_VAR_aws_key_pub='openssh-public-key-string'
export TF_VAR_aws_key='openssh-private-key-string'



# TF_VAR_ SENSITIVE local environment variables #
#################################################
# aws_key_pub             = TF_VAR_aws_key_pub
# aws_key                 = TF_VAR_aws_key
# rubrik_pass             = TF_VAR_rubrik_pass
# rubrik_support_password = TF_VAR_rubrik_support_password








[tfcloud]: <https://www.terraform.io/cloud-docs/workspaces/variables/managing-variables#workspace-specific-variables>
[vault]: <https://www.vaultproject.io/docs/what-is-vault>
[TF_VAR_]: <https://www.terraform.io/cli/config/environment-variables#tf_var_name>