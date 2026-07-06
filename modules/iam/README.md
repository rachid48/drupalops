# Module: iam

Creates an IAM role and instance profile allowing the ASG's EC2 instances to access the RDS secret (Secrets Manager) with no static access keys.

## Why this module

Least privilege principle: the role only allows `secretsmanager:GetSecretValue` on the exact secret ARN (not `*`). The instance profile is the only way to attach an IAM role to an EC2 instance (a policy can never be attached directly to an instance).

## Resources created

- `aws_iam_role`: role assumable only by the EC2 service (trust policy)
- `aws_iam_role_policy`: inline policy allowing `GetSecretValue` on the target secret
- `aws_iam_instance_profile`: wrapper attached to the launch template (`compute` module)

## Inputs

| Name | Type | Description |
|---|---|---|
| project_name | string | Project name, used to name the role and instance profile |
| secret_arn | string | Secrets Manager ARN (provided by the `secrets` module) |

## Outputs

| Name | Description |
|---|---|
| instance_profile_name | Instance profile name, passed to the `compute` module |

## Example usage

\`\`\`hcl
module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  secret_arn   = module.secrets.secret_arn
}
\`\`\`

## Dependencies

Depends on the `secrets` module (needs `secret_arn`). Used by the `compute` module (provides `instance_profile_name`).