output "cloudfront_domain_name" {
  description = "URL publique HTTPS du site (via CloudFront)"
  value       = aws_cloudfront_distribution.drupal.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.drupal.id
}
