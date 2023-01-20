# AWS Variables
aws_prefix          = "rubrik-cc-es-"
aws_region          = "us-west-1"
aws_zone            = "a"
aws_instance_type   = "t3.large"
rubrik_cluster_name = "rubrik-cc-es"
rubrik_node_count   = 3

#################################################
# TF_VAR_ SENSITIVE local environment variables #
#################################################
# aws_key_name            = TF_VAR_aws_key_name
# aws_key_pub             = TF_VAR_aws_key_pub
# aws_key                 = TF_VAR_aws_key
# rubrik_support_password = TF_VAR_rubrik_support_password
# rubrik_admin_email      = TF_VAR_rubrik_admin_email