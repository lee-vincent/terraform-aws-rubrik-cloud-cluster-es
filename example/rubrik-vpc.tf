provider "aws" {
  region = var.aws_region
}
module "rubrik-cloud-cluster" {
  # source                                   = "lee-vincent/rubrik-cloud-cluster-es/aws"
  source = "git::https://github.com/lee-vincent/terraform-aws-rubrik-cloud-cluster-es.git?ref=v8.0"
  # version                                  = "~> 1.2.6"
  aws_region                               = var.aws_region
  aws_subnet_id                            = aws_subnet.rubrik.id
  security_group_id_inbound_ssh_https_mgmt = aws_security_group.bastion.id
  aws_public_key_name                      = var.aws_key_name
  aws_disable_api_termination              = false
  number_of_nodes                          = var.rubrik_node_count
  force_destroy_s3_bucket                  = true
}
data "http" "ip" {
  url = "https://icanhazip.com"
  request_headers = {
    Accept = "text/*"
  }
}
resource "aws_key_pair" "openssh_key_pair" {
  key_name   = var.aws_key_name
  public_key = var.aws_key_pub
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
resource "aws_security_group" "bastion" {
  name        = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-bastion-securitygroup")
  description = "Allow inbound SSH from my workstation IP"
  vpc_id      = aws_vpc.rubrik_vpc.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-bastion-securitygroup")
  }
  ingress {
    description = "allow ssh from my workstation ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s%s", trimspace("${data.http.ip.response_body}"), "/32")]
  }
  ingress {
    description = "allow all inbound traffic from this security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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