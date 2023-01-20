terraform {
  required_version = "~> 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.51.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}