output "rubrik_cloud_cluster_ip_addrs" {
  description = "Private IP Addresses of the Rubrik EC2 instances"
  value = aws_instance.rubrik_cluster.*.private_ip
}

output "workoad_security_group_id" {
  description = "Apply this security group to instances being backed up by Rubrik Cloud Cluster"
  value       = aws_security_group.workload_instances.id
}

output "backup_bucket_name" {
  description = "S3 bucket name to use during Rubrik bootstrap process"
  value = aws_s3_bucket.rubrik_cc_es.id
}