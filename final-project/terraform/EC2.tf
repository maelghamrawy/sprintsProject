provider "aws" {
  region = "us-east-1" 
  profile = "default"
}

data "aws_ami" "amazon_ec2" {
      most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical 
}

resource "aws_instance" "ec2-sp" {
  ami           = data.aws_ami.amazon_ec2.image_id
  instance_type = "t2.medium"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.worker-sp.name

  tags = {
    Name = "Jenkins-Instance"
  }
}


#Resource:vpc
resource "aws_vpc" "vpc-sp" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-sp"
  }
}

#Resource:subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc-sp.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet-ec2"
  }
}

#Resource:igw
resource "aws_internet_gateway" "igw-ec2-sp" {
  vpc_id = aws_vpc.vpc-sp.id

  tags = {
    Name = "Internet Gateway-ec2"
  }
}

#Resoutce:route table
resource "aws_route_table" "rt-ec2-sp" {
  vpc_id = aws_vpc.vpc-sp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-ec2-sp.id
  }

  tags = {
    Name = "Route Table-ec2"
  }
}

#Resource:route table association
resource "aws_route_table_association" "rt_sp" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt-ec2-sp.id
}

#Resource:security group
resource "aws_security_group" "sg" {
  name   = "Terraform-sp"
  vpc_id = aws_vpc.vpc-sp.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

