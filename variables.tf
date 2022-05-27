variable "aws_region" {
  description = "The region to deploy Rubrik Cloud Cluster nodes."
  default     = "us-east-1"
}

variable "rubrik_instance_type" {
  description = "The type of instance to use as Rubrik Cloud Cluster ES nodes."
  default     = "m5.4xlarge" # m5.4xlarge this is the only supported Rubrik CC ES instance type
}

variable "rubrik_ami_id" {
  description = "Rubrik CDM's AWS Marketplace AMD ID - by default deploys rubrik-cdm-7.0.1-p4-15453"
  default     = "ami-0095fefc7754e019c" #  rubrik-cdm-7.0.1-p4-15453
}

variable "aws_disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection on the Rubrik Cloud Cluster nodes."
  default     = true
}

variable "security_group_name_rubrik_cc_instances" {
  description = "The name of the security group to create for Rubrik Cloud Cluster intra-node communication."
  default     = "rubrik-cc-intra-node-securitygroup"
}

variable "security_group_id_inbound_ssh_https_mgmt" {
  description = "The id of the security group to allow inbound port 22/443 access from into Rubrik Cloud Cluster"
}

variable "security_group_name_workloads" {
  description = "The name of the security group to create for Rubrik Cloud Cluster to communicate with EC2 workload instances."
  default     = "rubrik-cc-workload-securitygroup"
}

variable "aws_subnet_id" {
  description = "The VPC Subnet ID with route table s3 endpoint entry to launch Rubrik Cloud Cluster in."
}

variable "aws_prefix" {
  description = "prefix to add to tf created resources"
  default     = "tf-rubrik-cc-"
}

variable "aws_public_key_name" {
  description = "The name of an existing OPENSSH formatted AWS key for use with Rubrik Cloud Cluster."
  sensitive   = true
}

variable "number_of_nodes" {
  description = "The total number of nodes in Rubrik Cloud Cluster ES."
  default     = 3
}