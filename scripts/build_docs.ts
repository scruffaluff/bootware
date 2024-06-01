/**
 * Vuepress documentation builder.
 */

import * as vitepress from "vitepress";
import fs from "node:fs";
import mustache from "mustache";
import path from "node:path";
import prettier from "prettier";
import url from "node:url";

interface Condition {
  arch?: string;
  os?: string;
}

interface System {
  arch: string;
  os: string;
}

/**
 * Check if system matches any of the skip conditions.
 * @param system - The host architecture and os information.
 * @param conditions - The skip conditions for the role.
 * @return Whether system should be skipped.
 */
function shouldSkip(system: System, conditions: Array<Condition>): boolean {
  if (!conditions) {
    return false;
  }
  const distros = ["alpine", "arch", "fedora", "debian", "suse", "ubuntu"];
  const systemDistro = distros.includes(system.os);

  for (const condition of conditions) {
    if (condition.arch === undefined) {
      if (system.os === condition.os) {
        return true;
      } else if (condition.os === "linux" && systemDistro) {
        return true;
      }
    } else if (system.arch === condition.arch) {
      if (condition.os === undefined) {
        return true;
      } else if (system.os === condition.os) {
        return true;
      } else if (condition.os === "linux" && systemDistro) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Generate, template, and write software roles documentation file.
 * @param repoPath - System path to the repository.
 * @return Markdown table of tested roles.
 */
function rolesTable(repoPath: string): string {
  const systems = [
    { arch: "amd64", os: "alpine" },
    { arch: "amd64", os: "arch" },
    { arch: "amd64", os: "debian" },
    { arch: "amd64", os: "fedora" },
    { arch: "amd64", os: "freebsd" },
    { arch: "amd64", os: "macos" },
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
 * @param repoPath - System path to the repository.
 */
async function writeSoftware(repoPath: string): Promise<void> {
  const table = rolesTable(repoPath);

  const templatePath = path.join(
    repoPath,
    "scripts/templates/software.mustache"
  );
  const template = fs.readFileSync(templatePath, "utf8");
  const softwareText = mustache.render(template, { table });

  const prettyText = await prettier.format(softwareText, {
    parser: "markdown",
  });
  const softwarePath = path.join(repoPath, "docs/software.md");
  fs.writeFileSync(softwarePath, prettyText);
}

async function main(): Promise<void> {
  const repoPath = path.dirname(
    path.dirname(url.fileURLToPath(import.meta.url))
  );
  writeSoftware(repoPath);
  vitepress.build(".");
}

main();
