
// https://learn.hashicorp.com/terraform/getting-started/build#configuration

locals {
  ami = "ami-0b7937aeb16a7eb94"
}

provider "aws" {
  profile = "kubernetes"
  region  = "eu-north-1"
}

resource "aws_iam_role" "network_role" {
  name               = "cni-ipvlan-vpc-k8s-role"
  assume_role_policy = <<EOF
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "network_policy" {
  name   = "cni-ipvlan-vpc-k8s-network-policy"
  role   = aws_iam_role.network_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DetachNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeVpcs",
        "ec2:DescribeVpcPeeringConnections",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:DeleteNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:UnassignPrivateIpAddresses",
        "ec2:DescribeSubnets",
        "ec2:AssignPrivateIpAddresses"],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "network_profile" {
  name = "cni-ipvlan-vpc-k8s-network-profile"
  role = aws_iam_role.network_role.id
}

resource "aws_vpc" "test" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "test" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "kubernetes" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "eu-north-1b"
  tags = {
    Name               = "kubernetes"
    kubernetes_kubelet = true
  }
}

resource "aws_default_security_group" "test" {
  vpc_id = aws_vpc.test.id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 30000
    to_port     = 30001
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 6443
    to_port     = 6443
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "test"
  }
}

resource "aws_security_group" "kubernetes" {
  vpc_id = aws_vpc.test.id
  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "kubernetes"
  }
  provisioner "local-exec" {
    command = "echo ${aws_security_group.kubernetes.id} > kubernetes-security-group"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id
  tags = {
    Name = "test"
  }
}

resource "aws_route_table" "test" {
  vpc_id = aws_vpc.test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "test" {
  subnet_id      = aws_subnet.test.id
  route_table_id = aws_route_table.test.id
}

resource "aws_instance" "master" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.test.id
  vpc_security_group_ids = [aws_default_security_group.test.id]
  key_name               = "ssh-key"
  iam_instance_profile   = aws_iam_instance_profile.network_profile.id
  tags = {
    Name = "master"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.master.public_ip} > public_master_ip"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.master.public_dns} > public_master_dns"
  }
}

resource "aws_instance" "worker" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.test.id
  vpc_security_group_ids = [aws_default_security_group.test.id]
  key_name               = "master-to-worker"
  iam_instance_profile   = aws_iam_instance_profile.network_profile.id
  tags = {
    Name = "worker"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.worker.public_ip} > public_worker_ip"
  }
}
