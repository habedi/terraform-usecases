terraform {
    required_version = ">= 1.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 5.78" # Using the latest (current) version of the AWS provider
        }
    }
}