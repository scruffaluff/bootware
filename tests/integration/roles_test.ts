#!/usr/bin/env -S deno run --allow-read --allow-run
// Do not use long form --split-string flag for env. It does not work properly
// on some versions of Arch Linux.

// Execute shell commands to test binaries installed from roles.
import Denomander from "https://deno.land/x/denomander@0.9.3/mod.ts";
import * as path from "https://deno.land/std@0.186.0/path/mod.ts";
import * as streams from "https://deno.land/std@0.186.0/streams/mod.ts";

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

function identity<Type>(parameter: Type): Type {
  return parameter;
}

/**
 * Check if system matches any of the skip conditions.
 * @param system - The host architecture and os information.
 * @patam conditions - The skip conditions for the role.
 * @return Whether system should be skipped.
 */
function shouldSkip(system: Dict, conditions?: Array<Dict>): boolean {
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
 * @param system - The host architecture and os information.
 * @patam role - Testing information for a role.
 */
async function testRole(system: Dict, role: RoleTest): Promise<boolean> {
  let error = false;
  const decoder = new TextDecoder();
  let tests: Array<string>;
  const message = new TextEncoder().encode(`testing: ${role.name}`);
  await streams.writeAll(Deno.stdout, message);

  if (role.tests && !shouldSkip(system, role.skip)) {
    if (Array.isArray(role.tests)) {
      tests = role.tests;
    } else {
      tests = role.tests[system.os] || role.tests.default;
    }

    for (const test of tests) {
      const process = await Deno.run({
        cmd: [system.shell, "-c", test],
        stderr: "piped",
        stdout: "piped",
      });
      if (!(await process.status()).success) {
        error = true;
        console.log("-> fail\n");
        console.error(decoder.decode(await process.stderrOutput()));
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
  const program = new Denomander({
    app_name: "roles-test",
    app_description:
      "Execute shell commands to test binaries installed from roles",
    app_version: "0.0.1",
  });

  const defaultShell = {
    darwin: "/bin/bash",
    freebsd: "/usr/local/bin/bash",
    linux: "/bin/bash",
    windows: "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe",
  }[Deno.build.os];

  program
    .defaultCommand("[os]")
    .argDescription("os", "Operating system")
    .option("-a --arch", "System architecture", identity, "amd64")
    .option("--shell", "Test shell", identity, defaultShell)
    .option("-s --skip", "Roles to skip")
    .option("-t --tags", "Roles to test")
    .parse(Deno.args);

  const scriptFolder = path.dirname(path.fromFileUrl(import.meta.url));
  const rolesPath = path.join(path.dirname(scriptFolder), "data/roles.json");
  let roles = JSON.parse(await Deno.readTextFile(rolesPath));

  if (program.tags) {
    roles = roles.filter((role: RoleTest) => program.tags.includes(role.name));
  }

  if (program.skip) {
    roles = roles.filter((role: RoleTest) => !program.skip.includes(role.name));
  }

  let error = false;
  for (const role of roles) {
    error =
      (await testRole(
        { arch: program.architecture, os: program.os, shell: program.shell },
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
