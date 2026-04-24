#!/usr/bin/env node

// Usage: ./get-math.js json_db file1 [file2 ...]
//  json_db: JSON file mapping LaTeX source -> MathML (created/updated here);
//  file1, file2, ...: HTML files to scan for LaTeX strings.
//
// LaTeX must be delimited by \( \) (inline) or \[ \] (display math).
// Node replacement for the original phantomjs + MathJax 2 script.

const fs = require('fs');

const args = process.argv.slice(2);
if (args.length < 2) {
  console.error('Usage: ./get-math.js json_db file1 [file2 ...]');
  process.exit(1);
}

const dbPath = args[0];
const inputs = args.slice(1);
const pattern = /\\\([\s\S]+?\\\)|\\\[[\s\S]+?\\\]/g;

const found = {};
for (const file of inputs) {
  const text = fs.readFileSync(file, 'utf8');
  let m;
  while ((m = pattern.exec(text)) !== null) found[m[0]] = '';
}

const oldDb = fs.existsSync(dbPath)
  ? JSON.parse(fs.readFileSync(dbPath, 'utf8'))
  : {};

const result = {};
const delta = [];
for (const latex of Object.keys(found)) {
  if (oldDb[latex]) result[latex] = oldDb[latex];
  else { delta.push(latex); result[latex] = ''; }
}

if (delta.length === 0) {
  fs.writeFileSync(dbPath, JSON.stringify(result, null, 2));
  process.exit(0);
}

require('mathjax-full/es5/node-main').init({
  loader: { load: ['input/tex-full', 'output/chtml'] },
  startup: { typeset: false },
}).then((MathJax) => {
  for (const raw of delta) {
    const display = raw.startsWith('\\[');
    const body = raw.slice(2, -2);
    try {
      let mml = MathJax.tex2mml(body, { display });
      mml = mml.replace(/\s+$/, '').replace(/\n/g, '\n');
      result[raw] = mml;
    } catch (err) {
      result[raw] = "<span class='faulty'>" + raw + '</span>';
      console.error('TeX conversion failed:', raw, err.message);
    }
  }
  fs.writeFileSync(dbPath, JSON.stringify(result, null, 2));
}).catch((err) => {
  console.error(err);
  process.exit(1);
});
