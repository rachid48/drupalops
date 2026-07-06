# Module: cloudfront

This module provisions a CloudFront distribution that sits in front of the ALB to provide HTTPS, caching, and a global edge network.

## Why this module

CloudFront shields the ALB from direct public exposure, adds HTTPS termination with the default certificate, and selectively caches static Drupal assets. This reduces latency for static content while preserving dynamic request behavior for the Drupal application.

## Resources created

- `aws_cloudfront_distribution.drupal` — creates the CloudFront distribution with the ALB as the origin, pass-through behavior for dynamic requests, and optimized caching for `/sites/*/files/*`.

## Inputs

Name | Type | Description
--- | --- | ---
alb_dns_name | string | DNS name of the ALB used as the origin for CloudFront

## Outputs

Name | Description
--- | ---
cloudfront_domain_name | Public CloudFront domain name for the site
cloudfront_distribution_id | CloudFront distribution ID

## Example usage

```hcl
module "cloudfront" {
  source       = "./modules/cloudfront"
  alb_dns_name = module.alb.alb_dns_name
}
```

## Dependencies

This module depends on `module.alb` for the ALB DNS name origin. It is not referenced by any other module in the current root configuration.
