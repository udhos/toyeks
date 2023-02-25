//
// https://karpenter.sh/v0.25.0/getting-started/migrating-from-cas/
//

resource "aws_iam_instance_profile" "KarpenterInstanceProfile" {
  name = "KarpenterInstanceProfile"
  role = aws_iam_role.toyeks_node_role.name
}

data "tls_certificate" "toyeks" {
  url = aws_eks_cluster.eks_toyeks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "toyeks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.toyeks.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.toyeks.url
}

data "aws_iam_policy_document" "karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.toyeks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.toyeks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.toyeks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "KarpenterControllerRole" {
  name = "KarpenterControllerRole-${var.eks_cluster_name}"

  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json

  inline_policy {
    name = "KarpenterControllerPolicy"

    policy = <<POLICY
{
    "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "eks:DescribeCluster",
                    "ssm:GetParameter",
                    "iam:PassRole",
                    "ec2:DescribeImages",
                    "ec2:RunInstances",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeLaunchTemplates",
                    "ec2:DescribeInstances",
                    "ec2:DescribeInstanceTypes",
                    "ec2:DescribeInstanceTypeOfferings",
                    "ec2:DescribeAvailabilityZones",
                    "ec2:DeleteLaunchTemplate",
                    "ec2:CreateTags",
                    "ec2:CreateLaunchTemplate",
                    "ec2:CreateFleet",
                    "ec2:DescribeSpotPriceHistory",
                    "pricing:GetProducts"
                ],
                "Effect": "Allow",
                "Resource": "*",
                "Sid": "Karpenter"
            },
            {
                "Action": "ec2:TerminateInstances",
                "Condition": {
                    "StringLike": {
                        "ec2:ResourceTag/Name": "*karpenter*"
                    }
                },
                "Effect": "Allow",
                "Resource": "*",
                "Sid": "ConditionalEC2Termination"
            }
        ]
}
POLICY
  }
}
