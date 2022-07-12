# AWS Variables
variable "aws_region" {
  type = string
}
variable "aws_zone" {
  type = string
}
variable "aws_profile" {
  type        = string
  description = "AWS profile"
}
variable "aws_key_name" {
  type = string
}
variable "aws_key_pub" {
  type      = string
  sensitive = true
}
variable "aws_key" {
  type = string
}
variable "aws_prefix" {
}
variable "aws_instance_type" {
  type        = string
  description = "EC2 instance type to use for the bastion host and workload host"
}
# Rubrik Cloud Cluster Variables
variable "rubrik_support_password" {
  type        = string
  description = "support.rubrik.com password"
}
variable "rubrik_admin_email" {
  type        = string
  description = "support.rubrik.com email - will also be used as admin email during cluster bootstrap"
}
variable "rubrik_user" {
  type        = string
  default     = "admin"
  description = "username to log in to Rubrik CDM GUI"
}
variable "rubrik_pass" {
  type        = string
  default     = "rubrik123"
  description = "password for Rubrik CDM GUI login"
}
variable "rubrik_cluster_name" {
  type    = string
  default = "rubrik-cloud-cluster"
}
variable "rubrik_node_count" {
  type    = number
  default = 3
}
variable "rubrik_dns_nameservers" {
  type    = string
  default = "8.8.8.8"
}
variable "rubrik_dns_search_domain" {
  type    = string
  default = ""
}
variable "rubrik_ntp_servers" {
  type    = string
  default = "pool.ntp.org"
}
variable "rubrik_use_cloud_storage" {
  type    = string
  default = "y"
}
variable "rubrik_fileset_name_prefix" {
  type    = string
  default = "EPIC"
}
variable "rubrik_fileset_folder_path" {
  type    = string
  default = "/mnt/epic-iscsi-vol"
}
# i can make this a local variable instead
variable "ssh_key_pair_path" {
  type    = string
  default = "/home/ec2-user/.ssh/"
}