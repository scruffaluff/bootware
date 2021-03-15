"use strict";

/**
 * Copies and creates files to generate a RPM package.
 *
 * For the manual on creating RPM packages, visit
 * https://rpm-packaging-guide.github.io/.
 */

const fs = require("fs");
const mustache = require("mustache");
const path = require("path");
const childProcess = require("child_process");

function archiveFiles(repoPath) {
  childProcess.execSync(`tar -cvzf ${destPath} ${buildPath} `);
}

function buildPackage(buildPath, destPath) {
  childProcess.execSync(
    `rpmbuild -ba ${buildPath}/SPECS/bootware.spec ${destPath}`
  );
}

function createDirectories(buildDirs) {
  for (const key in buildDirs) {
    fs.mkdirSync(buildDirs[key], { recursive: true });
  }
}

function getBuildDirs(buildPath) {
  return {
    build: path.join(buildPath, "BUILD"),
    root: buildPath,
    rpm: path.join(buildPath, "RPMS"),
    source: path.join(buildPath, "SOURCES"),
    spec: path.join(buildPath, "SPECS"),
  };
}

function templateSpec(repoPath, buildDirs, version) {
  const sourcePath = path.join(repoPath, "scripts/templates/spec.mustache");
  const template = fs.readFileSync(sourcePath, "utf8");
  const text = mustache.render(template, { version });

  const destPath = path.join(buildDirs.spec, "bootware.spec");
  fs.writeFileSync(destPath, text);
}

function build(repoPath, destDir, version) {
  const packageName = `bootware-${version}-1.fc33.noarch`;
  const buildPath = path.join(repoPath, "build", packageName);
  const destPath = path.join(destDir, `${packageName}.rpm`);

  const buildDirs = getBuildDirs(buildPath);
  createDirectories(buildDirs);
  templateSpec(repoPath, buildDirs, version);
  buildPackage(buildPath, destPath);

  return destPath;
}

exports.build = build;
