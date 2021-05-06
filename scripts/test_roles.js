"use strict";

/**
 * Execute shell commands to test binaries installed from roles.
 */

const childProcess = require("child_process");
const fs = require("fs");
const path = require("path");

function shouldSkip(system, conditions) {
  if (!conditions) {
    return false;
  }

  for (const condition of conditions) {
    let skipMatch = true;
    for (const key in condition) {
      if (condition[key] != system[key]) {
        skipMatch = false;
      }
    }

    if (skipMatch) {
      return true;
    }
  }

  return false;
}

function test_role(system, role) {
  process.stdout.write(`testing: ${role.name}`);

  if (role.tests && !shouldSkip(system, role.skip)) {
    for (const test of role.tests) {
      childProcess.execSync(test);
    }
    console.log(`-> pass`);
  } else {
    console.log(`-> skip`);
  }
}

function main() {
  const os = process.argv[2];
  const arch = process.argv[3];
  const nameList = process.argv[4];

  const rolesPath = path.join(__dirname, "roles.json");
  let roles = JSON.parse(fs.readFileSync(rolesPath, "utf8"));

  if (nameList) {
    const names = nameList.split(",");
    roles = roles.filter((role) => names.includes(role.name));
  }

  for (const role of roles) {
    test_role({ arch, os }, role);
  }
}

main();
