# AWS Variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_zone" {
  type    = string
  default = "a"
}
variable "aws_key_name" {
  type    = string
  default = "rubrik-key"
}
variable "aws_key_pub" {
  type    = string
  default = "test"
}
variable "aws_prefix" {
  default = "rubrik-cc-es"
}
variable "aws_instance_type" {
  type        = string
  description = "EC2 instance type to use for the bastion host and workload host"
  default     = "t3.large"
}
# Rubrik Cloud Cluster Variables
variable "rubrik_support_password" {
  type        = string
  description = "support.rubrik.com password"
  default     = "password"
}
variable "rubrik_admin_email" {
  type        = string
  description = "support.rubrik.com email - will also be used as admin email during cluster bootstrap"
  default     = "test@test.com"
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
  default = "Epic"
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
variable "aws_key" {
  default = "private-key"
}