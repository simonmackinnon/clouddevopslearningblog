# ImprovMX — free email forwarding to var.improvmx_forward_to
# After applying, log in to improvmx.com and add an alias:
#   me@ → var.improvmx_forward_to

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.domain
  type    = "MX"
  ttl     = 300

  records = [
    "10 mx1.improvmx.com.",
    "20 mx2.improvmx.com.",
  ]
}

resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = local.domain
  type    = "TXT"
  ttl     = 300

  records = ["v=spf1 include:spf.improvmx.com ~all"]
}
