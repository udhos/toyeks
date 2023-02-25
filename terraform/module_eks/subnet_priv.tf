
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
  subnet_id     = aws_subnet.subnet_pub_toyeks_a.id
  allocation_id = aws_eip.eip_toyeks_a.id

  tags = {
    Name = "toyeks_nat_gw_${var.eks_cluster_name}_a"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.inet_gw_toyeks]
}

resource "aws_nat_gateway" "toyeks_nat_gw_b" {
  subnet_id     = aws_subnet.subnet_pub_toyeks_b.id
  allocation_id = aws_eip.eip_toyeks_b.id

  tags = {
    Name = "toyeks_nat_gw_${var.eks_cluster_name}_b"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.inet_gw_toyeks]
}

resource "aws_route_table" "route_table_priv_toyeks_a" {
  vpc_id = aws_vpc.vpc_toyeks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.toyeks_nat_gw_a.id
  }

  tags = {
    Name = "route_table_priv_${var.eks_cluster_name}_a"
  }
}

resource "aws_route_table" "route_table_priv_toyeks_b" {
  vpc_id = aws_vpc.vpc_toyeks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.toyeks_nat_gw_b.id
  }

  tags = {
    Name = "route_table_priv_${var.eks_cluster_name}_b"
  }
}

resource "aws_subnet" "subnet_priv_toyeks_a" {
  vpc_id            = aws_vpc.vpc_toyeks.id
  cidr_block        = "10.0.32.0/20"
  availability_zone = "${var.region}a"

  tags = {
    Name                     = "subnet_priv_${var.eks_cluster_name}_a"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_subnet" "subnet_priv_toyeks_b" {
  vpc_id            = aws_vpc.vpc_toyeks.id
  cidr_block        = "10.0.48.0/20"
  availability_zone = "${var.region}b"

  tags = {
    Name                     = "subnet_priv_${var.eks_cluster_name}_b"
    "karpenter.sh/discovery" = var.eks_cluster_name
  }
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.subnet_priv_toyeks_a.id
  route_table_id = aws_route_table.route_table_priv_toyeks_a.id
}

resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.subnet_priv_toyeks_b.id
  route_table_id = aws_route_table.route_table_priv_toyeks_b.id
}
