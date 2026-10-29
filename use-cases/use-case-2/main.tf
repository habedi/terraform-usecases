# AWS Region to deploy the resources
provider "aws" {
  region  = var.region
  profile = var.profile
}

# Network Resources
## Create a VPC
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

## Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

## Create a public subnet (with internet access)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true
}

## Create a private subnet in AZ 1 (no internet access)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block_az1
  availability_zone = var.availability_zone_a
}

## Create a private subnet in AZ 2 (no internet access)
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block_az2
  availability_zone = var.availability_zone_b
}

## Create a route table for the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

## Associate the route table with the public subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

## Create a security group for EC2 (allow SSH)
resource "aws_security_group" "allow_ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Create a security group for RDS (allow access only from EC2)
resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_ssh.id] # Allow access only from the EC2 security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Create the RDS MySQL instance in the private subnet
resource "aws_db_instance" "my_mysql" {
  allocated_storage      = var.db_parameters.allocated_storage
  engine                 = var.db_parameters.engine
  instance_class         = var.db_parameters.instance_class
  db_name                = var.db_parameters.name
  username               = var.db_parameters.username
  password               = var.db_parameters.password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  skip_final_snapshot    = true

  # Deploying in a single availability zone for simplicity and cost savings
  availability_zone = var.availability_zone_a
}

## Create a DB subnet group for RDS
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name        = "my_db_subnet_group"
  subnet_ids  = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  description = "MySQL RDS subnet group"
}

## EC2 Instance in the public subnet
resource "aws_instance" "server_one" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.public.id

  associate_public_ip_address = true
}
