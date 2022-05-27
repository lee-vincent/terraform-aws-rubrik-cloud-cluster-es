provider "aws" {
  region = var.aws_region
}

#############################
# Dynamic Variable Creation #
#############################
resource "null_resource" "create_cluster_node_name" {
  count = var.number_of_nodes

  triggers = {
    node_number = count.index + 1
  }
}

locals {
  cluster_node_name = formatlist("${var.aws_prefix}%s-%s", var.aws_region, null_resource.create_cluster_node_name.*.triggers.node_number)
  cluster_node_ips = aws_instance.rubrik_cluster.*.private_ip
}

data "aws_subnet" "rubrik_cloud_cluster" {
  id = var.aws_subnet_id
}

#########################################
# Security Group for the Rubrik Cluster #
#########################################

resource "aws_security_group" "rubrik_cloud_cluster" {
  name        = var.security_group_name_rubrik_cc_instances
  description = "Allow Rubrik Cloud Cluster intra-node communication"
  vpc_id      = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  ingress {
    description = "Intra cluster communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.security_group_id_inbound_ssh_https_mgmt}"]
  }
  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${var.security_group_id_inbound_ssh_https_mgmt}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "workload_instances" {
  name        = var.security_group_name_workloads
  description = "Allow Rubrik Cloud Cluster to communicate with workload instances"
  vpc_id      = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  ingress {
    description     = "Ports for Rubrik Backup Service (RBS)"
    from_port       = 12800
    to_port         = 12801
    protocol        = "tcp"
    security_groups = ["${aws_security_group.rubrik_cloud_cluster.id}"]
  }
}

###############################
# Create EC2 Instances in AWS #
###############################

resource "aws_instance" "rubrik_cluster" {
  count                  = var.number_of_nodes
  instance_type          = var.rubrik_instance_type
  ami                    = var.rubrik_ami_id
  iam_instance_profile   = aws_iam_instance_profile.rubrik_ec2_profile.name
  vpc_security_group_ids = [aws_security_group.rubrik_cloud_cluster.id]
  subnet_id              = var.aws_subnet_id
  key_name               = var.aws_public_key_name
  source_dest_check      = false
  tags = {
    Name = element(local.cluster_node_name, count.index)
  }
  disable_api_termination = var.aws_disable_api_termination
  root_block_device {
    encrypted = true
  }
  ebs_block_device {
    device_name           = "/dev/sdb"
    volume_type           = "gp2"
    volume_size           = "512"
    delete_on_termination = true
    encrypted             = true
    tags = {
      Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-ebsvolume")
    }
  }
}

resource "aws_s3_bucket" "rubrik_cc_es" {
  bucket_prefix = "rubrik-cc-es-"
  lifecycle {
    ignore_changes = [server_side_encryption_configuration]
  }
  tags = {
    Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-bucket")
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_sse" {
  bucket = aws_s3_bucket.rubrik_cc_es.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_iam_role" "rubrik_role" {
  name = format("%s%s%s", var.aws_prefix, var.aws_region, "-rubrik-s3-iamrole")
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

resource "aws_iam_role_policy" "rubrik_role_policy" {
  name = format("%s%s%s", var.aws_prefix, var.aws_region, "-rubrik-iamrolepolicy")
  role = aws_iam_role.rubrik_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:ListMultipartUploadParts",
          "s3:PutObject*"
        ],
        "Resource" : "${aws_s3_bucket.rubrik_cc_es.arn}/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetBucket*",
          "s3:ListBucket*"
        ],
        "Resource" : "${aws_s3_bucket.rubrik_cc_es.arn}"
      }
    ],
  })
}

resource "aws_iam_instance_profile" "rubrik_ec2_profile" {
  name = "rubrik-ec2-iam-profile"
  role = aws_iam_role.rubrik_role.name
}