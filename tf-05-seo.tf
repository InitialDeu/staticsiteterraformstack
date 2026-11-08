# ---------------------------------------------------------------------------
# SEO: robots.txt and sitemap.xml, served from S3 through CloudFront.
# The canonical host is www (see local.canonical_url in main.tf); the Google
# Search Console part lives in tf-07-google-search.tf.
# ---------------------------------------------------------------------------

resource "aws_s3_object" "robots" {
  bucket       = aws_s3_bucket.site.id
  key          = "robots.txt"
  content_type = "text/plain; charset=utf-8"

  content = <<-EOT
    User-agent: *
    Allow: /

    Sitemap: ${local.canonical_url}sitemap.xml
  EOT
}

resource "aws_s3_object" "sitemap" {
  bucket       = aws_s3_bucket.site.id
  key          = "sitemap.xml"
  content_type = "application/xml; charset=utf-8"

  content = <<-EOT
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
        <loc>${local.canonical_url}</loc>
      </url>
    </urlset>
  EOT
}
