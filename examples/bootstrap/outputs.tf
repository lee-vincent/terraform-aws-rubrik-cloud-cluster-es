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
