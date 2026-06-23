resource "aws_route53_zone" "main" {
  name = local.domain
}

# Root domain → CloudFront
resource "aws_route53_record" "root_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.blog.domain_name
    zone_id                = aws_cloudfront_distribution.blog.hosted_zone_id
    evaluate_target_health = false
  }
}

# www → root (alias within the same zone)
resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${local.domain}"
  type    = "A"

  alias {
    name                   = local.domain
    zone_id                = aws_route53_zone.main.zone_id
    evaluate_target_health = false
  }
}
