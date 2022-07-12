This module creates a Rubrik Cloud Cluster ES with backup data stored on S3 instead of EBS.

The full example in the example folder deploys all pre-requisite VPC infrastructure, Rubrik Cloud Cluster ES nodes, and
provides a one-line command to automatically bootstrap the cluster and configure the RBS agent and backups. It serves
as a useful tutorial in using ssh and curl to interact with the Rubrik API.

```sh
module "rubrik-cloud-cluster-es" {
  source  = "lee-vincent/rubrik-cloud-cluster-es/aws"
  version = "1.2.4"
  # insert the 3 required variables here
  aws_subnet_id                            = aws_subnet.rubrik.id
  security_group_id_inbound_ssh_https_mgmt = aws_security_group.bastion.id
  aws_public_key_name                      = aws_key_pair.master_key_name
}
```