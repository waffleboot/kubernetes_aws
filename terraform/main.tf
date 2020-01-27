
// https://learn.hashicorp.com/terraform/getting-started/build#configuration

locals {
  ami = "ami-1dab2163"
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
  enable_dns_hostnames = false
  tags = {
    Name = "test"
  }
}

# resource "aws_vpc" "kubernetes" {
#   cidr_block           = "172.16.0.0/24"
#   enable_dns_support   = true
#   enable_dns_hostnames = false
#   tags = {
#     Name = "kubernetes"
#   }
# }

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

resource "aws_security_group" "test" {
  vpc_id = aws_vpc.test.id
  name   = "public"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
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
    from_port   = 7080
    to_port     = 7080
  }
  tags = {
    Name = "test"
  }
  provisioner "local-exec" {
    command = "echo ${join(",", data.aws_security_groups.default.ids)} > kubernetes-security-group"
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.test.id]
  }
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

resource "aws_instance" "master" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.test.id
  vpc_security_group_ids = concat([aws_security_group.test.id], data.aws_security_groups.default.ids)
  key_name               = "ssh-key"
  iam_instance_profile   = aws_iam_instance_profile.network_profile.id
  tags = {
    Name = "master"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.master.public_ip} > public_master_ip"
  }
}

resource "aws_instance" "worker" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.test.id
  vpc_security_group_ids = concat([aws_security_group.test.id], data.aws_security_groups.default.ids)
  key_name               = "master-to-worker"
  iam_instance_profile   = aws_iam_instance_profile.network_profile.id
  tags = {
    Name = "worker"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.worker.public_ip} > public_worker_ip"
  }
}
