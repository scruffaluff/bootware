"use strict";

/**
 * Vuepress documentation builder.
 */

const fs = require("fs");
const vuepress = require("vuepress");

function copyFiles() {
  fs.mkdirSync("docs", { recursive: true });
  fs.copyFileSync("README.md", "docs/index.md");
}

function main() {
  copyFiles();
  vuepress.build({
    theme: "@vuepress/theme-default",
    dest: "site",
    sourceDir: "docs",
  });
}

main();
