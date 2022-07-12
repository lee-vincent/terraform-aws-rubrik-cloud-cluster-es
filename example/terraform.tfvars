# AWS Variables
aws_prefix        = "rubrik-cc-es-"
aws_region        = "us-east-1"
aws_profile       = "ahead-root"
aws_zone          = "a"
aws_instance_type = "t3.large"
aws_key_name      = "bilh-aws-demo-master-key"

rubrik_admin_email  = "vinnie.lee@ahead.com"
rubrik_cluster_name = "rubrik-cc-es"
rubrik_node_count   = 3

#################################################
# TF_VAR_ SENSITIVE local environment variables #
#################################################
# aws_key_pub             = TF_VAR_aws_key_pub
# aws_key                 = TF_VAR_aws_key
# rubrik_pass             = TF_VAR_rubrik_pass
# rubrik_support_password = TF_VAR_rubrik_support_password