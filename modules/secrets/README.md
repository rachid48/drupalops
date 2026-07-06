# Module: secrets

This module provisions an AWS Secrets Manager secret containing Drupal database credentials and the hash salt.

## Why this module

It stores database credentials and the Drupal `hash_salt` securely in Secrets Manager rather than hardcoding them in user data or Terraform outputs. This enables EC2 instances to retrieve secrets at runtime with a scoped IAM policy and reduces credential exposure.

## Resources created

- `aws_secretsmanager_secret.db_credentials` — secret metadata object in AWS Secrets Manager.
- `aws_secretsmanager_secret_version.db_credentials` — stores the JSON secret string version with database connection details and hash salt.

## Inputs

Name | Type | Description
--- | --- | ---
project_name | string | Project name used to name the secret
db_username | string | Database username
db_password | string | Database password
db_host | string | Database hostname
db_port | string | Database port
db_name | string | Database name
hash_salt | string | Random hash salt used by Drupal

## Outputs

Name | Description
--- | ---
secret_arn | ARN of the Secrets Manager secret

## Example usage

```hcl
module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
  db_username  = var.db_username
  db_password  = var.db_password
  db_host      = module.rds.rds_endpoint
  db_port      = module.rds.rds_port
  db_name      = var.db_name
  hash_salt    = random_id.hash_salt.hex
}
```

## Dependencies

This module depends on `module.rds` for the database endpoint and port. It is consumed by `module.iam` for secret ARN access control.
