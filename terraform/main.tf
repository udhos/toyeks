
variable "region" {
  default = "us-east-2"
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
  region = var.region
  //shared_credentials_file = "~/.aws/creds"
  //profile                 = "profilename"
}

module "eks_toyeks_cluster1" {
  source           = "./module_eks"
  eks_cluster_name = "eks_toyeks_cluster1"
  region           = var.region
}

/*
module "eks_toyeks_cluster2" {
  source           = "./module_eks"
  eks_cluster_name = "eks_toyeks_cluster2"
  region           = var.region
}
*/