
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.56"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "aws" {
  region = var.region
  //shared_credentials_file = "~/.aws/creds"
  //profile                 = "profilename"
}
