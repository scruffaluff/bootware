/**
 * Run all Docker integration tests for an architecture.
 */

import childProcess from "node:child_process";
import process from "node:process";
import { Command } from "commander";

function main(): void {
  const program = new Command();
  program
    .option(
      "-a, --arch <architecture>",
      "Chip architecture",
      process.arch === "x64" ? "amd64" : process.arch
    )
    .option("-c, --cache", "Use Docker cache")
    .option("-d, --distro <distributions...>", "Linux distributions list", [
      "alpine",
      "arch",
      "collection",
      "debian",
      "fedora",
      "suse",
      "ubuntu",
    ])
    .option("-s, --skip <roles...>", "Ansible roles to skip", "")
    .option("-t, --tags <roles...>", "Ansible roles to keep", "")
    .parse();
  const config = program.opts();

  let args = `--build-arg test=true`;
  if (config.skip) {
    args = `--build-arg skip=${config.skip} ` + args;
  }
  if (config.tags) {
    args = args + ` --build-arg tags=${config.tags}`;
  }

  for (const distro of config.distro) {
    const command = `docker build ${
      config.cache ? "" : "--no-cache"
    } --file tests/integration/${distro}.dockerfile --tag docker.io/scruffaluff/bootware:${distro} --platform linux/${
      config.arch
    }`;
    childProcess.execSync(`${command} . ${args}`, { stdio: "inherit" });

    console.log(`Integration test ${distro} passed.`);
  }

  console.log(`All integration tests passed.`);
}

main();
