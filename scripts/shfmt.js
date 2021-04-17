"use strict";

/**
 * Convenience script for running Shfmt.
 */

const childProcess = require("child_process");

function main() {
  let options;
  let paths = "bootware.sh install.sh roles/";

  switch (process.argv[2]) {
    case "format":
      options = "-w";
      break;
    case "test":
      options = "-d";
      break;
    default:
      console.error(`Not a command: ${format}.`);
  }

  childProcess.execSync(`shfmt ${options} ${paths}`, { stdio: "inherit" });
}

main();
