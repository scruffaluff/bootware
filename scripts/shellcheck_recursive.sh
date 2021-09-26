#!/usr/bin/env bash
#
# Extend ShellCheck to check files in directories.

#######################################
# Script entrypoint.
#######################################
main() {
  files="$(find . -type f -name '.bash_profile' -o -name '.bashrc' -o -name '*.bats' -o -name '*.sh')";

  for file in ${files}; do
    shellcheck "${file}"
  done
}

main
