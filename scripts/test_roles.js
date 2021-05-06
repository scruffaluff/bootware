"use strict";

/**
 * Execute shell commands to test binaries installed from roles.
 */

const childProcess = require("child_process");
const fs = require("fs");
const path = require("path");
const yaml = require("js-yaml");

function test_role(system, architecture, role) {
  process.stdout.write(`testing: ${role.name}`);

  if (role.tests) {
    for (const test of role.tests) {
      childProcess.execSync(test);
    }
    console.log(`-> pass`);
  } else {
    console.log(`-> skip`);
  }
}

function main() {
  const architecture = process.argv[2];
  const system = process.argv[3];

  const rolesPath = path.join(__dirname, "roles.yaml");
  const roles = yaml.load(fs.readFileSync(rolesPath, "utf8"));

  for (const role of roles) {
    test_role(system, architecture, role);
  }
}

main();
