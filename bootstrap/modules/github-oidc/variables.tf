# ==========================================================================
# GitHub OIDC Module — Variables
# Reusable across any project needing GitHub Actions → AWS authentication
# without long-lived credentials (no AWS_ACCESS_KEY_ID / SECRET stored).
# ==========================================================================

variable "project_name" {
  description = "Project name, used to name/tag the IAM role and policy (e.g. 'drupalops', 'drupalscale-eks')"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or personal username that owns the repo (e.g. 'rachid-dev')"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name only, without the org prefix (e.g. 'drupalops')"
  type        = string
}

variable "allowed_branches" {
  description = "List of branches allowed to assume this role via push (usually just main). Add more if you use a staging branch."
  type        = list(string)
  default     = ["main"]
}

variable "allow_pull_requests" {
  description = "Whether PRs from any branch can assume the role (needed for the terraform-plan.yml workflow to run on PRs). Set to false for a stricter, apply-only role."
  type        = bool
  default     = true
}

variable "state_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform remote state (created in step 7)"
  type        = string
}

variable "lock_table_arn" {
  description = "ARN of the DynamoDB table used for Terraform state locking (created in step 7)"
  type        = string
}