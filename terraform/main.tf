
variable "region" {
  default = "us-east-2"
}

variable "cluster_version" {
  default = "1.25"
}

variable "nodegroup_a_version" {
  default = "1.25"
}

variable "nodegroup_b_version" {
  default = "1.25"
}

variable "nodegroup_a_capacity_type" {
  default = "SPOT"
}

variable "nodegroup_b_capacity_type" {
  default = "SPOT"
}

variable "nodegroup_a_instance_types" {
  default = ["t3.medium"]
}

variable "nodegroup_b_instance_types" {
  default = ["t3.medium"]
}

module "eks_toyeks_cluster1" {
  source                     = "./module_eks"
  eks_cluster_name           = "eks_toyeks_cluster1"
  region                     = var.region
  cluster_version            = var.cluster_version
  nodegroup_a_version        = var.nodegroup_a_version
  nodegroup_b_version        = var.nodegroup_b_version
  nodegroup_a_capacity_type  = var.nodegroup_a_capacity_type
  nodegroup_b_capacity_type  = var.nodegroup_b_capacity_type
  nodegroup_a_instance_types = var.nodegroup_a_instance_types
  nodegroup_b_instance_types = var.nodegroup_b_instance_types
}

/*
module "eks_toyeks_cluster2" {
  source           = "./module_eks"
  eks_cluster_name = "eks_toyeks_cluster2"
  region           = var.region
}
*/