################################################################################
# General Variables
################################################################################
variable "environment" {
    description = "The environment for the resources (e.g., dev, staging, prod)"
    default     = "my-dev"
}

variable "profile" {
    description = "The AWS profile to use."
    default     = "default"
}

variable "region" {
    description = "The region in which to create the resources."
    default     = "us-east-1"
}

variable "availability_zone_a" {
    description = "The availability zone A in which to create the resources."
    default     = "us-east-1a"
}

variable "availability_zone_b" {
    description = "The availability zone B in which to create the resources."
    default     = "us-east-1b"
}

################################################################################
# Compute Variables
################################################################################

variable "server" {
    description = "The AMI ID for the bastion host."
    default = {
        ami = "ami-0866a3c8686eaeeba" # Ubuntu Server 24.04 LTS (available in us-east-1 region)
        instance_type = "t2.micro"
    }
}

variable "key_info" {
    description = "The key pair information."
    default = {
        name             = "my-key-pair"
        private_key_path = "~/.ssh/id_ed25519"
        public_key_path  = "~/.ssh/id_ed25519.pub"
    }
}

resource "aws_key_pair" "my_key_pair" {
    key_name = var.key_info.name
    public_key = file(var.key_info.public_key_path)
}
