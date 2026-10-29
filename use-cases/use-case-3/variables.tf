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
# Networking Variables
################################################################################
variable "cidr_block" {
  description = "The CIDR block for the VPC."
  default     = "172.16.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "The CIDR block for the public subnet."
  default     = "172.16.1.0/24"
}

variable "private_subnet_cidr_block_az1" {
  description = "The CIDR block for the private subnet in AZ 1."
  default     = "172.16.2.0/24"
}

variable "private_subnet_cidr_block_az2" {
  description = "The CIDR block for the private subnet in AZ 2."
  default     = "172.16.3.0/24"
}

################################################################################
# Database Variables
################################################################################
variable "db_parameters" {
  description = "The parameters for the RDS Aurora PostgreSQL database."
  default = {
    db_name                        = "auroradb"
    username                       = "root"
    password                       = "password"
    db_port                        = 5432
    db_engine_version              = "16.4"
    engine                         = "aurora-postgresql"
    cluster_identifier             = "aurora-pg-cluster"
    backup_retention_period        = 7
    aurora_serverless_min_capacity = 0.5
    aurora_serverless_max_capacity = 1
  }
}

################################################################################
# Storage variables
################################################################################
variable "db_dump_file" {
  description = "The path to the database dump file."
  default     = "./assets/db/db.sql.gz"
}

################################################################################
# Compute Variables
################################################################################
variable "bastion_host" {
  description = "The AMI ID for the bastion host."
  default = {
    ami           = "ami-0866a3c8686eaeeba" # Ubuntu Server 24.04 LTS (available in us-east-1 region)
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

################################################################################
# API Services Variables
################################################################################
variable "api_key_expiration_days" {
  default     = 30
  description = "Number of days before the AppSync API keys expire."
}
