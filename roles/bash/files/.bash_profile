# Bash settings file for login shells.
# shellcheck disable=SC1090,SC1091 shell=bash
#
# For more information, visit
# https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html.

# Load non-login settings if file exists.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if [[ -f "${HOME}/.bashrc" ]]; then
  source "${HOME}/.bashrc"
fi
