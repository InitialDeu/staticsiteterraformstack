
# Certificato ACM (us-east-1) con SAN per www
resource "aws_acm_certificate" "cert" {
  provider          = aws.use1
  domain_name       = local.apex
  validation_method = "DNS"

  subject_alternative_names = ["www.marcocavalieri.it"]

  lifecycle {
    create_before_destroy = true
  }
}

# Record DNS per validazione (Route53)
#resource "aws_route53_record" "cert_validation" {
#  for_each = {
#    for dvo in aws_acm_certificate.cert.domain_validation_options :
#    dvo.domain_name => {
#      name  = dvo.resource_record_name
#      type  = dvo.resource_record_type
#      value = dvo.resource_record_value
#    }
#  }
#
#  zone_id = var.hosted_zone_id
#  name    = each.value.name
#  type    = each.value.type
#  ttl     = 60
#  records = [each.value.value]
#}
#
resource "aws_acm_certificate_validation" "cert" {
  provider        = aws.use1
  certificate_arn = aws_acm_certificate.cert.arn
}