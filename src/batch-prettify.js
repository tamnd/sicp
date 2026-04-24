#!/usr/bin/env node

// Usage: ./batch-prettify.js file1 [file2 ...]
// Syntax-highlights Scheme code in the given XHTML files in place.
//
// Node replacement for the original phantomjs script. Runs
// google-code-prettify (prettify.js + lang-lisp.js) inside a jsdom window,
// then removes any <script class="prettifier"> tags and writes the file
// back.

const fs = require('fs');
const path = require('path');
const { JSDOM, VirtualConsole } = require('jsdom');

const HIGHL_DIR = path.join(__dirname, 'en_US', 'js', 'highlight');
const PRETTIFY_SRC = fs.readFileSync(path.join(HIGHL_DIR, 'prettify.js'), 'utf8');
const LANGLISP_SRC = fs.readFileSync(path.join(HIGHL_DIR, 'lang-lisp.js'), 'utf8');

const args = process.argv.slice(2);
if (args.length < 1) {
  console.error('Usage: ./batch-prettify.js file1 [file2 ...]');
  process.exit(1);
}

function prettifyFile(file) {
  const src = fs.readFileSync(file, 'utf8');
  const virtualConsole = new VirtualConsole();
  virtualConsole.on('jsdomError', () => {});
  const dom = new JSDOM(src, {
    contentType: src.trimStart().startsWith('<?xml')
      ? 'application/xhtml+xml'
      : 'text/html',
    runScripts: 'outside-only',
    virtualConsole,
  });
  const { window } = dom;
  try {
    window.eval(PRETTIFY_SRC);
    window.eval(LANGLISP_SRC);
    if (typeof window.prettyPrint === 'function') {
      window.prettyPrint();
    } else {
      console.error('prettyPrint not defined for', file);
      return;
    }
  } catch (err) {
    console.error('prettify error in', file, err.message);
    return;
  }
  const scripts = window.document.querySelectorAll('script.prettifier');
  scripts.forEach((s) => s.parentNode.removeChild(s));
  const out = dom.serialize();
  fs.writeFileSync(file, out);
}

(async () => {
  for (const file of args) {
    if (!fs.existsSync(file)) {
      console.error('No such file:', file);
      continue;
    }
    prettifyFile(file);
  }
})();
