provider "aws" {
  region  = "us-east-1"
  profile = "ahead"
}
variable "rubrik_key_name" {
  description = "The name of an existing AWS Keypair (OPENSSH formatted) for which you have access to the private key. Will be used for ssh to Rubrik Cloud Cluster nodes."
}
variable "rubrik_public_key" {
  description = "OpenSSH public key that will be configured on the EC2 rubrik nodes"
}
variable "rubrik_private_key" {
  description = "OpenSSH private key that will be added to secrets manager"
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

resource "aws_key_pair" "rubrik" {
  key_name   = aws_secretsmanager_secret.rubrik_cloud_cluster.name
  public_key = aws_secretsmanager_secret_version.rubrik_public_key_value.secret_string
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
resource "aws_instance" "workload" {
  ami           = data.aws_ami.amazon_linux2.image_id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.rubrik.key_name
  tags = {
    Name = "workload"
  }
  associate_public_ip_address = true
}
