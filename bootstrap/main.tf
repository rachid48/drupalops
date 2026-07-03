terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # Local state for this bootstrap only — chicken-and-egg problem
}

provider "aws" {
  region = "eu-west-3"
}

# S3 bucket to store Terraform remote state
resource "aws_s3_bucket" "tfstate" {
  bucket = "drupalops-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "drupalops-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.tfstate.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tfstate_lock.name
}

# ==========================================================================
# GitHub OIDC — step 8, CI/CD authentication
# Reuses the S3/DynamoDB resources created above directly (no need to
# pass their ARNs as variables since they live in the same state).
# ==========================================================================

module "github_oidc" {
  source = "./modules/github-oidc"

  project_name     = "drupalops"
  github_org       = var.github_org
  github_repo      = var.github_repo
  state_bucket_arn = aws_s3_bucket.tfstate.arn
  lock_table_arn   = aws_dynamodb_table.tfstate_lock.arn
}

output "github_actions_role_arn" {
  description = "ARN to put in GitHub Secrets as AWS_ROLE_ARN"
  value       = module.github_oidc.role_arn
}