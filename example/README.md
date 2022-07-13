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
> are sensitive and should have their values set in a way that will not expose them
> in any public code repositories. For this reason, these values are not set in the
> <font color="cyan">terraform.tfvars</font> file.
> 
> There are many ways to set these values without hardcoding them, including secrets managers
> like [HashiCorp Vault][vault], HashiCorp Terraform Cloud [sensitive workspace specific variables][tfcloud],
> and locally exported [TF_VAR_name environment variables][TF_VAR_], which is the method used in this quick start example.
>
> **Note**: the values of these variables will still be visible in terraform state files, so be sure to add appropriate
> entries to a .gitignore file to exclude file names containing patterns like *.tfstate and \*.tfstate.\* from commits.
> 
> ### Variables to be set using TF_VAR_name environment variables
> - aws_key_name
> - aws_key_pub
> - aws_key
> - rubrik_support_password
> - rubrik_admin_email
>
> In addition, the data.http.ip data source in <font color="cyan">rubrik-vpc.tf</font> automatically tries
> to determine the public IP address of the machine you run ```terraform apply``` from in order to determine
> the appropriate AWS security group inbound SSH rule. If you are running ```terraform apply``` from your
> home network, you don't want to accidentally expose your public IP address on GitHub, so make sure you
> add the .gitignore rules stated above.

## Step-by-Step Instructions

tbd will clean up

configure aws cli credentials and env vars
confiure tf_vars_
ssh-keygenexport TF_VAR_rubrik_admin_email=""
export TF_VAR_aws_key_name=""
export AWS_ACCOUNT_ID='0000000000'
export AWS_PROFILE='aws-profile-name'
export TF_VAR_rubrik_support_password='password'
export TF_VAR_aws_key_pub='openssh-public-key-string'
export TF_VAR_aws_key='openssh-private-key-string'
scp
ssh port forward





[tfcloud]: <https://www.terraform.io/cloud-docs/workspaces/variables/managing-variables#workspace-specific-variables>
[vault]: <https://www.vaultproject.io/docs/what-is-vault>
[TF_VAR_]: <https://www.terraform.io/cli/config/environment-variables#tf_var_name>