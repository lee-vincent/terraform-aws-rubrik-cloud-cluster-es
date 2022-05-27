This module creates a Rubrik Cloud Cluster ES with backup data stored on S3 instead of EBS.

```posh
module "rubrik-cloud-cluster-es" {
  source  = "lee-vincent/rubrik-cloud-cluster-es/aws"
  version = "1.2.0"
  # insert the 3 required variables here
  aws_subnet_id                            = aws_subnet.rubrik.id
  security_group_id_inbound_ssh_https_mgmt = aws_security_group.bastion.id
  aws_public_key_name                      = aws_key_pair.master_key_name
}
```