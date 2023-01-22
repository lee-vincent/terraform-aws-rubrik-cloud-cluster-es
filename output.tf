output "rubrik_cloud_cluster_ip_addrs" {
  description = "Private IP Addresses of the Rubrik EC2 instances"
  value       = aws_instance.rubrik_cluster[*].private_ip
}
output "workoad_security_group_id" {
  description = "Apply this security group to instances being backed up by Rubrik Cloud Cluster"
  value       = aws_security_group.ec2_workloads_rubrik.id
}
output "bastion_rubrik_security_group" {
  value = aws_security_group.bastion_rubrik.id
}
output "backup_bucket_name" {
  description = "S3 bucket name to use during Rubrik bootstrap process"
  value       = aws_s3_bucket.rubrik_cc_es.id
}
output "rubrik_ami" {
  value = aws_instance.rubrik_cluster[0].ami
}