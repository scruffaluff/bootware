"use strict";

/**
 * Execute shell commands to test binaries installed from roles.
 */

const childProcess = require("child_process");
const fs = require("fs");
const path = require("path");

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
 * Execute tests for the successfull installation of a role.
 * @param {Object} system - The host architecture and os information.
 * @patam {Object} role - Testing information for a role.
 */
function testRole(system, role) {
  process.stdout.write(`testing: ${role.name}`);

  if (role.tests && !shouldSkip(system, role.skip)) {
    for (const test of role.tests) {
      try {
        childProcess.execSync(test, { stdio: "pipe" });
      } catch (error) {
        console.log("-> fail\n");
        console.error(error.stderr.toString());
        process.exit(1);
      }
    }
    console.log("-> pass");
  } else {
    console.log("-> skip");
  }
}

function main() {
  const [os, arch, skipList, tagList] = process.argv.slice(2, 6);

  const rolesPath = path.join(path.dirname(__dirname), "data/roles.json");
  let roles = JSON.parse(fs.readFileSync(rolesPath, "utf8"));

  if (tagList) {
    const tags = tagList.split(",");
    roles = roles.filter((role) => tags.includes(role.name));
  }

  if (skipList) {
    const skips = skipList.split(",");
    roles = roles.filter((role) => !skips.includes(role.name));
  }

  for (const role of roles) {
    testRole({ arch, os }, role);
  }
}

main();
