# Terraform Drupal Infrastructure

Terraform infrastructure to deploy a Drupal application on AWS using a compute module and an RDS module.

## Structure

- `main.tf`: module calls and `aws_security_group.web` resource
- `network.tf`: VPC, public/private subnets, Internet Gateway, route table, DB subnet group
- `providers.tf`: Terraform and AWS provider version configuration
- `variables.tf`: global project variables
- `outputs.tf`: global outputs
- `drupal-app-user-data-serv.sh`: separate `user_data` script for the web instance
- `modules/compute/`: module for the web EC2 instance
- `modules/rds/`: module for the RDS database

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with valid credentials
- AWS account in the `eu-west-3` region

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Preview the plan:
   ```bash
   terraform plan
   ```

3. Apply the changes:
   ```bash
   terraform apply
   ```

## Modules

- `modules/compute`: manages the web EC2 instance and receives `user_data` from the root module
- `modules/rds`: manages the RDS instance and its security group

## Notes

- The Drupal setup script is stored in `drupal-app-user-data-serv.sh`
- Default variables are defined in `variables.tf`
- Provider and Terraform versions are pinned in `providers.tf`

## Suggested commit message

```
refactor(terraform): add compute and rds modules, reorganize root structure and add README
```
