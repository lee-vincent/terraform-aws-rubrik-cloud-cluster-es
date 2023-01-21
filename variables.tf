variable "aws_region" {
  description = "The region to deploy Rubrik Cloud Cluster nodes."
  default     = "us-east-1"
}
variable "aws_prefix" {
  description = "prefix to add to tf created resources"
  default     = "tf-rubrik-cc-"
}
variable "aws_subnet_id" {
  description = "The VPC Subnet ID with route table s3 endpoint entry to launch Rubrik Cloud Cluster in."
}
variable "rubrik_key_name" {
  description = "The name of an existing AWS Keypair (OPENSSH formatted) for which you have access to the private key. Will be used for ssh to Rubrik Cloud Cluster nodes."
}
variable "rubrik_node_count" {
  description = "The total number of nodes in Rubrik Cloud Cluster ES."
  default     = 3
}
variable "bootstrap_cluster" {
  type    = bool
  default = true
}
variable "rubrik_ami" {
  description = "Rubrik CDM's AWS Marketplace AMD ID"
  default     = ""
}
variable "aws_disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection on the Rubrik Cloud Cluster nodes."
  default     = true
}
variable "security_group_name_rubrik_cc_instances" {
  description = "The name of the security group to create for Rubrik Cloud Cluster intra-node communication."
  default     = "rubrik-nodes-sg"
}
variable "security_group_name_workloads" {
  description = "The name of the security group to create for Rubrik Cloud Cluster to communicate with EC2 workload instances."
  default     = "ec2-workloads-rubrik-sg"
}
variable "force_destroy_s3_bucket" {
  description = "Force deletion of non-empty s3 bucket used for Rubrik backup data"
  type        = bool
  default     = false
}