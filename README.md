# Static Site Terraform Stack

A small, cheap and secure stack for hosting a static website (a CV, a portfolio, a landing page) on AWS,
fully managed with Terraform:

- **S3** private bucket + **CloudFront** (HTTPS, HTTP/2, IPv6, Origin Access Control)
- **ACM** certificate for the apex and `www`, with auto-renewing DNS validation
- **DNS automation** for **Cloudflare** or **Route53** (or create the records by hand)
- **SEO**: `robots.txt`, `sitemap.xml`, canonical host (`www`), real 404s, apex → `www` redirect
- **Google Search Console** automation: domain verification and sitemap submission (optional)
- **Content deploy**: everything in `Content/` is uploaded to S3 and the CDN cache is invalidated on `terraform apply`
- A sample **multi-language one-page site** with a build-free prerender step for SEO

Typical cost for a low-traffic site: well under 1 USD/month (CloudFront's always-free tier covers 1 TB and 10 M requests
per month; S3 and ACM cost cents or nothing).

## Layout

| File | What it does |
|---|---|
| `main.tf`, `providers.tf`, `variables.tf` | providers, shared locals, input variables |
| `tf-01-s3.tf` | private S3 bucket |
| `tf-02-acm.tf` | ACM certificate (us-east-1, required by CloudFront) |
| `tf-03-cdn.tf` | CloudFront distribution, OAC, bucket policy |
| `tf-04-dns.tf` | DNS records for Cloudflare or Route53 |
| `tf-05-seo.tf` | `robots.txt`, `sitemap.xml` |
| `tf-06-content.tf` | upload of `Content/` + CDN invalidation |
| `tf-07-google-search.tf` | Google Search Console verification and sitemap submission |
| `Content/` | the website (sample site, replace it with yours) |
| `scripts/prerender.mjs` | writes the default-language text into the HTML for crawlers |

## Quick start

Requirements: Terraform ≥ 1.9, AWS CLI with credentials, Node.js ≥ 18 (prerender, CDN invalidation and sitemap
submission scripts; they run the same on Windows, Linux and macOS).

```bash
cp terraform.tfvars.example terraform.tfvars   # set project and domain_name
# optional: cp backend.tf.example backend.tf   # remote state in S3
terraform init
terraform apply -var-file=terraform.tfvars
```

If you did not configure a DNS provider, `terraform apply` waits for the certificate validation. Read the records from
the `acm_validation_records` output (or the ACM console) and create them at your DNS host, then create:

- `www` → `CNAME` to the `cloudfront_domain` output
- apex → `ALIAS`/`ANAME`/flattened `CNAME` to the same value

> ⚠️ Never delete the ACM validation CNAMEs: ACM needs them to **renew** the certificate automatically. If they are
> missing, the certificate expires and the site loses HTTPS.

## DNS options

Set **at most one** of these variables.

### Cloudflare (`cloudflare_zone_id`)

Creates the ACM validation records, the `www` CNAME (DNS-only, the certificate lives on CloudFront), a **proxied apex
record** and a **301 redirect from the apex to `www`** that Cloudflare answers at its edge (the apex IP is never contacted,
so the default documentation address `192.0.2.1` is fine).

1. Dashboard → your domain → *Overview* → copy the **Zone ID**.
2. *My Profile → API Tokens → Create Token → Custom token* with `Zone › DNS › Edit` and
   `Zone › Dynamic URL Redirects › Edit`, limited to your zone.
3. `export CLOUDFLARE_API_TOKEN=...` (PowerShell: `$env:CLOUDFLARE_API_TOKEN = "..."`).
4. Set `cloudflare_zone_id` in `terraform.tfvars`.

Existing records with the same name cause a "record already exists" error: delete them, or bring them under Terraform
with an `import` block (id format: `<zone_id>/<record_id>`). Cloudflare allows a single redirect ruleset per zone.

### Route53 (`route53_zone_id`)

Creates the ACM validation records and alias records (A and AAAA) for `www` and the apex pointing to CloudFront.
There is no redirect: the canonical tag tells search engines to prefer `www`.

## SEO

- `robots.txt` and `sitemap.xml` are generated from `domain_name` (`tf-05-seo.tf`). Add more URLs to the sitemap there.
- Missing pages return a real **404** (instead of a 200 with the home page), so search engines do not index junk URLs.
- `Content/index.html` ships with canonical, Open Graph and JSON-LD (`schema.org/Person`) tags: replace the
  `example.com` placeholders with your domain (`https://www.<domain>/`).
- **Prerender**: crawlers index pages faster when the text is in the HTML instead of injected by JavaScript.
  Run `node scripts/prerender.mjs` after changing texts: it writes the default-language text into `index.html`
  (the language switch keeps working).

## Google Search Console (optional)

Verifies your domain through a DNS TXT record and submits the sitemap, all from Terraform.

```bash
gcloud auth login
gcloud projects create <project-id>          # accept the Google Cloud Terms of Service in the console first
gcloud services enable siteverification.googleapis.com searchconsole.googleapis.com --project <project-id>
gcloud auth application-default login --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/siteverification,https://www.googleapis.com/auth/webmasters"
gcloud auth application-default set-quota-project <project-id>
```

Then set `enable_google_search = true` and `google_project = "<project-id>"` and apply. The APIs are free and need no
billing account. If Google refuses the `webmasters` scope for the gcloud client, drop it: verification still works and you
can submit the sitemap manually in Search Console. Indexing itself takes days to a couple of weeks; use *URL Inspection →
Request indexing* in Search Console to speed it up.

## Editing the site

Everything visible is in `Content/`:

- **Text** lives in `Content/Language.js`, one object per language; elements in `index.html` are bound to it with
  `data-i18n="section.key"`. Edit the values, never the HTML text of elements that have `data-i18n`.
- **Add a language**: copy the `en` block under a new key (e.g. `fr`) and translate it. The first key is the default
  language. The switch button appears automatically with two or more languages.
- Text that has no `data-i18n` attribute is not translated.
- Static files (images, favicon, PDF) go in `Content/` and are uploaded automatically with the right content type.

Publish with:

```bash
node scripts/prerender.mjs
terraform apply -var-file=terraform.tfvars
```

Objects that exist in the bucket but not in `Content/` are never deleted by Terraform.

## Destroying

`terraform destroy` removes everything except a non-empty bucket (`force_destroy = false`); empty the bucket first.
