
resource "aws_internet_gateway" "inet_gw_toyeks" {
  vpc_id = aws_vpc.vpc_toyeks.id

  tags = {
    Name = "inet_gw_${var.eks_cluster_name}"
  }
}

resource "aws_route_table" "route_table_pub_toyeks_a" {
  vpc_id = aws_vpc.vpc_toyeks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inet_gw_toyeks.id
  }

  tags = {
    Name = "route_table_pub_${var.eks_cluster_name}_a"
  }
}

resource "aws_route_table" "route_table_pub_toyeks_b" {
  vpc_id = aws_vpc.vpc_toyeks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inet_gw_toyeks.id
  }

  tags = {
    Name = "route_table_pub_${var.eks_cluster_name}_b"
  }
}

resource "aws_subnet" "subnet_pub_toyeks_a" {
  vpc_id            = aws_vpc.vpc_toyeks.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "${var.region}a"

  tags = {
    Name = "subnet_pub_${var.eks_cluster_name}_a"
  }
}

resource "aws_subnet" "subnet_pub_toyeks_b" {
  vpc_id            = aws_vpc.vpc_toyeks.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "${var.region}b"

  tags = {
    Name = "subnet_pub_${var.eks_cluster_name}_b"
  }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.subnet_pub_toyeks_a.id
  route_table_id = aws_route_table.route_table_pub_toyeks_a.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.subnet_pub_toyeks_b.id
  route_table_id = aws_route_table.route_table_pub_toyeks_b.id
}
