"use strict";

/**
 * Vuepress documentation builder.
 */

const fs = require("fs");
const vuepress = require("vuepress");

function copyFiles() {
  fs.copyFileSync("README.md", "docs/index.md");
}

copyFiles();
vuepress.build({
  theme: "@vuepress/theme-default",
  dest: "site",
  sourceDir: "docs",
});
