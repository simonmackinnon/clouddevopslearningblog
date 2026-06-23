output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — used in CI/CD invalidation"
  value       = aws_cloudfront_distribution.blog.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.blog.domain_name
}

output "s3_bucket" {
  value = aws_s3_bucket.blog.bucket
}

output "nameservers" {
  description = "Route53 nameservers — must match what the registrar has"
  value       = aws_route53_zone.main.name_servers
}
