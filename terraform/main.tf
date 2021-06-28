
variable "region" {
  default = "us-east-2"
}

variable "aws_profile" {
  type = string
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/creds"
  profile                 = var.aws_profile
}

resource "aws_vpc" "vpc_eks" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc_eks"
  }
}
