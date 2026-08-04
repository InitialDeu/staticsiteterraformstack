# DNS: record ALIAS verso CloudFront
#resource "aws_route53_record" "apex" {
#  zone_id = var.hosted_zone_id
#  name    = local.apex
#  type    = "A"
#
#  alias {
#    name                   = aws_cloudfront_distribution.cdn.domain_name
#    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
#    evaluate_target_health = false
#  }
#}
#
#resource "aws_route53_record" "www" {
#  count   = var.create_www ? 1 : 0
#  zone_id = var.hosted_zone_id
#  name    = local.www
#  type    = "A"
#
#  alias {
#    name                   = aws_cloudfront_distribution.cdn.domain_name
#    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
#    evaluate_target_health = false
#  }
#}
