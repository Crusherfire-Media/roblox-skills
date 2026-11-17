#!/usr/bin/env node
// Wrap a markdown file in a one-line kit page so it opens in the browser.
//   node kit/md2html.cjs report.md            -> report.html (kit extensions on)
//   node kit/md2html.cjs report.md --plain    -> report.html (plain GitHub-style render)
// The agent only ever writes the .md; this step costs zero tokens.
const fs = require("fs");
const url = require("url");
const path = require("path");

const args = process.argv.slice(2);
const plain = args.includes("--plain");
const files = args.filter((a) => !a.startsWith("--"));
if (!files.length) {
  console.error("usage: node kit/md2html.cjs <file.md> [--plain]");
  process.exit(1);
}
const kit = path.join(__dirname, "kit.js");
for (const file of files) {
  const src = fs.readFileSync(file, "utf8");
  const out = file.replace(/\.(md|markdown)$/i, "") + ".html";
  // A URL, not a file path: encode each segment so "#", "?" or spaces in folder names still load.
  // On another Windows drive there is no relative path, so link the kit by its file URL.
  const relPath = path.relative(path.dirname(path.resolve(out)), kit);
  const rel = path.isAbsolute(relPath) ? url.pathToFileURL(kit).href : relPath.split(path.sep).map(encodeURIComponent).join("/");
  const safe = src.replace(/<\/script/gi, "<\\/script");
  const html = `<!doctype html><meta charset="utf-8"><script src="${rel}" defer></script>\n<rk-md${plain ? " plain" : ""}><script type="text/markdown">\n${safe}\n</script></rk-md>\n`;
  fs.writeFileSync(out, html);
  console.log(out);
}
