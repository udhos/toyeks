
variable "eks_cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "nodegroup_a_version" {
  type = string
}

variable "nodegroup_b_version" {
  type = string
}

variable "nodegroup_a_capacity_type" {
  type = string
}

variable "nodegroup_b_capacity_type" {
  type = string
}

variable "nodegroup_a_instance_types" {
  type = list
}

variable "nodegroup_b_instance_types" {
  type = list
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

resource "aws_security_group" "toyeks_nodes" {
  name        = "${var.eks_cluster_name}_toyeks_nodes"
  description = "${var.eks_cluster_name} toyeks nodes"
  vpc_id      = aws_vpc.vpc_toyeks.id

  tags = {
    Name = "${var.eks_cluster_name}_toyeks_nodes"
    "karpenter.sh/discovery" = var.eks_cluster_name
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
  version  = var.cluster_version

  vpc_config {
    security_group_ids      = [aws_security_group.toyeks_nodes.id]
    subnet_ids              = [aws_subnet.subnet_priv_toyeks_a.id, aws_subnet.subnet_priv_toyeks_b.id]
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
  subnet_ids      = [aws_subnet.subnet_priv_toyeks_a.id]

  version = var.nodegroup_a_version
  capacity_type = var.nodegroup_a_capacity_type
  instance_types = var.nodegroup_a_instance_types

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
  subnet_ids      = [aws_subnet.subnet_priv_toyeks_b.id]

  version = var.nodegroup_b_version
  capacity_type = var.nodegroup_b_capacity_type
  instance_types = var.nodegroup_b_instance_types

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
