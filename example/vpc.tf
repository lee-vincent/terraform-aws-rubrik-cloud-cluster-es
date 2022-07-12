provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
data "local_sensitive_file" "ip" {
  depends_on = [
    null_resource.ip_check,
  ]
  filename = "${path.module}/ip.txt"
}
resource "null_resource" "ip_check" {
  # always check for a new workstation ip
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "echo -n $(curl https://icanhazip.com --silent)/32 > ip.txt"
  }
}
module "rubrik-cloud-cluster" {
  source                                   = "git::https://github.com/lee-vincent/terraform-aws-rubrik-cloud-cluster-es.git"
  aws_region                               = var.aws_region
  aws_subnet_id                            = aws_subnet.rubrik.id
  security_group_id_inbound_ssh_https_mgmt = aws_security_group.bastion.id
  aws_public_key_name                      = var.aws_key_name
  aws_disable_api_termination              = false
  number_of_nodes                          = var.rubrik_node_count
  force_destroy_s3_bucket                  = true
}
resource "aws_vpc" "rubrik_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-vpc")
  }
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-public-subnet")
  }
}
resource "aws_subnet" "workload" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-workload-subnet")
  }
}
resource "aws_subnet" "rubrik" {
  vpc_id            = aws_vpc.rubrik_vpc.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = format("%s%s", var.aws_region, var.aws_zone)
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-rubrik-subnet")
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.rubrik_vpc.id
  service_name    = format("%s%s%s", "com.amazonaws.", var.aws_region, ".s3")
  route_table_ids = [aws_route_table.cbs_routetable.id]
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-s3endpoint")
  }
}
resource "aws_internet_gateway" "cbs_internet_gateway" {
  vpc_id = aws_vpc.rubrik_vpc.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-internet-gateway")
  }
}
resource "aws_eip" "cbs_nat_gateway_eip" {
  vpc = true
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-internet-gateway-eip")
  }
}
resource "aws_nat_gateway" "cbs_nat_gateway" {
  allocation_id = aws_eip.cbs_nat_gateway_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-nat-gateway")
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.cbs_internet_gateway]
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
    cidr_blocks = ["${data.local_sensitive_file.ip.content}"]
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
  route_table_id = aws_route_table.cbs_routetable_public.id
}
resource "aws_route_table_association" "rubrik" {
  subnet_id      = aws_subnet.rubrik.id
  route_table_id = aws_route_table.cbs_routetable.id
}
resource "aws_route_table_association" "workload" {
  subnet_id      = aws_subnet.workload.id
  route_table_id = aws_route_table.cbs_routetable.id
}
resource "aws_route_table" "cbs_routetable" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.cbs_nat_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable")
  }
}
resource "aws_route_table" "cbs_routetable_public" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cbs_internet_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable-public")
  }
}
resource "aws_route_table" "cbs_routetable_main" {
  vpc_id = aws_vpc.rubrik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.cbs_nat_gateway.id
  }
  tags = {
    Name = format("%s%s", aws_vpc.rubrik_vpc.tags.Name, "-routetable-main")
  }
}
resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.rubrik_vpc.id
  route_table_id = aws_route_table.cbs_routetable_main.id
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
resource "aws_instance" "bastion_instance" {
  ami                    = data.aws_ami.amazon_linux2.image_id
  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.public.id
  key_name               = var.aws_key_name
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-bastion")
  }
  user_data                   = <<-EOF
    #!/bin/bash
    KEYPATH="${local.ssh_key_full_file_path}" && export KEYPATH
    touch $KEYPATH
    echo "${var.aws_key}" > $KEYPATH
    chmod 0400 $KEYPATH
    chown ec2-user:ec2-user $KEYPATH
    yum update -y
    amazon-linux-extras install epel -y
    yum install sshpass -y
    yum -y install jq
  EOF
  associate_public_ip_address = true
}