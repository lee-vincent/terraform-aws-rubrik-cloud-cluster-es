terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.51.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
provider "aws" {
  region = var.aws_region
}

variable "ips" {
  default = [
    "10.150.7.1",
    "10.150.7.2",
    "10.150.7.3",
    "10.1.1.1",
    "3.3.3.3"
  ]
}
data "aws_ami" "amazon_linux2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_instance" "bastion" {
  lifecycle {
    create_before_destroy = true
  }
  key_name             = "bilh-aws-demo-master-key"
  iam_instance_profile = aws_iam_instance_profile.ec2_secretsmanager_profile.name
  ami                  = data.aws_ami.amazon_linux2.image_id
  instance_type        = "t3.micro"
  user_data            = <<-EOF1
    #!/bin/bash
    yum install -y jq
    RUBRIK_IPS=(%{for ip in var.ips}"${ip}" %{endfor~})
    echo $${#RUBRIK_IPS[@]} > /home/ec2-user/array.length
    for ip in $${RUBRIK_IPS[@]}; do echo $ip >> /home/ec2-user/ips; done
    curl "http://169.254.169.254/latest/meta-data/iam/security-credentials/$(curl http://169.254.169.254/latest/meta-data/iam/security-credentials/)" -o /home/ec2-user/creds
    echo 'export AWS_ACCESS_KEY_ID="$(cat /home/ec2-user/creds | grep AccessKeyId | tr -d \"[:space:], | cut -d : -f 2)"' >> /home/ec2-user/.bashrc
    echo 'export AWS_SECRET_ACCESS_KEY="$(cat /home/ec2-user/creds | grep SecretAccessKey | tr -d \"[:space:], | cut -d : -f 2)"' >> /home/ec2-user/.bashrc
    echo 'export AWS_SESSION_TOKEN="$(cat /home/ec2-user/creds | grep Token | tr -d \"[:space:], | cut -d : -f 2)"' >> /home/ec2-user/.bashrc
    export AWS_ACCESS_KEY_ID="$(cat /home/ec2-user/creds | grep AccessKeyId | tr -d \"[:space:], | cut -d : -f 2)"
    export AWS_SECRET_ACCESS_KEY="$(cat /home/ec2-user/creds | grep SecretAccessKey | tr -d \"[:space:], | cut -d : -f 2)"
    export AWS_SESSION_TOKEN="$(cat /home/ec2-user/creds | grep Token | tr -d \"[:space:], | cut -d : -f 2)"
    raw_key=$(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.rubrik_cloud_cluster.arn} --region ${var.aws_region} --query SecretString)
    echo -e $raw_key | tr -d \" > /home/ec2-user/.ssh/rubrik-cloud-cluster
    chown ec2-user:ec2-user /home/ec2-user/.ssh/rubrik-cloud-cluster
    chmod 0400 /home/ec2-user/.ssh/rubrik-cloud-cluster
  EOF1
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
resource "aws_iam_role" "ec2_secretsmanager_instance_role" {
  name = "ec2-secretsmanager-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
variable "rubrik_key_name" {

}

variable "rubrik_private_key" {
}
variable "rubrik_public_key" {
}
resource "aws_secretsmanager_secret" "rubrik_cloud_cluster" {
  name                    = var.rubrik_key_name
  recovery_window_in_days = 0
  description             = "OpenSSH private key used to bootstrap rubrik cloud cluster nodes"
}
resource "aws_secretsmanager_secret_version" "rubrik_private_key_value" {
  secret_id     = aws_secretsmanager_secret.rubrik_cloud_cluster.id
  secret_string = var.rubrik_private_key
}
resource "aws_secretsmanager_secret" "rubrik_cloud_cluster_pub" {
  name                    = "${var.rubrik_key_name}.pub"
  recovery_window_in_days = 0
  description             = "OpenSSH public key used to bootstrap rubrik cloud cluster nodes"
}
resource "aws_secretsmanager_secret_version" "rubrik_public_key_value" {
  secret_id     = aws_secretsmanager_secret.rubrik_cloud_cluster_pub.id
  secret_string = var.rubrik_public_key
}
data "aws_secretsmanager_secret" "rubrik_cloud_cluster_pub" {
  name = aws_secretsmanager_secret.rubrik_cloud_cluster_pub.name
}
data "aws_secretsmanager_secret_version" "rubrik_public_key_value" {
  secret_id = data.aws_secretsmanager_secret.rubrik_cloud_cluster_pub.id
}

resource "aws_iam_role_policy" "allow_secretsmanager_read" {
  name = "AllowSecretsManagerRead"
  role = aws_iam_role.ec2_secretsmanager_instance_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : "${aws_secretsmanager_secret_version.rubrik_private_key_value.arn}"
      }
    ],
  })
}
resource "aws_iam_instance_profile" "ec2_secretsmanager_profile" {
  name = "ec2-secretsmanager-instance-profile"
  role = aws_iam_role.ec2_secretsmanager_instance_role.name
}
