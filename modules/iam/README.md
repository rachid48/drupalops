# Module: iam

This module provisions an IAM role, inline policy, and instance profile for EC2 instances to retrieve the Drupal database secret from Secrets Manager.

## Why this module

It enforces least privilege by granting EC2 instances only `secretsmanager:GetSecretValue` on the specific secret ARN. The instance profile attaches the role to compute instances without static credentials.

## Resources created

- `aws_iam_role.ec2_role` — IAM role assumable by EC2 via a trust policy.
- `aws_iam_role_policy.secrets_access` — inline policy allowing Secrets Manager access to the secret ARN.
- `aws_iam_instance_profile.ec2_profile` — instance profile attached to the EC2 launch template.

## Inputs

Name | Type | Description
--- | --- | ---
project_name | string | Project name used to name the role, policy, and instance profile
secret_arn | string | ARN of the Secrets Manager secret to which EC2 instances need access

## Outputs

Name | Description
--- | ---
instance_profile_name | Name of the IAM instance profile for EC2 instances

## Example usage

```hcl
module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  secret_arn   = module.secrets.secret_arn
}
```

## Dependencies

This module depends on `module.secrets` for the secret ARN. It is consumed by `module.compute` for the EC2 instance profile name.
