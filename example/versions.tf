terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.2.0"
    }
  }
}