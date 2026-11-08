output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

# Manual DNS setup (only needed when no DNS provider is managed by Terraform):
#  - the ACM validation CNAMEs below (keep them forever, ACM renewal needs them)
#  - www  -> CNAME to cloudfront_domain
#  - apex -> ALIAS/ANAME/flattened CNAME to cloudfront_domain
output "acm_validation_records" {
  description = "CNAME records ACM needs for validation and automatic renewal"
  value       = local.acm_validation_records
}
