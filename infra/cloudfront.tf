# Legacy custom-origin distribution pointing at the S3 website endpoint (not OAC).
# The origin uses HTTP-only because S3 website hosting doesn't support HTTPS.
resource "aws_cloudfront_distribution" "blog" {
  enabled         = true
  is_ipv6_enabled = true
  http_version    = "http2"
  aliases         = [local.domain, "www.${local.domain}"]
  price_class     = "PriceClass_All"

  origin {
    domain_name = "${local.domain}.s3-website-${var.aws_region}.amazonaws.com"
    origin_id   = "S3-${local.domain}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.domain}"
    viewer_protocol_policy = "allow-all"
    compress               = false

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.blog.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  tags = { Project = local.project }
}
