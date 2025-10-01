terraform {
required_providers {aws = {source = "hashicorp/aws"}}
}
provider "aws" {region = "us-east-1"}
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {"Name" = "jenkins_vpc"}
}
resource "aws_subnet" "jenkins_public_subnet" {
  vpc_id = aws_vpc.jenkins_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {"Name" = "jenkins_public_subnet" }
}
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags = {"Name" = "jenkins_igw"}
}
resource "aws_route_table" "jenkins_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }
  tags = {"Name" = "jenkins_route_table"}
}
resource "aws_route_table_association" "subnet_association" {
  route_table_id = aws_route_table.jenkins_rt.id
  subnet_id = aws_subnet.jenkins_public_subnet.id
}
resource "aws_security_group" "sg-jenkins" {
  vpc_id = aws_vpc.jenkins_vpc.id
  name = "jenkins-sg"
}
resource "aws_vpc_security_group_ingress_rule" "jenkins-allow-ssh" {
  security_group_id = aws_security_group.sg-jenkins.id
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  to_port = 22
}
resource "aws_vpc_security_group_egress_rule" "jenkins-egress" {
  security_group_id = aws_security_group.sg-jenkins.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

data "aws_ami" "amazon_linux2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "lab_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "lab_key" {
  key_name   = "jenkins_key"
  public_key = tls_private_key.lab_key.public_key_openssh
}

resource "local_file" "lab_private_key" {
  content  = tls_private_key.lab_key.private_key_pem
  filename = "${path.module}/jenkins_key.pem"
}

resource "aws_instance" "jenkins_agent" {
  ami = data.aws_ami.amazon_linux2023.id
  associate_public_ip_address = true
  instance_type = "t3.micro"
  key_name = aws_key_pair.lab_key.key_name
  vpc_security_group_ids = [aws_security_group.sg-jenkins.id]
  subnet_id = aws_subnet.jenkins_public_subnet.id
  tags = {
    "Name" = "jenkins-agent-instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.jenkins_agent.public_ip
}
