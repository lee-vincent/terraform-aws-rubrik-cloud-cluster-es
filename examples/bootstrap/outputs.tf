# Outputs for Rubrik Cloud Cluster
output "rubrik_ips" {
  value = module.rubrik_cloud_cluster.rubrik_cloud_cluster_ip_addrs[*]
}
output "rubrik_ami" {
  value = module.rubrik_cloud_cluster.rubrik_ami
}
output "rubrik_bucket" {
  value = module.rubrik_cloud_cluster.backup_bucket_name
}
output "bastion_ip" {
  value = aws_instance.bastion.public_ip
}

# # Command for running configure.sh script on the bastion instance
# output "secure_copy_configure_sh_command" {
#   value = format("%s", "scp -i $HOME/.ssh/${var.rubrik_key_name} -oStrictHostKeyChecking=no ${local_file.configure_sh.filename} ec2-user@${aws_instance.bastion.public_ip}:/home/ec2-user/ && ssh -i $HOME/.ssh/${var.aws_key_name} -oStrictHostKeyChecking=no ec2-user@${aws_instance.bastion_instance.public_ip} ./configure.sh")
# }
# # use this output to set up an ssh tunnel to the Pure and Rubrik management GUIs
# output "ssh_local_port_forwarding_command" {
#   value = format("%s", "ssh -N -i $HOME/.ssh/${var.aws_key_name} -L 8444:${module.rubrik-cloud-cluster.rubrik_cloud_cluster_ip_addrs[0]}:443 -oStrictHostKeyChecking=no -p 22 ec2-user@${aws_instance.bastion_instance.public_ip}")
# }
# output "rubrik_managment_url" {
#   value = format("%s", "https://localhost:8444")
# }