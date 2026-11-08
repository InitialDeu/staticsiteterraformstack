# ACM certificate (us-east-1, required by CloudFront) covering apex + www
resource "aws_acm_certificate" "cert" {
  provider                  = aws.use1
  domain_name               = local.apex
  subject_alternative_names = [local.www]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS records ACM needs to validate AND to keep auto-renewing the certificate.
# They must exist for as long as the certificate is in use.
locals {
  acm_validation_records = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = trimsuffix(dvo.resource_record_name, ".")
      type  = dvo.resource_record_type
      value = trimsuffix(dvo.resource_record_value, ".")
    }
  }
}

# With a managed DNS provider the records are created in tf-04-dns.tf and this
# resource waits for them. Without one, create the records by hand (see the
# `acm_validation_records` output) before the apply can finish.
resource "aws_acm_certificate_validation" "cert" {
  provider        = aws.use1
  certificate_arn = aws_acm_certificate.cert.arn

  depends_on = [
    cloudflare_dns_record.acm_validation,
    aws_route53_record.acm_validation,
  ]
}
