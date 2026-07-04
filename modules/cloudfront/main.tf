# CloudFront = AWS's CDN (Content Delivery Network).
# It sits in front of the ALB and acts as the public "front door" of the site:
# - it provides free HTTPS (via the *.cloudfront.net default certificate)
# - it can cache static files to speed things up
# - it hides the ALB behind a global AWS URL (edge locations)

resource "aws_cloudfront_distribution" "drupal" {
  enabled     = true
  comment     = "CloudFront - DrupalOps (no custom domain)"

  # PriceClass_100 = only Europe + US edge locations (cheapest option).
  # Other options: PriceClass_200 (+ Asia) and PriceClass_All (worldwide, most expensive).
  price_class = "PriceClass_100"

  # "origin" = where CloudFront fetches the actual content from.
  # Here, the origin is our Application Load Balancer (ALB).
  origin {
    domain_name = var.alb_dns_name   # the ALB's DNS name, e.g. my-alb-123.eu-west-3.elb.amazonaws.com
    origin_id   = "alb-origin"       # internal identifier, reused below

    # How CloudFront talks to the ALB internally ("backend" connection)
    custom_origin_config {
      http_port               = 80
      https_port              = 443
      origin_protocol_policy  = "http-only"  # our ALB has no TLS cert -> talk plain HTTP internally
      origin_ssl_protocols    = ["TLSv1.2"]  # only relevant if origin_protocol_policy switches to https later
    }
  }

  # "default_cache_behavior" = the default rule for ALL requests
  # that don't match a more specific behavior defined below.
  # For Drupal (dynamic pages, sessions, forms), we want "pass-through":
  # nothing is cached, every request actually reaches the ALB.
  default_cache_behavior {
    allowed_methods         = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "alb-origin"
    viewer_protocol_policy   = "redirect-to-https"  # if someone visits http://, redirect them to https://

    # What CloudFront should forward to the origin (the ALB)
    forwarded_values {
      query_string = true  # forward ?param=value query strings (required for Drupal)
      headers      = ["Host", "Accept", "Accept-Language"]  # HTTP headers to forward

      # Cookies (PHP/Drupal session, login state) must be forwarded,
      # otherwise nobody could stay logged in on the site!
      cookies {
        forward = "all"
      }
    }

    # TTL = Time To Live = how long content stays cached. All set to 0 here
    # means no caching at all for "regular" pages, since Drupal generates
    # dynamic/personalized content.
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # "ordered_cache_behavior" = a SPECIFIC rule that takes priority over
  # the "default" one for URLs matching path_pattern.
  # Here: all static files uploaded through Drupal (images, PDFs, etc.)
  # located under /sites/*/files/*. These files never change once created,
  # so it's safe to cache them.
ordered_cache_behavior {
  path_pattern            = "/sites/*/files/*"
  allowed_methods         = ["GET", "HEAD"]
  cached_methods           = ["GET", "HEAD"]
  target_origin_id        = "alb-origin"
  viewer_protocol_policy  = "redirect-to-https"

  forwarded_values {
    query_string = true
    cookies {
      forward = "none"
    }
  }

  min_ttl     = 0
  default_ttl = 86400
  max_ttl     = 604800
  compress    = true
}

  # Geographic restriction: "none" = accessible from any country
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # HTTPS certificate used by visitors. "cloudfront_default_certificate = true"
  # means we use AWS's free default certificate for the *.cloudfront.net URL.
  # (If we had a real custom domain, we'd use ACM here instead.)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name    = "drupalops-cloudfront"
    Project = "DrupalOps"
  }
}
