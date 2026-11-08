provider "aws" {
  region = var.region
}

# ACM certificates used by CloudFront MUST live in us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

locals {
  apex        = var.domain_name
  www         = "www.${var.domain_name}"
  bucket_name = "${var.project}-${replace(var.domain_name, ".", "-")}-site"

  # Canonical host/URL used for SEO (canonical tag, sitemap, redirects)
  canonical_host = local.www
  canonical_url  = "https://${local.canonical_host}/"

  # Which DNS provider (if any) Terraform manages records on
  cloudflare_on = var.cloudflare_zone_id != null
  route53_on    = var.route53_zone_id != null
  dns_managed   = local.cloudflare_on || local.route53_on

  # Google Search Console automation needs a DNS provider for the TXT record
  google_on = var.enable_google_search && local.dns_managed
}
