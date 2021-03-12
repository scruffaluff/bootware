"use strict";

/**
 * Copies and creates files to generate a Debian package.
 */

const fs = require("fs");
const mustache = require("mustache");
const path = require("path");
const childProcess = require("child_process");

function buildPackage(buildPath) {
  childProcess.execSync(`dpkg-deb --build ${buildPath}`);
}

function createDirectories(buildDirs) {
  for (const key in buildDirs) {
    fs.mkdirSync(buildDirs[key], { recursive: true });
  }
}

function copyFiles(repoPath, buildDirs) {
  const bootwareScript = path.join(repoPath, "bootware.sh");
  fs.copyFileSync(bootwareScript, path.join(buildDirs.bin, "bootware"));

  const manPage = path.join(repoPath, "dist/man/bootware.1");
  fs.copyFileSync(manPage, path.join(buildDirs.man, "bootware.1"));
}

function getBuildDirs(buildPath) {
  const usrLocal = path.join(buildPath, "usr/local");

  return {
    bin: path.join(usrLocal, "bin"),
    debian: path.join(buildPath, "DEBIAN"),
    man: path.join(usrLocal, "share/man/man1"),
    root: buildPath,
  };
}

function templateControl(repoPath, buildDirs, version) {
  const sourcePath = path.join(repoPath, "scripts/control.mustache");
  const template = fs.readFileSync(sourcePath, "utf8");
  const text = mustache.render(template, { version });

  const destPath = path.join(buildDirs.debian, "control");
  fs.writeFileSync(destPath, text);
}

function main() {
  const version = process.argv[2];
  const repoPath = path.dirname(__dirname);
  const packageName = `bootware_${version}_all`;
  const buildPath = path.join(repoPath, "tmp", packageName);

  const buildDirs = getBuildDirs(buildPath);
  createDirectories(buildDirs);
  copyFiles(repoPath, buildDirs);
  templateControl(repoPath, buildDirs, version);
  buildPackage(buildPath);
}

main();
