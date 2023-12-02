"use strict";

/**
 * Copies and creates files to generate a Debian package.
 *
 * For the manual on creating Debian packages, visit
 * https://www.debian.org/doc/debian-policy/index.html.
 */

const fs = require("fs");
const mustache = require("mustache");
const path = require("path");
const childProcess = require("child_process");

function buildPackage(buildPath, destPath) {
  // Do not use stdio: "inherit", since then dpkg-deb will print to stdout and
  // mangle the captured path for the GitHubCI release workflow.
  childProcess.execSync(`dpkg-deb --build ${buildPath} ${destPath}`);
}

function createDirectories(buildDirs) {
  for (const key in buildDirs) {
    fs.mkdirSync(buildDirs[key], { recursive: true });
  }
}

function copyFiles(repoPath, buildDirs) {
  const bootwareScript = path.join(repoPath, "bootware.sh");
  fs.copyFileSync(bootwareScript, path.join(buildDirs.bin, "bootware"));

  const manPage = path.join(repoPath, "completions/bootware.man");
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
  const sourcePath = path.join(repoPath, "scripts/templates/control.mustache");
  const template = fs.readFileSync(sourcePath, "utf8");
  const text = mustache.render(template, { version });

  const destPath = path.join(buildDirs.debian, "control");
  fs.writeFileSync(destPath, text);
}

function build(repoPath, destDir, version) {
  const packageName = `bootware_${version}_all`;
  const buildPath = path.join(repoPath, "build", packageName);
  const destPath = path.join(destDir, `${packageName}.deb`);

  const buildDirs = getBuildDirs(buildPath);
  createDirectories(buildDirs);
  copyFiles(repoPath, buildDirs);
  templateControl(repoPath, buildDirs, version);
  buildPackage(buildPath, destPath);

  return destPath;
}

exports.build = build;
