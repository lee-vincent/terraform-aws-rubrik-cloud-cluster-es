provider "aws" {
  region = var.aws_region
}

#############################
# Dynamic Variable Creation #
#############################
resource "null_resource" "create_cluster_node_name" {
  count = var.rubrik_node_count

  triggers = {
    node_number = count.index + 1
  }
}

locals {
  cluster_node_name    = formatlist("${var.aws_prefix}%s-%s", var.aws_region, null_resource.create_cluster_node_name.*.triggers.node_number)
  cluster_node_ips     = aws_instance.rubrik_cluster.*.private_ip
  rubrik_instance_type = "m5.4xlarge"
  rubrik_ami           = var.rubrik_ami != "" ? var.rubrik_ami : "${data.aws_ami.rubrik_ami.image_id}"
}

resource "local_file" "configure_sh" {
  count = var.bootstrap_cluster ? 1 : 0
  content = templatefile("${path.module}/bootstrap.tftpl",
    {
      rubrik_ip = "${aws_instance.rubrik_cluster.0.private_ip}",
      # rubrik_node_count = "${var.rubrik_node_count}",
      # ip_addrs          = "${aws_instance.rubrik_cluster.*.private_ip}",
      # rubrik_support_password       = "${var.rubrik_support_password}",
      # rubrik_admin_email            = "${var.rubrik_admin_email}",
      # rubrik_user                   = "${var.rubrik_user}",
      # rubrik_pass                   = "${var.rubrik_pass}",
      # rubrik_cluster_name           = "${var.rubrik_cluster_name}",
      # rubrik_s3_bucket              = "${module.rubrik-cloud-cluster.backup_bucket_name}",
      # rubrik_management_gateway     = cidrhost("${data.aws_subnet.rubrik.cidr_block}", 1)
      # rubrik_management_subnet_mask = cidrnetmask("${data.aws_subnet.rubrik.cidr_block}")
      # rubrik_dns_search_domain      = "${var.rubrik_dns_search_domain}"
      # rubrik_dns_nameservers        = "${var.rubrik_dns_nameservers}"
      # rubrik_ntp_servers            = "${var.rubrik_ntp_servers}"
      # rubrik_use_cloud_storage      = "${var.rubrik_use_cloud_storage}"
      # ssh_key_full_file_path        = "${local.ssh_key_full_file_path}"
      # rubrik_fileset_name_prefix    = "${var.rubrik_fileset_name_prefix}",
      # rubrik_fileset_folder_path    = "${var.rubrik_fileset_folder_path}",
      # workload_ip                   = "${aws_instance.workload_instance.private_ip}"
  })
  filename = "${path.module}/bootstrap.sh"
}

data "aws_subnet" "rubrik_cloud_cluster" {
  id = var.aws_subnet_id
}

data "aws_ami" "rubrik_ami" {
  owners      = ["aws-marketplace"]
  most_recent = true
  filter {
    name   = "name"
    values = ["rubrik-mp-cc-8*"]
  }
}

#########################################
# Security Group for the Rubrik Cluster #
#########################################

resource "aws_security_group" "rubrik_nodes" {
  name        = var.security_group_name_rubrik_cc_instances
  description = "Allow all between Rubrik nodes"
  vpc_id      = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  ingress {
    description = "allow all in between rubrik nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  egress {
    description = "allow all out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "bastion_rubrik" {
  name        = "bastion-rubrik-sg"
  description = "Allow management from bastion"
  vpc_id      = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  ingress {
    description = "allow https in between sg"
    from_port   = 443
    to_port     = 443
    protocol    = "-1"
    self        = true
  }
  ingress {
    description = "allow ssh in between sg"
    from_port   = 22
    to_port     = 22
    protocol    = "-1"
    self        = true
  }
  egress {
    description = "allow all out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
}
resource "aws_security_group" "ec2_workloads_rubrik" {
  name        = var.security_group_name_workloads
  description = "Allow inbound from Rubrik Cloud Cluster"
  vpc_id      = data.aws_subnet.rubrik_cloud_cluster.vpc_id
  ingress {
    description     = "Ports for Rubrik Backup Service (RBS)"
    from_port       = 12800
    to_port         = 12801
    protocol        = "tcp"
    security_groups = ["${aws_security_group.rubrik_nodes.id}"]
  }
}
###############################
# Create EC2 Instances in AWS #
###############################

resource "aws_instance" "rubrik_cluster" {
  count                = var.rubrik_node_count
  instance_type        = local.rubrik_instance_type
  ami                  = local.rubrik_ami
  iam_instance_profile = aws_iam_instance_profile.rubrik_ec2_profile.name
  vpc_security_group_ids = [
    aws_security_group.rubrik_nodes.id,
    aws_security_group.bastion_rubrik.id
  ]
  subnet_id         = var.aws_subnet_id
  key_name          = var.rubrik_key_name
  source_dest_check = false
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
  force_destroy = var.force_destroy_s3_bucket
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