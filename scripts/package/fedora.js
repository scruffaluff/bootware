"use strict";

/**
 * Copies and creates files to generate a RPM package.
 *
 * For the manual on creating RPM packages, visit
 * https://rpm-packaging-guide.github.io/.
 */

const fs = require("fs");
const mustache = require("mustache");
const os = require("os");
const path = require("path");
const childProcess = require("child_process");

function archiveFiles(repoPath, buildDirs, version) {
  const tarName = `bootware-${version}.tar.gz`;
  const destPath = path.join(buildDirs.source, tarName);

  const tmpDir = os.tmpdir();
  const copyDir = path.join(tmpDir, `bootware-${version}`);
  fs.mkdirSync(copyDir, { recursive: true });

  const bootwareScript = path.join(repoPath, "bootware.sh");
  fs.copyFileSync(bootwareScript, path.join(copyDir, "bootware"));

  const manPage = path.join(repoPath, "completions/bootware.man");
  fs.copyFileSync(manPage, path.join(copyDir, "bootware.1"));

  const copyDirName = path.basename(copyDir);
  childProcess.execSync(`tar -cvzf ${tarName} -C ${tmpDir} ${copyDirName}`, {
    stdio: "inherit",
  });

  fs.renameSync(tarName, destPath);
}

function buildPackage(buildDirs, destPath, version) {
  const specPath = path.join(buildDirs.spec, "bootware.spec");
  childProcess.execSync(`rpmbuild -ba ${specPath}`, { stdio: "inherit" });

  const rpmPath = path.join(
    buildDirs.rpm,
    `noarch/bootware-${version}-1.fc33.noarch.rpm`
  );
  fs.renameSync(rpmPath, destPath);
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
  const buildPath = path.join(os.homedir(), "rpmbuild");
  const destPath = path.join(destDir, `${packageName}.rpm`);

  const buildDirs = getBuildDirs(buildPath);
  createDirectories(buildDirs);
  archiveFiles(repoPath, buildDirs, version);
  templateSpec(repoPath, buildDirs, version);
  buildPackage(buildDirs, destPath, version);

  return destPath;
}

exports.build = build;
