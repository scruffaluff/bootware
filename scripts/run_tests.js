"use strict";

/**
 * Run all Docker integration tests for an architecture.
 */

const childProcess = require("child_process");

function main() {
  const architecture = process.argv[2];
  const skip = process.argv[3];
  const tags = process.argv[4];

  let args = `--build-arg test=true`;
  if (skip) {
    args = `--build-arg skip=${skip} ` + args;
  }
  if (tags) {
    args = args + ` --build-arg tags=${tags}`;
  }

  const distros = ["arch", "debian", "fedora", "ubuntu"];

  for (const distro of distros) {
    const command = `docker build --no-cache -f tests/integration/Dockerfile.${distro} -t bootware:${distro} --platform=linux/${architecture}`;
    childProcess.execSync(`${command} . ${args}`, { stdio: "inherit" });

    console.log(`Integration test ${distro} passed.`);
  }
}

main();
