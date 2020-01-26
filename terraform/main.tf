
// https://learn.hashicorp.com/terraform/getting-started/build#configuration

locals {
  ami = "ami-1dab2163"
}

provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

resource "aws_vpc" "test" {
  cidr_block           = "192.168.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = "192.168.0.0/26"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
}

resource "aws_internet_gateway" "test" {
  vpc_id = aws_vpc.test.id
  tags = {
    Name = "test"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "public" {
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
    Name = "public"
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
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = concat([aws_security_group.public.id], data.aws_security_groups.default.ids)
  key_name               = "ssh-key"
  tags = {
    Name = "master"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.master.public_ip} > public_master_ip"
  }
}

resource "aws_instance" "worker" {
  ami           = local.ami
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = concat([aws_security_group.public.id], data.aws_security_groups.default.ids)
  key_name               = "master-to-worker"
  tags = {
    Name = "worker"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.worker.public_ip} > public_worker_ip"
  }
}
