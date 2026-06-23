# Terraform 1.5+ import blocks — bring existing manually-created resources into state.
# These are safe to leave in place; once a resource is in state the import is a no-op.

# ── Route53 ───────────────────────────────────────────────────────────────────
import {
  to = aws_route53_zone.main
  id = "Z01466352O0VU9TPMM30I"
}

# ── S3 ────────────────────────────────────────────────────────────────────────
import {
  to = aws_s3_bucket.blog
  id = "theclouddevopslearningblog.com"
}

import {
  to = aws_s3_bucket_website_configuration.blog
  id = "theclouddevopslearningblog.com"
}

import {
  to = aws_s3_bucket_versioning.blog
  id = "theclouddevopslearningblog.com"
}

import {
  to = aws_s3_bucket_policy.blog
  id = "theclouddevopslearningblog.com"
}

# ── ACM certificate ───────────────────────────────────────────────────────────
import {
  to = aws_acm_certificate.blog
  id = "arn:aws:acm:us-east-1:210779650910:certificate/0ca1f4c7-d01b-48b9-b503-6bcec927b894"
}


# ── CloudFront ────────────────────────────────────────────────────────────────
import {
  to = aws_cloudfront_distribution.blog
  id = "E5CSONWGEIVIX"
}

# ── DNS records ───────────────────────────────────────────────────────────────
import {
  to = aws_route53_record.root_a
  id = "Z01466352O0VU9TPMM30I_theclouddevopslearningblog.com_A"
}

import {
  to = aws_route53_record.www_a
  id = "Z01466352O0VU9TPMM30I_www.theclouddevopslearningblog.com_A"
}

# ACM validation CNAMEs — keys match domain_validation_options[*].domain_name
import {
  to = aws_route53_record.cert_validation["theclouddevopslearningblog.com"]
  id = "Z01466352O0VU9TPMM30I__b889842ff3bef295431abdea7adc0bca.theclouddevopslearningblog.com_CNAME"
}

import {
  to = aws_route53_record.cert_validation["www.theclouddevopslearningblog.com"]
  id = "Z01466352O0VU9TPMM30I__ba4143dd7217064998fdd83b47cd779f.www.theclouddevopslearningblog.com_CNAME"
}
