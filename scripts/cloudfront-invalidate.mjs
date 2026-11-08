// Invalidates the whole CloudFront cache. Called by Terraform (tf-06-content.tf).
// Needs the AWS CLI on PATH. Works the same on Windows, Linux and macOS.
//
// Usage: node scripts/cloudfront-invalidate.mjs <distribution-id>

import { execFileSync } from "node:child_process";

const [distributionId] = process.argv.slice(2);
if (!distributionId) {
  console.error("Usage: node cloudfront-invalidate.mjs <distribution-id>");
  process.exit(2);
}

const id = execFileSync(
  "aws",
  [
    "cloudfront", "create-invalidation",
    "--distribution-id", distributionId,
    "--paths", "/*",
    "--query", "Invalidation.Id",
    "--output", "text",
  ],
  { encoding: "utf8" }
);
console.log(`CloudFront invalidation started: ${id.trim()}`);
