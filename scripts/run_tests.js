"use strict";

/**
 * Run all Docker integration tests for an architecture.
 */

const childProcess = require("child_process");

function main() {
  const config = parse_args(process.argv.slice(2));

  let args = `--build-arg test=true`;
  if (config.skip) {
    args = `--build-arg skip=${config.skip} ` + args;
  }
  if (config.tags) {
    args = args + ` --build-arg tags=${config.tags}`;
  }

  for (const distro of config.distros) {
    const command = `docker build --no-cache -f tests/integration/Dockerfile.${distro} -t bootware:${distro} --platform linux/${config.architecture}`;
    childProcess.execSync(`${command} . ${args}`, { stdio: "inherit" });

    console.log(`Integration test ${distro} passed.`);
  }

  console.log(`All integration tests passed.`);
}

function parse_args(args) {
  let params = {
    architecture: "amd64",
    distros: ["arch", "debian", "fedora", "ubuntu"],
    skip: null,
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
      case "-d":
      case "--distros":
        params.distros = args[index + 1].split(",");
        index += 2;
        break;
      case "-s":
      case "--skip":
        params.skip = args[index + 1];
        index += 2;
        break;
      case "-t":
      case "--tags":
        params.tags = args[index + 1];
        index += 2;
        break;
      default:
        console.error(`error: No such option ${args[index]}`);
        process.exit(2);
    }
  }

  return params;
}

main();
