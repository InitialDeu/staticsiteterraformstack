# ---------------------------------------------------------------------------
# DNS records. Choose ONE provider by setting its zone ID (see variables.tf):
#   cloudflare_zone_id -> Cloudflare (www CNAME to CloudFront, proxied apex that
#                         301-redirects to www, ACM validation records)
#   route53_zone_id    -> Route53 (alias records for www and apex, ACM validation)
#   neither            -> no records are created, create them by hand
#                         (see the outputs)
# ---------------------------------------------------------------------------

# --- Cloudflare ------------------------------------------------------------
# The token is read from the CLOUDFLARE_API_TOKEN environment variable.
# Permissions: Zone > DNS > Edit and Zone > Dynamic URL Redirects > Edit.
provider "cloudflare" {}

resource "cloudflare_dns_record" "acm_validation" {
  for_each = local.cloudflare_on ? local.acm_validation_records : {}

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.value
  ttl     = 1
  proxied = false # must stay DNS-only for ACM to validate and renew
}

# www -> CloudFront. Must NOT be proxied (the TLS certificate lives on CloudFront)
resource "cloudflare_dns_record" "www" {
  count = local.cloudflare_on ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = local.www
  type    = "CNAME"
  content = aws_cloudfront_distribution.cdn.domain_name
  ttl     = 1
  proxied = false
}

# Apex: proxied so Cloudflare can answer with the redirect to www at its edge.
# The origin IP is never contacted.
resource "cloudflare_dns_record" "apex" {
  count = local.cloudflare_on ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = local.apex
  type    = "A"
  content = var.apex_placeholder_ip
  ttl     = 1
  proxied = true
}

# Redirect apex -> www (301), keeping path and query string. Note: Cloudflare
# allows a single ruleset per zone in this phase.
resource "cloudflare_ruleset" "apex_to_www" {
  count = local.cloudflare_on ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "apex-to-www"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [{
    action      = "redirect"
    description = "Redirect ${local.apex} -> ${local.www}"
    enabled     = true
    expression  = "(http.host eq \"${local.apex}\")"
    action_parameters = {
      from_value = {
        status_code           = 301
        preserve_query_string = true
        target_url = {
          expression = "concat(\"https://${local.www}\", http.request.uri.path)"
        }
      }
    }
  }]
}

# --- Route53 ---------------------------------------------------------------
resource "aws_route53_record" "acm_validation" {
  for_each = local.route53_on ? local.acm_validation_records : {}

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.value]
  allow_overwrite = true
}

# Alias records for www and apex (A + AAAA, the distribution has IPv6 enabled)
resource "aws_route53_record" "site" {
  for_each = local.route53_on ? {
    "www-A"     = { name = local.www, type = "A" }
    "www-AAAA"  = { name = local.www, type = "AAAA" }
    "apex-A"    = { name = local.apex, type = "A" }
    "apex-AAAA" = { name = local.apex, type = "AAAA" }
  } : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
