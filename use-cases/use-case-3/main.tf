provider "aws" {
  region  = var.region
  profile = var.profile
}

################################################################################
# Networking Resources
################################################################################
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true # Enable DNS resolution
  enable_dns_hostnames = true # Enable DNS hostnames

  tags = {
    Name        = "Main VPC"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "Internet Gateway"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true # Automatically assign public IPs to instances in this subnet

  tags = {
    Name        = "Public Subnet"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Route all traffic to the internet gateway
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "Public Route Table"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block_az1
  availability_zone = var.availability_zone_a

  tags = {
    Name        = "Private Subnet AZ1"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_block_az2
  availability_zone = var.availability_zone_b

  tags = {
    Name        = "Private Subnet AZ2"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name = "aurora_subnet_group"
  subnet_ids = [
    aws_subnet.public.id,    # Include the public subnet for public accessibility
    aws_subnet.private_a.id, # Private subnet for AZ1
    aws_subnet.private_b.id  # Private subnet for AZ2
  ]

  tags = {
    Name        = "Aurora DB Subnet Group"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.db_parameters.db_port
    to_port     = var.db_parameters.db_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from any IP (update for production security)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "RDS Security Group"
    Environment = var.environment
  }
}

resource "aws_security_group" "allow_ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access from any IP (update for production security)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"] # Allow access from any IP (update for production security)
  }

  tags = {
    Name        = "SSH Security Group"
    Environment = var.environment
  }
}

################################################################################
# API Services Resources
################################################################################
data "aws_iam_policy_document" "appsync_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "appsync_role" {
  name = "appsync-access-rds"

  assume_role_policy = data.aws_iam_policy_document.appsync_assume_role.json

  tags = {
    Name        = "AppSync Role"
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "appsync_rds_policy" {
  statement {
    effect = "Allow"
    actions = [
      "rds-data:ExecuteStatement",
      "rds-data:BatchExecuteStatement",
      "rds-data:BeginTransaction",
      "rds-data:CommitTransaction",
      "rds-data:RollbackTransaction",

      # Allow AppSync to access the secretmanager secrets to get the database credentials
      "secretsmanager:GetSecretValue"

    ]
    resources = ["*"] # Replace "*" with specific ARNs for better security in production
  }
}

resource "aws_iam_role_policy" "appsync_rds_policy" {
  name   = "appsync-rds-policy"
  role   = aws_iam_role.appsync_role.id
  policy = data.aws_iam_policy_document.appsync_rds_policy.json
}

resource "aws_appsync_graphql_api" "appsync_api" {
  authentication_type = "API_KEY"
  name                = "roles-api"

  #additional_authentication_provider {
  #    authentication_type = "AWS_IAM"
  #}

  # Define the schema for the API
  schema = file("${path.module}/assets/apis/roles/schema.graphql")

  # Choose between GLOBAL and PRIVATE visibility; Default is GLOBAL; can't be changed after creation
  visibility = "GLOBAL"

  # Enable CloudWatch logging for the API
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs_role.arn
    field_log_level          = "ALL" # Possible values: NONE, ERROR, ALL (Modify as needed)
    exclude_verbose_content  = false # Set to true to exclude detailed resolver info
  }

  tags = {
    Name        = "AppSync API for Roles"
    Environment = var.environment
  }
}

resource "aws_appsync_datasource" "aurora_ds" {
  api_id           = aws_appsync_graphql_api.appsync_api.id
  name             = "aurora_ds"
  type             = "RELATIONAL_DATABASE"
  service_role_arn = aws_iam_role.appsync_role.arn

  relational_database_config {
    source_type = "RDS_HTTP_ENDPOINT"
    http_endpoint_config {
      db_cluster_identifier = aws_rds_cluster.aurora_pg.arn
      aws_secret_store_arn  = aws_secretsmanager_secret.aurora_pg_secret.arn
      database_name         = var.db_parameters.db_name
      region                = var.region
      #schema                = "core_model" # Optional: public (Must not be specified for Aurora PostgreSQL serverless)
    }
  }

  # Depends on the API
  depends_on = [aws_appsync_graphql_api.appsync_api]
}

resource "aws_appsync_api_key" "appsync_key" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  description = "API Key for accessing AppSync API"
  expires     = timeadd(timestamp(), format("%ds", var.api_key_expiration_days * 86400)) # 30 days in seconds

  # Depends on the API
  depends_on = [aws_appsync_graphql_api.appsync_api]
}

## Resolver Definitions

# Define the resolver for the getRole query
resource "aws_appsync_resolver" "get_role_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Query"
  field       = "getRole"
  data_source = aws_appsync_datasource.aurora_ds.name

  request_template  = file("${path.module}/assets/apis/roles/resolvers/getRole/request.vtl")
  response_template = file("${path.module}/assets/apis/roles/resolvers/getRole/response.vtl")

  caching_config {
    caching_keys = [
      "$context.identity.sub",
      "$context.arguments.id",
    ]
    ttl = 60
  }
}

# Define the resolver for the listRoles query
resource "aws_appsync_resolver" "list_roles_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Query"
  field       = "listRoles"
  data_source = aws_appsync_datasource.aurora_ds.name

  # Using JS instead of VTL for the resolver implementation
  code = file("${path.module}/assets/apis/roles/resolvers/listRoles/resolver.js")

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  caching_config {
    caching_keys = [
      "$context.identity.sub",
      "$context.arguments.limit",
      "$context.arguments.nextToken",
    ]
    ttl = 60
  }

  depends_on = [aws_appsync_datasource.aurora_ds]
}

# Define the resolver for the createRole mutation
resource "aws_appsync_resolver" "create_role_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Mutation"
  field       = "createRole"
  data_source = aws_appsync_datasource.aurora_ds.name

  request_template  = file("${path.module}/assets/apis/roles/resolvers/createRole/request.vtl")
  response_template = file("${path.module}/assets/apis/roles/resolvers/createRole/response.vtl")

  depends_on = [aws_appsync_datasource.aurora_ds]
}

# Define the resolver for the updateRole mutation
resource "aws_appsync_resolver" "update_role_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Mutation"
  field       = "updateRole"
  data_source = aws_appsync_datasource.aurora_ds.name

  request_template  = file("${path.module}/assets/apis/roles/resolvers/updateRole/request.vtl")
  response_template = file("${path.module}/assets/apis/roles/resolvers/updateRole/response.vtl")

  depends_on = [aws_appsync_datasource.aurora_ds]
}

# Define the resolver for the deleteRole mutation
resource "aws_appsync_resolver" "delete_role_resolver" {
  api_id      = aws_appsync_graphql_api.appsync_api.id
  type        = "Mutation"
  field       = "deleteRole"
  data_source = aws_appsync_datasource.aurora_ds.name

  # Using JS instead of VTL for the resolver implementation
  code = file("${path.module}/assets/apis/roles/resolvers/deleteRole/resolver.js")

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  depends_on = [aws_appsync_datasource.aurora_ds]
}

################################################################################
# Monitoring Resources
################################################################################
resource "aws_iam_role" "appsync_logs_role" {
  name = "appsync-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "appsync.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "appsync_logs_policy" {
  name = "appsync-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = ["arn:aws:logs:*:*:log-group:/aws/appsync/apis/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "appsync_logs_attach" {
  role       = aws_iam_role.appsync_logs_role.name
  policy_arn = aws_iam_policy.appsync_logs_policy.arn
}

# resource "aws_cloudwatch_log_group" "appsync_log_group" {
#     name              = "/aws/appsync/apis/roles"
#     retention_in_days = 1 # Optional: Set retention period for logs
# }

################################################################################
# Database Resources
################################################################################
resource "aws_rds_cluster" "aurora_pg" {
  engine                 = var.db_parameters.engine
  engine_version         = var.db_parameters.db_engine_version
  cluster_identifier     = var.db_parameters.cluster_identifier
  database_name          = var.db_parameters.db_name
  master_username        = var.db_parameters.username
  master_password        = var.db_parameters.password
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = var.db_parameters.backup_retention_period
  storage_encrypted       = true # Enable encryption for storage
  engine_mode             = "provisioned"

  # Serverless configuration (Capacity in Aurora Serverless v2)
  serverlessv2_scaling_configuration {
    min_capacity = var.db_parameters.aurora_serverless_min_capacity # Min capacity for scaling
    max_capacity = var.db_parameters.aurora_serverless_max_capacity # Max capacity for scaling
  }

  # Enable the Data API for easier access through AppSync
  enable_http_endpoint = true

  # Skip the final snapshot when the cluster is deleted
  skip_final_snapshot = true

  tags = {
    Name        = "Aurora PostgreSQL Cluster"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_instance" "aurora_pg_instance" {
  cluster_identifier  = aws_rds_cluster.aurora_pg.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora_pg.engine
  engine_version      = aws_rds_cluster.aurora_pg.engine_version
  publicly_accessible = true # Ensure public access is enabled

  tags = {
    Name        = "Aurora PG Instance"
    Environment = var.environment
  }
}

################################################################################
# Storage Resources
################################################################################
resource "aws_s3_bucket" "database_dump" {
  bucket        = "database-dump-bucket-${var.environment}-${random_id.unique.hex}"
  force_destroy = true

  tags = {
    Name        = "Database Dump Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "database_dump_block" {
  bucket                  = aws_s3_bucket.database_dump.id
  block_public_acls       = false # Set to true to block public ACLs
  block_public_policy     = false # Set to true to block public policies
  ignore_public_acls      = false # Set to true to ignore public ACLs
  restrict_public_buckets = false # Set to true to restrict public buckets
}

resource "aws_s3_bucket_policy" "database_dump_policy" {
  bucket = aws_s3_bucket.database_dump.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowReadWriteAccess",
        Effect    = "Allow",
        Principal = "*", # Replace "*" with specific IAM roles/users for security
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.database_dump.id}/*"
        ]
      }
    ]
  })
}

resource "null_resource" "prefetch_database_dump_file" {
  provisioner "local-exec" {
    command = "test -f ${var.db_dump_file} || (echo 'File not found!' && exit 1)"
  }
}

resource "aws_s3_object" "database_dump_file" {
  depends_on = [null_resource.prefetch_database_dump_file]

  bucket = aws_s3_bucket.database_dump.id
  key    = "db.sql.gz"
  source = var.db_dump_file # Reference the variable here
}

################################################################################
# Compute Resources
################################################################################
resource "aws_instance" "bastion_host" {
  ami           = var.bastion_host.ami
  instance_type = var.bastion_host.instance_type

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.public.id

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

  # Add the db dump file to the instance
  provisioner "file" {
    source      = var.db_dump_file
    destination = "/tmp/db.sql.gz"
  }

  # Load the database dump into RDS Aurora PostgreSQL
  provisioner "remote-exec" {
    inline = [
      "while ! command -v psql > /dev/null; do echo 'Waiting for psql to be installed...' && sleep 5; done",
      "export PGPASSWORD=${var.db_parameters.password} && gunzip -c /tmp/db.sql.gz | psql -h ${aws_rds_cluster.aurora_pg.endpoint} -U ${var.db_parameters.username} -d ${var.db_parameters.db_name} -p ${var.db_parameters.db_port}",
      "rm /tmp/db.sql.gz"
    ]
  }

  # Define how Terraform connects to the instance
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"                            # Default user for Ubuntu AMIs
    private_key = file(var.key_info.private_key_path) # Path to your private key
  }

  # Depends on the RDS instance
  depends_on = [aws_rds_cluster_instance.aurora_pg_instance]

  tags = {
    Name        = "Bastion Host"
    Environment = var.environment
  }
}

################################################################################
# SIC Resources
################################################################################
resource "aws_secretsmanager_secret" "aurora_pg_secret" {
  name = "aurora_pg_secret-${var.environment}-${random_id.unique.hex}"

  tags = {
    Name        = "Aurora PostgreSQL Secret"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "aurora_pg_secret_version" {
  secret_id     = aws_secretsmanager_secret.aurora_pg_secret.id
  secret_string = jsonencode(var.db_parameters)
}

################################################################################
# Extra Resources
################################################################################
resource "random_id" "unique" {
  byte_length = 4
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_info.name
  public_key = file(var.key_info.public_key_path)
}
