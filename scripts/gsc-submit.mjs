// Adds the domain property to Google Search Console and submits the sitemap.
// Called by Terraform (tf-07-google-search.tf). Needs Node >= 18.
//
// Env: GOOGLE_TOKEN (OAuth access token), GOOGLE_PROJECT (quota project),
//      DOMAIN (e.g. example.com), SITEMAP_URL (full sitemap URL)
//
// Verifying a domain does not create the Search Console property, so the
// property is added first (sites.add), then the sitemap is submitted.

const { GOOGLE_TOKEN, GOOGLE_PROJECT, DOMAIN, SITEMAP_URL } = process.env;
for (const [name, value] of Object.entries({ GOOGLE_TOKEN, GOOGLE_PROJECT, DOMAIN, SITEMAP_URL })) {
  if (!value) {
    console.error(`Missing environment variable ${name}`);
    process.exit(2);
  }
}

const site = `https://www.googleapis.com/webmasters/v3/sites/${encodeURIComponent(`sc-domain:${DOMAIN}`)}`;

async function put(url) {
  const response = await fetch(url, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${GOOGLE_TOKEN}`,
      "x-goog-user-project": GOOGLE_PROJECT,
      "Content-Length": "0",
    },
  });
  if (!response.ok) {
    throw new Error(`PUT ${url} -> ${response.status} ${await response.text()}`);
  }
}

await put(site);
console.log(`Search Console property added: sc-domain:${DOMAIN}`);
await put(`${site}/sitemaps/${encodeURIComponent(SITEMAP_URL)}`);
console.log(`Sitemap submitted: ${SITEMAP_URL}`);
