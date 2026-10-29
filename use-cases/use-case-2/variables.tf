variable "profile" {
  description = "The AWS profile to use."
  default     = "terraform" # Assuming you have a profile named "terraform" set up that has the necessary permissions
}

variable "ami_id" {
  description = "The ID of the AMI to use for the instance."
  default     = "ami-04a81a99f5ec58529"
}

variable "instance_type" {
  description = "The type of instance to launch."
  default     = "t2.micro"
}

variable "region" {
  description = "The region in which to create the resources."
  default     = "us-east-1"
}

variable "availability_zone_a" {
  description = "The availability zone a in which to create the resources."
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "The availability zone b in which to create the resources."
  default     = "us-east-1b"
}

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

variable "db_parameters" {
  description = "The parameters for the RDS database."
  default = {
    allocated_storage = 20
    engine            = "mysql"
    instance_class    = "db.t3.micro"
    name              = "mydb"
    username          = "admin"
    password          = "mypassword"
  }
}
