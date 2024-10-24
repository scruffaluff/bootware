"use strict";

/**
 * Execute shell commands to test binaries installed from roles.
 */

const childProcess = require("child_process");
const fs = require("fs");
const path = require("path");
const process = require("node:process");

/**
 * Check if operating system is a Linux distribution.
 * @param {Object} system - The host operating system.
 * @return {boolean} Whether the system is a Linux distribution
 */
function isLinux(distro) {
  const distros = ["alpine", "arch", "fedora", "debian", "ubuntu"];
  return distros.includes(distro);
}

function parseArgs(args) {
  const params = {
    architecture: process.arch === "x86" ? "amd64" : process.arch,
    os: null,
    skips: null,
    shell: {
      darwin: "/bin/bash",
      freebsd: "/usr/local/bin/bash",
      linux: "/bin/bash",
      win32: "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
    }[process.platform],
    tags: null,
  };

  let index = 0;
  while (index < args.length) {
    switch (args[index]) {
      case "-a":
      case "--arch":
        params.architecture = args[index + 1];
        index += 2;
        break;
      case "--shell":
        params.shell = args[index + 1];
        index += 2;
        break;
      case "-s":
      case "--skip":
        params.skips = args[index + 1];
        index += 2;
        break;
      case "-t":
      case "--tags":
        params.tags = args[index + 1];
        index += 2;
        break;
      default:
        if (params.os === null) {
          params.os = args[index];
          index += 1;
        } else {
          console.error(`error: No such option ${args[index]}`);
          process.exit(2);
        }
    }
  }

  if (params.os === null) {
    console.error(`error: The os argument is required`);
    process.exit(2);
  }

  return params;
}

/**
 * Check if system matches any of the skip conditions.
 * @param {Object} system - The host architecture and os information.
 * @param {Array<Object>} conditions - The skip conditions for the role.
 * @return {boolean} Whether system should be skipped.
 */
function shouldSkip(system, conditions) {
  if (!conditions) {
    return false;
  }

  for (const condition of conditions) {
    let skipMatch = true;
    for (const key in condition) {
      // Skip if os condition is Linux and system is a Linux distro.
      if (key === "os" && condition[key] === "linux") {
        if (!isLinux(system[key])) {
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
 * @param {Object} role - Testing information for a role.
 */
function testRole(system, role) {
  let error = false;
  let tests;
  process.stdout.write(`testing: ${role.name}`);

  if (role.tests && !shouldSkip(system, role.skip)) {
    if (Array.isArray(role.tests)) {
      tests = role.tests;
    } else if (isLinux(system.os)) {
      tests =
        role.tests[system.os] || role.tests["linux"] || role.tests.default;
    } else {
      tests = role.tests[system.os] || role.tests.default;
    }

    for (const test of tests) {
      try {
        childProcess.execSync(test, { shell: system.shell, stdio: "pipe" });
      } catch (exception) {
        error = true;
        console.log("-> fail\n");
        console.error(exception.stderr.toString());
      }
    }

    if (!error) {
      console.log("-> pass");
    }
  } else {
    console.log("-> skip");
  }

  return error;
}

function main() {
  const config = parseArgs(process.argv.slice(2));

  const rolesPath = path.join(path.dirname(__dirname), "data/roles.json");
  let roles = JSON.parse(fs.readFileSync(rolesPath, "utf8"));

  if (config.tags) {
    roles = roles.filter((role) => config.tags.includes(role.name));
  }

  if (config.skips) {
    roles = roles.filter((role) => !config.skips.includes(role.name));
  }

  let error = false;
  for (const role of roles) {
    error =
      testRole(
        { arch: config.architecture, os: config.os, shell: config.shell },
        role
      ) || error;
  }

  if (error) {
    console.error("\nIntegration tests failed.");
    process.exit(1);
  } else {
    console.log("\nIntegration tests passed.");
  }
}

main();
