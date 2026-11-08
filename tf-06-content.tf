# ---------------------------------------------------------------------------
# Deploys the static site (Content/ folder) to S3 and invalidates the CDN.
# Every file changed in Content/ is re-uploaded on the next `terraform apply`.
# Objects present in the bucket but not in Content/ are left untouched.
# ---------------------------------------------------------------------------

locals {
  content_dir   = "${path.module}/Content"
  content_files = fileset(local.content_dir, "**")

  mime_types = {
    html        = "text/html; charset=utf-8"
    css         = "text/css; charset=utf-8"
    js          = "application/javascript; charset=utf-8"
    json        = "application/json"
    webmanifest = "application/manifest+json"
    svg         = "image/svg+xml"
    png         = "image/png"
    jpg         = "image/jpeg"
    jpeg        = "image/jpeg"
    webp        = "image/webp"
    ico         = "image/x-icon"
    pdf         = "application/pdf"
    txt         = "text/plain; charset=utf-8"
    xml         = "application/xml; charset=utf-8"
  }
}

resource "aws_s3_object" "content" {
  for_each = local.content_files

  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${local.content_dir}/${each.value}"
  etag         = filemd5("${local.content_dir}/${each.value}")
  content_type = lookup(local.mime_types, lower(element(reverse(split(".", each.value)), 0)), "application/octet-stream")
}

# Clears the CloudFront cache whenever something published changes.
# Requires the AWS CLI and Node.js on the machine running Terraform
# (the script is cross-platform, no bash needed).
resource "terraform_data" "invalidate_cdn" {
  triggers_replace = [
    sha1(join(",", [for k, o in aws_s3_object.content : o.etag])),
    aws_s3_object.robots.etag,
    aws_s3_object.sitemap.etag,
    jsonencode(aws_cloudfront_distribution.cdn.custom_error_response),
  ]

  provisioner "local-exec" {
    working_dir = path.module
    command     = "node scripts/cloudfront-invalidate.mjs ${aws_cloudfront_distribution.cdn.id}"
  }
}
