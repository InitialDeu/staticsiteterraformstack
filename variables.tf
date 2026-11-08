variable "project" {
  type        = string
  description = "Project name, used as a prefix for resource names"
}

variable "region" {
  type        = string
  description = "AWS region for the S3 bucket"
  default     = "eu-south-1"
}

variable "domain_name" {
  type        = string
  description = "Apex domain of the site, e.g. example.com (the site is served on www.<domain>)"
}

# ---------------------------------------------------------------------------
# DNS (optional). Set AT MOST ONE of the two zone IDs. With neither, Terraform
# creates no DNS records and prints the ones you must create by hand (outputs).
# ---------------------------------------------------------------------------
variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID. Enables Cloudflare DNS records, apex->www redirect. Needs CLOUDFLARE_API_TOKEN."
  default     = null
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID. Enables Route53 DNS records."
  default     = null

  validation {
    condition     = var.route53_zone_id == null || var.cloudflare_zone_id == null
    error_message = "Set only one of cloudflare_zone_id / route53_zone_id."
  }
}

variable "apex_placeholder_ip" {
  type        = string
  description = "Cloudflare only: IP of the proxied apex A record. It is never contacted, the redirect to www happens at the Cloudflare edge. 192.0.2.1 is a documentation address."
  default     = "192.0.2.1"
}

# ---------------------------------------------------------------------------
# Google Search Console (optional, needs a DNS provider above)
# ---------------------------------------------------------------------------
variable "enable_google_search" {
  type        = bool
  description = "Verify the domain in Google Search Console and submit the sitemap"
  default     = false
}

variable "google_project" {
  type        = string
  description = "GCP project with the Site Verification and Search Console APIs enabled"
  default     = null
}
