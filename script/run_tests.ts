/**
 * Run all container integration tests for an architecture.
 */

import childProcess from "node:child_process";
import process from "node:process";
import { Command } from "commander";

function findRunner(): string {
  try {
    childProcess.execSync("podman --version");
    return "podman";
  } catch (error) {
    return "docker";
  }
}

function main(): void {
  const program = new Command();
  program
    .option(
      "-a, --arch <architecture>",
      "Chip architecture",
      process.arch === "x64" ? "amd64" : process.arch
    )
    .option("-c, --cache", "Use container cache")
    .option("-d, --distro <distributions...>", "Linux distributions list", [
      "alpine",
      "arch",
      "debian",
      "fedora",
      "suse",
      "ubuntu",
    ])
    .option("-s, --skip <roles...>", "Ansible roles to skip", "none")
    .option("-t, --tags <roles...>", "Ansible roles to keep", "desktop,extras")
    .parse();
  const config = program.opts();

  let args =
    `--build-arg skip=${config.skip} --build-arg tags=${config.tags}` +
    ` --build-arg test=true`;
  const runner = findRunner();
  for (const distro of config.distro) {
    const command =
      `${runner} build ${config.cache ? "" : "--no-cache"}` +
      ` --file tests/integration/${distro}.dockerfile` +
      ` --tag docker.io/scruffaluff/bootware:${distro}` +
      ` --platform linux/${config.arch}`;
    childProcess.execSync(`${command} . ${args}`, { stdio: "inherit" });

    console.log(`Integration test ${distro} passed.`);
  }

  console.log(`All integration tests passed.`);
}

main();
