# ---------------------------------------------------------------------------
# Google Search Console automation (optional, off by default).
# Enabled with `enable_google_search = true` plus a DNS provider zone ID.
#
#  1. asks Google for the domain verification token
#  2. publishes it as a TXT record on the apex (Cloudflare or Route53)
#  3. verifies the domain with the Site Verification API
#  4. adds the property to Search Console and submits sitemap.xml
#
# Credentials (never in code or tfvars):
#   gcloud auth application-default login --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/siteverification,https://www.googleapis.com/auth/webmasters"
#   gcloud auth application-default set-quota-project <google_project>
# The project needs siteverification.googleapis.com and searchconsole.googleapis.com
# enabled (free). Sitemap submission also needs Node.js >= 18.
# ---------------------------------------------------------------------------

provider "google" {
  project               = var.google_project
  user_project_override = true
  billing_project       = var.google_project
  # Disabled: dummy token so the provider does not look for ADC credentials.
  # Enabled: null -> uses Application Default Credentials.
  access_token = local.google_on ? null : "disabled"
  scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/siteverification",
    "https://www.googleapis.com/auth/webmasters",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

data "google_site_verification_token" "domain" {
  count               = local.google_on ? 1 : 0
  type                = "INET_DOMAIN"
  identifier          = var.domain_name
  verification_method = "DNS_TXT"
}

resource "cloudflare_dns_record" "google_verification" {
  count   = local.google_on && local.cloudflare_on ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = local.apex
  type    = "TXT"
  ttl     = 300
  content = data.google_site_verification_token.domain[0].token
}

resource "aws_route53_record" "google_verification" {
  count   = local.google_on && local.route53_on ? 1 : 0
  zone_id = var.route53_zone_id
  name    = local.apex
  type    = "TXT"
  ttl     = 300
  records = [data.google_site_verification_token.domain[0].token]
}

resource "google_site_verification_web_resource" "domain" {
  count               = local.google_on ? 1 : 0
  verification_method = "DNS_TXT"

  site {
    type       = "INET_DOMAIN"
    identifier = var.domain_name
  }

  depends_on = [
    cloudflare_dns_record.google_verification,
    aws_route53_record.google_verification,
  ]
}

data "google_client_config" "default" {
  count = local.google_on ? 1 : 0
}

resource "terraform_data" "submit_sitemap" {
  count = local.google_on ? 1 : 0

  triggers_replace = [
    aws_s3_object.sitemap.etag,
    google_site_verification_web_resource.domain[0].id,
  ]

  provisioner "local-exec" {
    working_dir = path.module
    command     = "node scripts/gsc-submit.mjs"
    environment = {
      GOOGLE_TOKEN   = data.google_client_config.default[0].access_token
      GOOGLE_PROJECT = var.google_project
      DOMAIN         = var.domain_name
      SITEMAP_URL    = "${local.canonical_url}sitemap.xml"
    }
  }

  depends_on = [terraform_data.invalidate_cdn]
}
