# ==========================================================================
# GitHub OIDC Module — Main
#
# What this creates:
#   1. An OIDC identity provider trusting GitHub's token issuer
#   2. An IAM role that GitHub Actions can assume via a short-lived token
#      (no static AWS keys stored anywhere in GitHub secrets)
#   3. A least-privilege policy scoped to Terraform state access + infra mgmt
#
# How it's used:
#   In your GitHub Actions workflow, aws-actions/configure-aws-credentials
#   requests a token from GitHub, presents it to AWS, and AWS hands back
#   temporary credentials valid only for that job run.
# ==========================================================================

# Fetches GitHub's current TLS certificate thumbprint — required by AWS
# to validate the OIDC provider. GitHub rotates this rarely.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # sts.amazonaws.com = fixed value required by AWS for GitHub OIDC
  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name    = "github-actions-oidc"
    Project = var.project_name
  }
}

# --------------------------------------------------------------------------
# Trust policy (who is allowed to assume this role)
# --------------------------------------------------------------------------
# GitHub embeds a "sub" claim in its token like:
#   repo:ORG/REPO:ref:refs/heads/main        <- a push to main
#   repo:ORG/REPO:pull_request                <- any PR against the repo
# We restrict the role to ONLY this specific repo, on ONLY these refs.
# Without this, ANY GitHub repo could try to assume the role.
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # Ensures the token was issued for AWS STS specifically
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Ensures the token comes from THIS repo, on an allowed branch or PR
condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = concat(
        [for branch in var.allowed_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"],
        var.allow_pull_requests ? ["repo:${var.github_org}/${var.github_repo}:pull_request"] : [],
        ["repo:${var.github_org}/${var.github_repo}:environment:production"]
      )
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    Project = var.project_name
  }
}

# --------------------------------------------------------------------------
# Permissions policy (what the role can actually DO once assumed)
# --------------------------------------------------------------------------
# Kept scoped on purpose — NOT AdministratorAccess.
# Split in 3 blocks: state access, lock access, infra management.
# Extend the "InfraManagement" statement if a future project needs
# more services (e.g. eks:*, route53:*, cloudfront:*).
resource "aws_iam_role_policy" "terraform_permissions" {
  name = "${var.project_name}-terraform-permissions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read/write access to the Terraform state file in S3
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.state_bucket_arn,
          "${var.state_bucket_arn}/*"
        ]
      },
      {
        # DynamoDB state locking (prevents concurrent applies)
        Sid    = "TerraformLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = var.lock_table_arn
      },
{
  # Actual infra permissions — adjust per project.
  # DrupalOps needs: EC2, RDS, EFS, ALB, CloudFront, CloudWatch, Secrets Manager.
  Sid    = "InfraManagement"
  Effect = "Allow"
  Action = [
    "autoscaling:*",
    "ec2:*",
    "rds:*",
    "elasticfilesystem:*",
    "elasticloadbalancing:*",
    "cloudfront:*",
    "cloudwatch:*",
    "logs:*",
    "secretsmanager:*",
    "iam:GetRole",
    "iam:PassRole",
    "iam:CreateRole",
    "iam:DeleteRole",
    "iam:PutRolePolicy",
    "iam:DeleteRolePolicy",
    "iam:AttachRolePolicy",
    "iam:DetachRolePolicy",
    "iam:CreateServiceLinkedRole"
  ]
  Resource = "*"
}
    ]
  })
}