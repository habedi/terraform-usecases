# This Terraform configuration file sets up an AWS infrastructure with the following resources:
# - VPC
# - Internet Gateway
# - Subnet
# - Route Table and its association with the subnet
# - Security Group allowing SSH access
# - EC2 Instance
# - Key Pair for SSH access
# - Null resource to push the public key to the instance

# AWS Region to deploy the resources
provider "aws" {
    region = var.region
    profile = var.profile
}

# Network Resources
## Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "172.16.0.0/16"
}

## Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

## Create a subnet
resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "172.16.1.0/24"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
}

## Create a route table
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

## Associate the route table with the subnet
resource "aws_route_table_association" "public_association" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public_rt.id
}

## Create a security group
resource "aws_security_group" "allow_ssh" {
    name   = "allow_ssh"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 22
        to_port   = 22
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create an EC2 instance
resource "aws_instance" "single_server" {
    ami           = var.server.ami
    instance_type = var.server.instance_type

    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
    subnet_id = aws_subnet.public.id

    # Associate a public IP address with the instance
    associate_public_ip_address = true

    # Use the key pair created in the module
    key_name = aws_key_pair.my_key_pair.key_name

    # Run a command in the instance
    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update
                sudo apt-get upgrade -y
                sudo apt-get install pipx wget postgresql-client pgloader -y
                sudo -u ubuntu pipx install awscli harlequin[postgres]
                sudo -u ubuntu pipx ensurepath
                wget -c https://gist.githubusercontent.com/habedi/94831e88b7405f4bb7091009bd42b0f8/raw/697bf062cc003d136aaf0082554f159477c4377c/install_useful_cli_tools.sh
                chmod +x install_useful_cli_tools.sh
                ./install_useful_cli_tools.sh
                sudo apt-get autoremove -y
                sudo apt-get clean
                EOF

    # Define how Terraform connects to the instance
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ubuntu" # Default user for Ubuntu AMIs
        private_key = file(var.key_info.private_key_path) # Path to your private key
    }

    tags = {
        Name = "Single Server"
    }
}
