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
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_zone" {
  type    = string
  default = "a"
}
provider "aws" {
  region = var.aws_region
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
resource "aws_instance" "bastion1" {
  lifecycle {
    create_before_destroy = true
  }
  key_name                    = "bilh-aws-demo-master-key"
  ami                         = data.aws_ami.amazon_linux2.image_id
  vpc_security_group_ids      = [aws_security_group.workstation_bastion.id]
  subnet_id                   = aws_subnet.public1.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true

}
resource "aws_instance" "bastion2" {
  lifecycle {
    create_before_destroy = true
  }
  key_name                    = "bilh-aws-demo-master-key"
  ami                         = data.aws_ami.amazon_linux2.image_id
  vpc_security_group_ids      = [aws_security_group.workstation_bastion.id]
  subnet_id                   = aws_subnet.public2.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
}
resource "aws_instance" "bastion3" {
  lifecycle {
    create_before_destroy = true
  }
  key_name                    = "bilh-aws-demo-master-key"
  ami                         = data.aws_ami.amazon_linux2.image_id
  vpc_security_group_ids      = [aws_security_group.workstation_bastion.id]
  subnet_id                   = aws_subnet.public2.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
}
resource "aws_vpc" "rubrik_vpc" {
  cidr_block           = "10.150.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = format("%s%s", var.aws_region, "-vpc")
  }
}
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.150.5.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s", var.aws_region, "-public-subnet1")
  }
}
resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.150.6.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s", var.aws_region, "-public-subnet2")
  }
}
resource "aws_internet_gateway" "rubrik_internet_gateway" {
  vpc_id = aws_vpc.rubrik_vpc.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-internet-gateway")
  }
}
resource "aws_route_table" "rubrik_routetable_main" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rubrik_internet_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable-main")
  }
}
resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.rubrik_vpc.id
  route_table_id = aws_route_table.rubrik_routetable_main.id
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow all in between sg"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    description = "allow all out between sg"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
}