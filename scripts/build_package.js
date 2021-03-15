"use strict";

/**
 * Copies and creates files to generate a software package.
 */

const debian = require("./package/debian");
const fedora = require("./package/fedora");
const fs = require("fs");
const path = require("path");

function main() {
  const format = process.argv[2];
  const version = process.argv[3];
  const repoPath = path.dirname(__dirname);
  const destDir = path.join(repoPath, "dist");
  fs.mkdirSync(destDir, { recursive: true });

  let packagePath;
  switch (format) {
    case "deb":
      packagePath = debian.build(repoPath, destDir, version);
      break;
    case "rpm":
      packagePath = fedora.build(repoPath, destDir, version);
      break;
    default:
      console.error(`Unknown package format: ${format}.`);
  }
  console.log(packagePath);
}

main();
