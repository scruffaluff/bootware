#!/usr/bin/env sh
#
# Extend ShellCheck to check files in directories.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

#######################################
# Script entrypoint.
#######################################
main() {
  bats_files="$(
    find . -type f -name '*.bats' -not -path '*/.venv/*' \
      -not -path '*/node_modules/*'
  )"
  for file in ${bats_files}; do
    shellcheck --shell bash "${file}"
  done

  sh_files="$(
    find . -type f -name '*.sh' -not -path '*/.venv/*' \
      -not -path '*/node_modules/*'
  )"
  for file in ${sh_files}; do
    shellcheck "${file}"
  done
}

main
