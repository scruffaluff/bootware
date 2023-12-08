#!/usr/bin/env sh
#
# ShellCheck script to check files in directories.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

#######################################
# Show CLI help information.
# Cannot use function name help, since help is a pre-existing command.
# Outputs:
#   Writes help information to stdout.
#######################################
usage() {
  cat 1>&2 << EOF
ShellCheck script to check files in directories.

Usage: shellcheck [OPTIONS]

Options:
      --debug               Enable shell debug traces
  -h, --help                Print help information
EOF
}

#######################################
# Script entrypoint.
#######################################
main() {
  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      --debug)
        set -o xtrace
        shift 1
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "error: No such subcommand or option '${1}'"
        exit 2
        ;;
    esac
  done

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

main "$@"
