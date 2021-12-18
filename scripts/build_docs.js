"use strict";

/**
 * Vuepress documentation builder.
 */

const fs = require("fs");
const mustache = require("mustache");
const path = require("path");
const prettier = require("prettier");
const vuepress = require("vuepress");

/**
 * Copy Markdown files into docs directory.
 * @param {string} repoPath - System path to the repository.
 */
function copyFiles(repoPath) {
  fs.copyFileSync(
    path.join(repoPath, "README.md"),
    path.join(repoPath, "docs/index.md")
  );
}

/**
 * Check if system matches any of the skip conditions.
 * @param {Object} system - The host architecture and os information.
 * @patam {Array<Object>} conditions - The skip conditions for the role.
 * @return {boolean} Whether system should be skipped.
 */
function shouldSkip(system, conditions) {
  if (!conditions) {
    return false;
  }

  const distros = ["alpine", "arch", "fedora", "debian", "ubuntu"];
  for (const condition of conditions) {
    let skipMatch = true;
    for (const key in condition) {
      // Skip if os condition is Linux and system is a Linux distro.
      if (key === "os" && condition[key] === "linux") {
        if (!distros.includes(system[key])) {
          skipMatch = false;
        }
      } else if (condition[key] !== system[key]) {
        skipMatch = false;
      }
    }

    if (skipMatch) {
      return true;
    }
  }

  return false;
}

/**
 * Generate, template, and write software roles documentation file.
 * @param {string} repoPath - System path to the repository.
 * @return {string} Markdown table of tested roles.
 */
function rolesTable(repoPath) {
  const systems = [
    { arch: "amd64", os: "alpine" },
    { arch: "amd64", os: "arch" },
    { arch: "amd64", os: "debian" },
    { arch: "arm64", os: "debian" },
    { arch: "amd64", os: "fedora" },
    { arch: "arm64", os: "fedora" },
    { arch: "amd64", os: "freebsd" },
    { arch: "amd64", os: "macos" },
    { arch: "amd64", os: "ubuntu" },
    { arch: "arm64", os: "ubuntu" },
    { arch: "amd64", os: "windows" },
  ];

  const rolesPath = path.join(repoPath, "tests/data/roles.json");
  let roles = JSON.parse(fs.readFileSync(rolesPath, "utf8"));

  let table = "| |";
  for (const system of systems) {
    table += ` ${system.os} ${system.arch} |`;
  }

  table += "\n| :--- |";
  for (const system of systems) {
    table += ` :---: |`;
  }

  table += "\n";
  for (const role of roles) {
    table += `| ${role.name} |`;

    for (const system of systems) {
      if (shouldSkip(system, role.skip)) {
        table += " ❌ |";
      } else {
        table += " ✅ |";
      }
    }

    table += "\n";
  }

  return table;
}

/**
 * Generate, template, and write software roles documentation file.
 * @param {string} repoPath - System path to the repository.
 */
function writeSoftware(repoPath) {
  const table = rolesTable(repoPath);

  const templatePath = path.join(
    repoPath,
    "scripts/templates/software.mustache"
  );
  const template = fs.readFileSync(templatePath, "utf8");
  const softwareText = mustache.render(template, { table });

  const prettyText = prettier.format(softwareText, { parser: "markdown" });
  const softwarePath = path.join(repoPath, "docs/software.md");
  fs.writeFileSync(softwarePath, prettyText);
}

function main() {
  const repoPath = path.dirname(__dirname);

  copyFiles(repoPath);
  writeSoftware(repoPath);

  vuepress.build({
    theme: "@vuepress/theme-default",
    dest: "site",
    sourceDir: "docs",
  });
}

main();
