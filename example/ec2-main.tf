data "aws_subnet" "rubrik" {
  id = aws_subnet.rubrik.id
}
locals {
  ssh_key_full_file_path = format("%s%s", "${var.ssh_key_pair_path}", "${var.aws_key_name}")
}
resource "local_file" "configure_sh" {
  content = templatefile("${path.module}/configure.tftpl",
    {
      rubrik_ip                     = "${module.rubrik-cloud-cluster.rubrik_cloud_cluster_ip_addrs[0]}",
      rubrik_node_count             = "${var.rubrik_node_count}",
      ip_addrs                      = "${module.rubrik-cloud-cluster.rubrik_cloud_cluster_ip_addrs[*]}",
      rubrik_support_password       = "${var.rubrik_support_password}",
      rubrik_admin_email            = "${var.rubrik_admin_email}",
      rubrik_user                   = "${var.rubrik_user}",
      rubrik_pass                   = "${var.rubrik_pass}",
      rubrik_cluster_name           = "${var.rubrik_cluster_name}",
      rubrik_s3_bucket              = "${module.rubrik-cloud-cluster.backup_bucket_name}",
      rubrik_management_gateway     = cidrhost("${data.aws_subnet.rubrik.cidr_block}", 1)
      rubrik_management_subnet_mask = cidrnetmask("${data.aws_subnet.rubrik.cidr_block}")
      rubrik_dns_search_domain      = "${var.rubrik_dns_search_domain}"
      rubrik_dns_nameservers        = "${var.rubrik_dns_nameservers}"
      rubrik_ntp_servers            = "${var.rubrik_ntp_servers}"
      rubrik_use_cloud_storage      = "${var.rubrik_use_cloud_storage}"
      ssh_key_full_file_path        = "${local.ssh_key_full_file_path}"
      rubrik_fileset_name_prefix    = "${var.rubrik_fileset_name_prefix}",
      rubrik_fileset_folder_path    = "${var.rubrik_fileset_folder_path}",
      workload_ip                   = "${aws_instance.workload_instance.private_ip}"
  })
  filename = "${path.module}/configure.sh"
}
resource "aws_key_pair" "openssh_key_pair" {
  key_name   = var.aws_key_name
  public_key = var.aws_key_pub
}
resource "aws_instance" "workload_instance" {
  depends_on = [
    module.rubrik-cloud-cluster,
  ]
  ami                    = data.aws_ami.amazon_linux2.image_id
  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.bastion.id, module.rubrik-cloud-cluster.workoad_security_group_id]
  get_password_data      = false
  subnet_id              = aws_subnet.workload.id
  key_name               = var.aws_key_name
  tags = {
    Name = "workload_instance"
  }
  root_block_device {
    volume_size           = "64"
    delete_on_termination = true
    encrypted             = true
    tags = {
      Name = format("%s%s%s", var.aws_prefix, var.aws_region, "-ebsvolume")
    }
  }
  user_data = <<-EOF1
    #!/bin/bash
    KEYPATH="${local.ssh_key_full_file_path}" && export KEYPATH
    touch $KEYPATH
    echo "${var.aws_key}" > $KEYPATH
    chmod 0400 $KEYPATH
    chown ec2-user:ec2-user $KEYPATH
    yum update -y
    amazon-linux-extras install epel -y
    PURE_VOL_NAME="epic-iscsi-vol"
    PURE_MOUNT_PATH="/mnt/$PURE_VOL_NAME"
    mkdir $PURE_MOUNT_PATH
    wget -O /mnt/$PURE_VOL_NAME/win22.vhd https://go.microsoft.com/fwlink/p/?linkid=2195166&clcid=0x409&culture=en-us&country=us
    chown -R ec2-user:ec2-user $PURE_MOUNT_PATH
  EOF1
}