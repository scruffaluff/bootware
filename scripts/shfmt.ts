/**
 * Convenience script for running Shfmt.
 */

const childProcess = require("child_process");

function main(): void {
  const command = process.argv[2];
  let options;
  let paths = "bootware.sh install.sh completions/ roles/";

  switch (command) {
    case "format":
      options = "-w";
      break;
    case "test":
      options = "-d";
      break;
    default:
      console.error(`Not a command: ${command}.`);
      process.exit(2);
  }

  childProcess.execSync(`shfmt ${options} ${paths}`, { stdio: "inherit" });
}

main();
