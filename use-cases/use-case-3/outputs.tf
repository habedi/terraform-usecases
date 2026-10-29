################################################################################
# Networking Outputs
################################################################################
output "vpc_info" {
  description = "Details of the VPC and associated networking resources."
  value = {
    vpc_id                  = aws_vpc.main.id
    vpc_cidr_block          = aws_vpc.main.cidr_block
    public_subnet_id        = aws_subnet.public.id
    public_subnet_cidr      = aws_subnet.public.cidr_block
    private_subnet_az1_id   = aws_subnet.private_a.id
    private_subnet_az1_cidr = aws_subnet.private_a.cidr_block
    private_subnet_az2_id   = aws_subnet.private_b.id
    private_subnet_az2_cidr = aws_subnet.private_b.cidr_block
    internet_gateway_id     = aws_internet_gateway.igw.id
  }
}

################################################################################
# Database Outputs
################################################################################
output "aurora_postgresql_cluster" {
  description = "Aurora PostgreSQL cluster configuration details."
  value = {
    cluster_id              = aws_rds_cluster.aurora_pg.id
    cluster_endpoint        = aws_rds_cluster.aurora_pg.endpoint
    cluster_reader_endpoint = aws_rds_cluster.aurora_pg.reader_endpoint
    cluster_engine_version  = aws_rds_cluster.aurora_pg.engine_version
    db_name                 = var.db_parameters["db_name"]
    master_username         = var.db_parameters["username"]
    security_group_id       = aws_security_group.rds_sg.id
    db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
    cluster_arn             = aws_rds_cluster.aurora_pg.arn
  }
}

################################################################################
# Storage Outputs
################################################################################
output "s3_bucket_info" {
  description = "Details about the S3 bucket used for database dumps."
  value = {
    bucket_name    = aws_s3_bucket.database_dump.bucket
    bucket_arn     = aws_s3_bucket.database_dump.arn
    region         = var.region
    dump_file_key  = aws_s3_object.database_dump_file.key
    dump_file_etag = aws_s3_object.database_dump_file.etag
  }
}

################################################################################
# API Services Outputs
################################################################################
output "appsync_api_info" {
  description = "Details of the AppSync API configuration."
  value = {
    api_name            = aws_appsync_graphql_api.appsync_api.name
    graphql_endpoint    = aws_appsync_graphql_api.appsync_api.uris["GRAPHQL"]
    api_id              = aws_appsync_graphql_api.appsync_api.id
    authentication_type = aws_appsync_graphql_api.appsync_api.authentication_type
    datasource_name     = aws_appsync_datasource.aurora_ds.name
    service_role_arn    = aws_iam_role.appsync_role.arn
  }
}

################################################################################
# SIC Outputs
################################################################################
output "secrets_manager_info" {
  description = "Details about the AWS Secrets Manager secret for Aurora PostgreSQL credentials."
  value = {
    secret_name       = aws_secretsmanager_secret.aurora_pg_secret.name
    secret_arn        = aws_secretsmanager_secret.aurora_pg_secret.arn
    secret_version_id = aws_secretsmanager_secret_version.aurora_pg_secret_version.version_id
  }
}

output "iam_roles" {
  description = "IAM roles created for the infrastructure."
  value = {
    appsync_role_arn = aws_iam_role.appsync_role.arn
  }
}

################################################################################
# Compute Outputs
################################################################################
output "bastion_host_info" {
  description = "Details of the bastion host configuration."
  value = {
    bastion_host_ami_id      = var.bastion_host["ami"]
    bastion_host_instance_id = aws_instance.bastion_host.id
    bastion_host_public_ip   = aws_instance.bastion_host.public_ip
    bastion_host_key_name    = var.key_info["name"]
  }
}

################################################################################
# Extra Outputs
################################################################################
output "unique_id" {
  description = "Unique ID used for naming resources."
  value       = random_id.unique.hex
}
