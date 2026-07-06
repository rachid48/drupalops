# Module: secrets

Creates and manages an AWS Secrets Manager secret containing RDS credentials (username, password, host, port, dbname) as JSON.

## Why this module

Avoids storing credentials in plain text in the Terraform state or as environment variables on instances. EC2 instances fetch credentials at runtime via the IAM instance profile (see `iam` module), with no static access keys.

## Resources created

- `aws_secretsmanager_secret`: secret container (metadata, name, description)
- `aws_secretsmanager_secret_version`: the actual secret value (separated to allow rotation without recreating the secret)

## Inputs

| Name | Type | Description |
|---|---|---|
| project_name | string | Project name, used to name the secret |
| db_username | string | RDS username |
| db_password | string (sensitive) | RDS password |
| db_host | string | RDS endpoint |
| db_port | string | RDS port (default: 3306) |
| db_name | string | Database name |

## Outputs

| Name | Description |
|---|---|
| secret_arn | Secret ARN, used by the `iam` module to scope the IAM policy |

## Example usage

\`\`\`hcl
module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
  db_username  = var.db_username
  db_password  = var.db_password
  db_host      = module.rds.db_endpoint
  db_name      = var.db_name
}
\`\`\`