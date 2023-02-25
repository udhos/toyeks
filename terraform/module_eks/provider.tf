
data "aws_eks_cluster_auth" "eks_toyeks" {
  name = aws_eks_cluster.eks_toyeks.name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_toyeks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_toyeks.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.eks_toyeks.token
  }
}
