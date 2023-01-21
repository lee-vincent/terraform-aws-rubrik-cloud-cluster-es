provider "aws" {
  region  = var.aws_region
  profile = "ahead"
}
# keys used by ec2 bastion to manage rubrik nodes
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
# next add a bastion spcific key and use user data and secrets manager agent to pull
# the rubrik key onto the bastion
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux2.image_id
  instance_type          = var.aws_instance_type
  key_name               = aws_key_pair.rubrik.key_name
  vpc_security_group_ids = [aws_security_group.workstation_bastion.id, module.rubrik_cloud_cluster.bastion_rubrik_security_group]
  subnet_id              = aws_subnet.workload.id
  tags = {
    Name = "bastion"
  }
  associate_public_ip_address = true
}
# then create new security group for bastion to nodes communication
module "rubrik_cloud_cluster" {
  # source                                   = "lee-vincent/rubrik-cloud-cluster-es/aws"
  # version                                  = "~> 1.2.6"
  source                      = "git::https://github.com/lee-vincent/terraform-aws-rubrik-cloud-cluster-es.git?ref=v8.0"
  aws_region                  = var.aws_region
  aws_subnet_id               = aws_subnet.rubrik.id
  rubrik_key_name             = var.rubrik_key_name
  aws_disable_api_termination = false
  rubrik_node_count           = var.rubrik_node_count
  bootstrap_cluster           = true
  force_destroy_s3_bucket     = true
}
resource "aws_vpc" "rubrik_vpc" {
  cidr_block = "10.150.0.0/16"
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-vpc")
  }
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.150.5.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-public-subnet")
  }
}
resource "aws_subnet" "workload" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.150.6.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-workload-subnet")
  }
}
resource "aws_subnet" "rubrik" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.150.7.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-rubrik-subnet")
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.rubrik_vpc.id
  service_name    = format("%s%s%s", "com.amazonaws.", var.aws_region, ".s3")
  route_table_ids = [aws_route_table.rubrik_routetable.id]
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-s3endpoint")
  }
}
resource "aws_internet_gateway" "rubrik_internet_gateway" {
  vpc_id = aws_vpc.rubrik_vpc.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-internet-gateway")
  }
}
resource "aws_eip" "rubrik_nat_gateway_eip" {
  depends_on = [
    aws_internet_gateway.rubrik_internet_gateway
  ]
  vpc = true
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-internet-gateway-eip")
  }
}
resource "aws_nat_gateway" "rubrik_nat_gateway" {
  allocation_id = aws_eip.rubrik_nat_gateway_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-nat-gateway")
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.rubrik_internet_gateway]
}
resource "aws_security_group" "workstation_bastion" {
  name        = "workstation-bastion-sg"
  description = "Allow inbound SSH from my workstation IP"
  vpc_id      = aws_vpc.rubrik_vpc.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-bastion-sg")
  }
  ingress {
    description = "allow ssh from my workstation ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/32"]
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rubrik_routetable_public.id
}
resource "aws_route_table_association" "rubrik" {
  subnet_id      = aws_subnet.rubrik.id
  route_table_id = aws_route_table.rubrik_routetable.id
}
resource "aws_route_table_association" "workload" {
  subnet_id      = aws_subnet.workload.id
  route_table_id = aws_route_table.rubrik_routetable.id
}
resource "aws_route_table" "rubrik_routetable" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.rubrik_nat_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable")
  }
}
resource "aws_route_table" "rubrik_routetable_public" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rubrik_internet_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable-public")
  }
}
resource "aws_route_table" "rubrik_routetable_main" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.rubrik_nat_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable-main")
  }
}
resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.rubrik_vpc.id
  route_table_id = aws_route_table.rubrik_routetable_main.id
}