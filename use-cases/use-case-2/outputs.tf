output "network" {
  description = "The network configuration information."
  value = {
    vpc_id                = aws_vpc.main.id
    subnet_public_id      = aws_subnet.public.id
    subnet_private_az1_id = aws_subnet.private_a.id
    subnet_private_az2_id = aws_subnet.private_b.id
    internet_gateway_id   = aws_internet_gateway.igw.id
    route_table_public_id = aws_route_table.public_rt.id
    security_group_ec2_id = aws_security_group.allow_ssh.id
    security_group_rds_id = aws_security_group.rds_sg.id
  }
}

output "instance_info" {
  description = "The instance information."
  value = {
    instance_id   = aws_instance.server_one.id
    instance_type = aws_instance.server_one.instance_type
    public_ip     = aws_instance.server_one.public_ip
  }
}

output "rds_info" {
  description = "The RDS database information."
  value = {
    db_instance_id      = aws_db_instance.my_mysql.id
    db_instance_address = aws_db_instance.my_mysql.address
  }
}
