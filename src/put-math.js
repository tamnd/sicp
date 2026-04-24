#!/usr/bin/env node

// Usage: ./put-math.js json_db file1 [file2 ...]
//  json_db: existing JSON file mapping LaTeX -> MathML;
//  file1, file2, ...: output files to modify in place.
//
// Replaces LaTeX markup (\(...\), \[...\]) in the given files with MathML
// from the database. If a formula has no entry, it is rendered in blue so
// it stands out for the author.

const fs = require('fs');

const args = process.argv.slice(2);
if (args.length < 2) {
  console.error('Usage: ./put-math.js json_db file1 [file2 ...]');
  process.exit(1);
}

const dbPath = args[0];
const inputs = args.slice(1);
const pattern = /\\\([\s\S]+?\\\)|\\\[[\s\S]+?\\\]/g;

const mathml = JSON.parse(fs.readFileSync(dbPath, 'utf8'));

for (const file of inputs) {
  const text = fs.readFileSync(file, 'utf8');
  const out = text.replace(pattern, (latex) =>
    mathml[latex] || "<span style='color:blue'>" + latex + '</span>'
  );
  fs.writeFileSync(file, out);
}
