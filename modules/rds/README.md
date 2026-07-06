# Module: rds

This module provisions a MySQL RDS instance and a security group restricting access to the Drupal web servers.

## Why this module

The RDS instance provides durable managed database storage for Drupal content and configuration. It isolates database access to the web security group, reducing blast radius and enforcing least-privilege network access.

## Resources created

- `aws_db_instance.default` — creates the MySQL database instance with private accessibility and configured storage.
- `aws_security_group.rds` — allows MySQL traffic only from the web EC2 security group.

## Inputs

Name | Type | Description
--- | --- | ---
db_instance_class | string | The type of RDS instance to use
db_name | string | The name of the database
db_username | string | The username for the database
db_password | string | The password for the database
db_subnet_group_name | string | The DB subnet group name
vpc_id | string | The VPC ID where RDS will be deployed
web_sg_id | string | The security group ID of the web server allowed to reach RDS
sg_name | string | The security group name for RDS

## Outputs

Name | Description
--- | ---
rds_endpoint | RDS hostname (without port)
rds_port | RDS port for Drupal connection
rds_security_group_id | RDS security group ID

## Example usage

```hcl
module "rds" {
  source               = "./modules/rds"
  db_instance_class    = var.db_instance_class
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_id               = aws_vpc.main.id
  web_sg_id            = aws_security_group.web.id
}
```

## Dependencies

This module is consumed by `module.secrets` for database connection details. It does not depend on any other `modules/` module directly.
