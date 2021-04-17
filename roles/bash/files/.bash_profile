# Bash settings file for login shells.
# shellcheck disable=SC1090 shell=bash

# Load non-login settings if file exists.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if [[ -f "${HOME}/.bashrc" ]]; then
  source "${HOME}/.bashrc"
fi
