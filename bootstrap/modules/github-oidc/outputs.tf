# ==========================================================================
# GitHub OIDC Module — Outputs
# ==========================================================================

output "role_arn" {
  description = "ARN of the IAM role GitHub Actions will assume. Copy this into GitHub Secrets as AWS_ROLE_ARN."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider (rarely needed directly, but useful if you add more roles later)"
  value       = aws_iam_openid_connect_provider.github.arn
}