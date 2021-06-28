
variable "eks_cluster_name" {
  default = "eks_toyeks_cluster1"
}

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

resource "aws_vpc" "vpc_toyeks" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc_${var.eks_cluster_name}"
  }
}

resource "aws_internet_gateway" "inet_gw_toyeks" {
  vpc_id = aws_vpc.vpc_toyeks.id

  tags = {
    Name = "inet_gw_${var.eks_cluster_name}"
  }
}

resource "aws_eip" "eip_toyeks_a" {
  tags = {
    Name = "eip_${var.eks_cluster_name}_a"
  }
}

resource "aws_eip" "eip_toyeks_b" {
  tags = {
    Name = "eip_${var.eks_cluster_name}_b"
  }
}

resource "aws_nat_gateway" "toyeks_nat_gw_a" {
  subnet_id     = aws_subnet.subnet_toyeks_a.id
  allocation_id = aws_eip.eip_toyeks_a.id

  tags = {
    Name = "toyeks_nat_gw_${var.eks_cluster_name}_a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.inet_gw_toyeks]
}

resource "aws_nat_gateway" "toyeks_nat_gw_b" {
  subnet_id     = aws_subnet.subnet_toyeks_b.id
  allocation_id = aws_eip.eip_toyeks_b.id

  tags = {
    Name = "toyeks_nat_gw_${var.eks_cluster_name}_b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.inet_gw_toyeks]
}

resource "aws_route_table" "route_table_toyeks_a" {
  vpc_id = aws_vpc.vpc_toyeks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.toyeks_nat_gw_a.id
  }

  tags = {
    Name = "route_table_${var.eks_cluster_name}_a"
  }
}

resource "aws_route_table" "route_table_toyeks_b" {
  vpc_id = aws_vpc.vpc_toyeks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.toyeks_nat_gw_b.id
  }

  tags = {
    Name = "route_table_${var.eks_cluster_name}_b"
  }
}

resource "aws_subnet" "subnet_toyeks_a" {
  vpc_id            = aws_vpc.vpc_toyeks.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "${var.region}a"

  tags = {
    Name = "subnet_${var.eks_cluster_name}_a"
  }
}

resource "aws_subnet" "subnet_toyeks_b" {
  vpc_id            = aws_vpc.vpc_toyeks.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "${var.region}b"

  tags = {
    Name = "subnet_${var.eks_cluster_name}_b"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_toyeks_a.id
  route_table_id = aws_route_table.route_table_toyeks_a.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_toyeks_b.id
  route_table_id = aws_route_table.route_table_toyeks_b.id
}

resource "aws_security_group" "toyeks_nodes" {
  name        = "${var.eks_cluster_name}_toyeks_nodes"
  description = "${var.eks_cluster_name} toyeks nodes"
  vpc_id      = aws_vpc.vpc_toyeks.id

  tags = {
    Name = "${var.eks_cluster_name}_toyeks_nodes"
  }
}

resource "aws_security_group_rule" "toyeks_nodes_in" {
  description              = "Allow traffic among nodes"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  security_group_id        = aws_security_group.toyeks_nodes.id
  source_security_group_id = aws_security_group.toyeks_nodes.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "toyeks_nodes_out" {
  description       = "toyeks_nodes_out"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  security_group_id = aws_security_group.toyeks_nodes.id
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

resource "aws_iam_role" "eks_toyeks_cluster_role" {
  name = "${var.eks_cluster_name}_cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_role_toyeks_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_toyeks_cluster_role.name
}

resource "aws_cloudwatch_log_group" "toyeks_logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30
}

resource "aws_eks_cluster" "eks_toyeks" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_toyeks_cluster_role.arn
  version  = "1.20"

  vpc_config {
    security_group_ids      = [aws_security_group.toyeks_nodes.id]
    subnet_ids              = [aws_subnet.subnet_toyeks_a.id, aws_subnet.subnet_toyeks_b.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  kubernetes_network_config {
    /*
    service_ipv4_cidr:
    The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes
    assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks. We recommend that you
    specify a block that does not overlap with resources in other networks that are peered or connected
    to your VPC. You can only specify a custom CIDR block when you create a cluster, changing this value
    will force a new cluster to be created.
    */
    service_ipv4_cidr = "10.99.0.0/16"
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_cloudwatch_log_group.toyeks_logs,
    aws_iam_role_policy_attachment.eks_role_toyeks_policy_attachment
  ]
}

resource "aws_iam_policy" "toyeks_node_role_autoscaling" {
  name        = "${var.eks_cluster_name}_node_role_autoscaling"
  path        = "/"
  description = "Allow nodes to call autoscaling APIs."

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role" "toyeks_node_role" {
  name = "${var.eks_cluster_name}_node_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "toyeks_node_policy_attachment_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.toyeks_node_role.name
}

resource "aws_iam_role_policy_attachment" "toyeks_node_policy_attachment_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.toyeks_node_role.name
}

resource "aws_iam_role_policy_attachment" "toyeks_node_policy_attachment_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.toyeks_node_role.name
}

resource "aws_iam_role_policy_attachment" "toyeks_node_policy_attachment_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.toyeks_node_role.name
}

resource "aws_iam_role_policy_attachment" "toyeks_node_policy_attachment_autoscaling" {
  policy_arn = aws_iam_policy.toyeks_node_role_autoscaling.arn
  role       = aws_iam_role.toyeks_node_role.name
}

resource "aws_eks_node_group" "toyeks_node_group_a" {
  cluster_name    = aws_eks_cluster.eks_toyeks.name
  node_group_name = "toyeks_node_group_a"
  node_role_arn   = aws_iam_role.toyeks_node_role.arn
  subnet_ids      = [aws_subnet.subnet_toyeks_a.id]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_autoscaling,
  ]
}

resource "aws_eks_node_group" "toyeks_node_group_b" {
  cluster_name    = aws_eks_cluster.eks_toyeks.name
  node_group_name = "toyeks_node_group_b"
  node_role_arn   = aws_iam_role.toyeks_node_role.arn
  subnet_ids      = [aws_subnet.subnet_toyeks_b.id]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.toyeks_node_policy_attachment_autoscaling,
  ]
}
