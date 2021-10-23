#!/usr/bin/env bash
#
# Extend ShellCheck to check files in directories.

#######################################
# Script entrypoint.
#######################################
main() {
  bats_files="$(find . -type f -name '*.bats' -not -path '*/node_modules/*')";
  for file in ${bats_files}; do
    shellcheck "${file}"
  done

  sh_files="$(find . -type f -name '*.sh' -not -path '*/node_modules/*')";
  for file in ${sh_files}; do
    shellcheck "${file}"
  done
}

main
