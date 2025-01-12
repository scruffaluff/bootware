#!/usr/bin/env -S deno run --allow-read --allow-run
// Do not use long form --split-string flag for env. It does not work properly
// on some versions of Arch Linux.

// Execute shell commands to test binaries installed from roles.
import { Command } from "jsr:@cliffy/command@1.0.0-rc.7";
import * as path from "jsr:@std/path";
import * as write_all from "jsr:@std/io/write-all";

interface Dict {
  [key: string]: string;
}

interface DictArray {
  [key: string]: Array<string>;
}

interface RoleTest {
  name: string;
  skip?: Array<Dict>;
  tests?: Array<string> | DictArray;
}

/**
 * Check if operating system is a Linux distribution.
 * @param {Object} system - The host operating system.
 * @return {boolean} Whether the system is a Linux distribution
 */
function isLinux(distro: string): boolean {
  const distros = ["alpine", "arch", "fedora", "debian", "ubuntu"];
  return distros.includes(distro);
}

/**
 * Check if system matches any of the skip conditions.
 * @param system - The host architecture and os information.
 * @param conditions - The skip conditions for the role.
 * @return Whether system should be skipped.
 */
function shouldSkip(system: Dict, conditions?: Array<Dict>): boolean {
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
 * @param system - The host architecture and os information.
 * @param role - Testing information for a role.
 */
async function testRole(system: Dict, role: RoleTest): Promise<boolean> {
  let error = false;
  const decoder = new TextDecoder();
  let tests: Array<string>;
  const message = new TextEncoder().encode(`testing: ${role.name}`);
  await write_all.writeAll(Deno.stdout, message);

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
      const process = new Deno.Command(system.shell, {
        args: ["-c", test],
        stderr: "piped",
        stdout: "piped",
      });
      const result = await process.output();
      if (!result.success) {
        error = true;
        console.log("-> fail\n");
        console.error(decoder.decode(await result.stderr));
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

async function main(): Promise<void> {
  const defaultArch = {
    aarch64: "arm64",
    x86_64: "amd64",
  }[Deno.build.arch];
  // @ts-ignore Only the following operating systems are supported.
  const defaultShell = {
    darwin: "/bin/bash",
    freebsd: "/usr/local/bin/bash",
    linux: "/bin/bash",
    windows: "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
  }[Deno.build.os];

  const program = await new Command()
    .name("roles-test")
    .description("Execute shell commands to test binaries installed from roles")
    .version("0.0.2")
    .option("-a --arch <architecture:string>", "System architecture", {
      default: defaultArch,
    })
    .option("--shell <shell:string>", "Test shell", { default: defaultShell })
    .option("-s --skip <roles:string>", "Roles to skip")
    .option("-t --tags <roles:string>", "Roles to test")
    .arguments("<os:string>")
    .parse();

  const scriptFolder = path.dirname(path.fromFileUrl(import.meta.url));
  const rolesPath = path.join(path.dirname(scriptFolder), "data/roles.json");
  let roles = JSON.parse(await Deno.readTextFile(rolesPath));

  if (program.options.tags) {
    roles = roles.filter((role: RoleTest) =>
      program.options.tags.includes(role.name)
    );
  }

  if (program.options.skip) {
    roles = roles.filter(
      (role: RoleTest) => !program.options.skip.includes(role.name)
    );
  }

  let error = false;
  for (const role of roles) {
    error =
      (await testRole(
        {
          arch: program.options.arch,
          os: program.args[0],
          shell: program.options.shell,
        },
        role
      )) || error;
  }

  if (error) {
    console.error("\nIntegration tests failed.");
    Deno.exit(1);
  } else {
    console.log("\nIntegration tests passed.");
  }
}

await main();
