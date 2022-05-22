output "rubrik_cloud_cluster_ip_addrs" {
  value = aws_instance.rubrik_cluster.*.private_ip
}

output "workoad_security_group_id" {
  description = "Apply this security to instances being backed up by Rubrik Cloud Cluster"
  value       = aws_security_group.workload_instances.id
}