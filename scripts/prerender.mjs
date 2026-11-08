// SEO prerender: writes the default-language text from Content/Language.js into
// Content/index.html, so crawlers see the content even without running JavaScript.
// The data-i18n attributes are kept, so the in-page language switch still works.
// The default language is the FIRST key of the `translations` object.
//
// Usage:  node scripts/prerender.mjs [content-dir]     (idempotent)
//         then `terraform apply` to publish.

import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(process.argv[2] ?? path.join(here, "..", "Content"));
const htmlPath = path.join(root, "index.html");

// Load Language.js in a sandbox with a fake `document` to extract `translations`
const stubEl = { addEventListener() {}, remove() {}, set textContent(_) {}, dataset: {} };
const ctx = vm.createContext({
  document: {
    documentElement: {},
    addEventListener() {},
    querySelectorAll: () => [],
    getElementById: () => stubEl,
  },
});
vm.runInContext(fs.readFileSync(path.join(root, "Language.js"), "utf8"), ctx);
const translations = vm.runInContext("translations", ctx);
const defaultLang = Object.keys(translations)[0];

const escapeHtml = (s) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const lookup = (key) => key.split(".").reduce((v, k) => v?.[k], translations[defaultLang]);

const missing = [];
let count = 0;
let html = fs
  .readFileSync(htmlPath, "utf8")
  .replace(
    /(<([a-z0-9]+)\b[^>]*\bdata-i18n="([^"]+)"[^>]*>)([\s\S]*?)(<\/\2>)/gi,
    (whole, open, _tag, key, _old, close) => {
      const value = lookup(key);
      if (!value) {
        missing.push(key);
        return whole;
      }
      count++;
      return `${open}${escapeHtml(value)}${close}`;
    }
  )
  .replace(/<html lang="[^"]*"/i, `<html lang="${defaultLang}"`);

fs.writeFileSync(htmlPath, html);
console.log(`Prerender (${defaultLang}): ${count} elements filled in ${htmlPath}`);
if (missing.length) {
  console.error(`Keys without a "${defaultLang}" translation: ${missing.join(", ")}`);
  process.exitCode = 1;
}
