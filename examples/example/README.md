# Rubrik Cloud Cluster ES on AWS Deployment Example
[![AHEAD](https://public-bucket-general.s3.amazonaws.com/AHEAD-logo-bluebackground-180x38px.png)](https://ahead.com)


- Author: Vinnie Lee
- Contact: vinnie.lee@ahead.com

This module deploys the required (and fully confgured) AWS infrastructure to support a Rubrik Cloud Cluster ES deployment. This example then bootstraps, and configures Rubrik Cloud Cluster ES into the AWS infrastructure, and automatically configures the cluster to perform backups on the .

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

0. Subscribe to Rubrik Cloud Cluster v7.0 in the AWS Marketplace

1. Register for the [Rubrik Support Portal][rubrik_support]. This is optional but required to access the Rubrik GUI in step 8.

2. Configure your local environment with AWS CLI credentials. Open a terminal/shell and run the following:

    ```sh
    export AWS_ACCOUNT_ID='your-aws-account-id'
    export AWS_PROFILE='aws-profile-name' # 'default' or a profile from $HOME/.aws/credentials or $HOME/.aws/config
    ```

3. Create an OPENSSH formatted key pair with no passphrase that will be used for SSH access into the bastion, workload, and Rubrik EC2 instances.
Rubrik requires the OPENSSH format.

    ```sh
    KEYNAME='rubrik-cloud-cluster-key' # feel free to change if you want
    ssh-keygen -f "$HOME/.ssh/$KEYNAME" -q -P ""
    ```

4. Set the TF_VAR_name local environment variables

    ```sh
    export TF_VAR_rubrik_support_password='replace-with-your-rubrik-support-portal-password'; # if you aren't registered, just run command as is
    export TF_VAR_rubrik_admin_email='replace-with-your-email'
    export TF_VAR_aws_key_name="$KEYNAME"; # the name you chose in step 3
    TF_VAR_aws_key_pub=$(cat "$HOME/.ssh/$KEYNAME.pub") && export TF_VAR_aws_key_pub;
    TF_VAR_aws_key=$(cat "$HOME/.ssh/$KEYNAME") && export TF_VAR_aws_key;
    ```

5. Run these commands from inside the <font color="cyan">**example**</font> directory

    ```sh
    terraform init
    terraform plan # if no errors, apply the configuration
    terraform apply -auto-approve
    # Wait about 10 minutes for the apply to finish and produce output
    ```

6. Find the terraform output labeled secure_copy_configure_sh_command and copy everything between the opening and closing parentheses (" ") 

    ```sh
    # look for this line of output
    secure_copy_configure_sh_command = "scp -i $HOME/.ssh/rubrik-cloud-cluster-key -oStrictHostKeyChecking=no ./configure.sh ec2-user@44.204.34.234:/home/ec2-user/ && ssh -i $HOME/.ssh/rubrik-cloud-cluster-key -oStrictHostKeyChecking=no ec2-user@44.204.34.234 ./configure.sh"
    # copy/paste everything between the opening " and closing " and run the command
    # for example:
    scp -i $HOME/.ssh/rubrik-cloud-cluster-key -oStrictHostKeyChecking=no ./configure.sh ec2-user@44.204.34.234:/home/ec2-user/ && ssh -i $HOME/.ssh/rubrik-cloud-cluster-key -oStrictHostKeyChecking=no ec2-user@44.204.34.234 ./configure.sh
    # this command bootstraps the Rubrik CLuster and configures the Rubrik Backup SLA to start taking backups of the workload instance
    # wait for this command to finish before moving on - can take 15 minutes or more
    ```

7. Optional - Set up local port forwarding so you can log in to the Rubrik GUI from your laptop by tunneling through the bastion instance. Start a new shell/terminal and run the following command:

    ```sh
    # look for this line of output in your first terminal:
    ssh_local_port_forwarding_command = "ssh -N -i $HOME/.ssh/rubrik-cloud-cluster-key -L 8444:10.0.7.209:443 -oStrictHostKeyChecking=no -p 22 ec2-user@44.204.34.234"
    # copy/paste everything between the opening " and closing " and run the command
    # for example:
    ssh -N -i $HOME/.ssh/rubrik-cloud-cluster-key -L 8444:10.0.7.209:443 -oStrictHostKeyChecking=no -p 22 ec2-user@44.204.34.234
    ```


8. Optional - After running the local port forwarding command in step 7, open an internet browser and navigate to **https://localhost:8444**

9. Destroy your infrastructure - **<font color="red">this example can cost upwards of $100 per hour in AWS</font>**

    make sure you are in the same terminal/shell you ran ```terraform apply -auto-approve``` from and run:

    ```sh
    terraform destroy -auto-approve
    ```


[rubrik_support]: <https://support.rubrik.com/s/>
[tfcloud]: <https://www.terraform.io/cloud-docs/workspaces/variables/managing-variables#workspace-specific-variables>
[vault]: <https://www.vaultproject.io/docs/what-is-vault>
[TF_VAR_]: <https://www.terraform.io/cli/config/environment-variables#tf_var_name>