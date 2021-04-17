#!/usr/bin/env bash
#
# Install Bootware for MacOS or Linux systems.

# Exit immediately if a command exists with a non-zero status.
set -e

#######################################
# Show CLI help information.
# Cannot use function name help, since help is a pre-existing command.
# Outputs:
#   Writes help information to stdout.
#######################################
usage() {
  cat 1>&2 << EOF
Bootware Installer
Installer script for Bootware

USAGE:
    bootware-installer [OPTIONS]

OPTIONS:
    -d, --dest <PATH>           Path to install bootware
    -h, --help                  Print help information
    -u, --user                  Install bootware for current user
    -v, --version <VERSION>     Version of Bootware to install
EOF
}

#######################################
# Assert that command can be found in system path.
# Will exit script with an error code if command is not in system path.
# Arguments:
#   Command to check availabilty.
# Outputs:
#   Writes error message to stderr if command is not in system path.
#######################################
assert_cmd() {
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v "$1")" ]]; then
    error "Cannot find required $1 command on computer."
  fi
}

#######################################
# Add Bootware to system path in user's shell profile.
# Globals:
#   HOME
#   PATH
#   SHELL
# Arguments:
#   Parent directory of Bootware script.
#######################################
configure_shell() {
  local export_cmd="export PATH=\"$1:\$PATH\""
  local profile
  local shell_name

  shell_name="$(basename "${SHELL}")"

  case "${shell_name}" in
    bash)
      profile="${HOME}/.bashrc"
      ;;
    zsh)
      profile="${HOME}/.zshrc"
      ;;
    ksh)
      profile="${HOME}/.profile"
      ;;
    fish)
      export_cmd="set -x PATH \"$1\" \$PATH"
      profile="${HOME}/.config/fish/config.fish"
      ;;
    *)
      error "Shell ${shell_name} is not supported."
      ;;
  esac

  printf "\n# Added by Bootware installer.\n%s\n" "${export_cmd}" >> "${profile}"
}

#######################################
# Print error message and exit script with error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error() {
  local bold_red="\033[1;31m"
  local default="\033[0m"

  printf "${bold_red}error${default}: %s\n" "$1" >&2
  exit 1
}

#######################################
# Print error message and exit script with usage error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error_usage() {
  local bold_red="\033[1;31m"
  local default="\033[0m"

  printf "${bold_red}error${default}: %s\n" "$1" >&2
  printf "Run 'bootware --help' for usage.\n" >&2
  exit 2
}

#######################################
# Print log message to stdout if logging is enabled.
# Globals:
#   BOOTWARE_NOLOG
# Outputs:
#   Log message to stdout.
#######################################
log() {
  # Log if environment variable is not set.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${BOOTWARE_NOLOG}" ]]; then
    echo "$@"
  fi
}

#######################################
# Script entrypoint.
#######################################
main() {
  local dst_dir
  local dst_file="/usr/local/bin/bootware"
  local src_url
  local use_sudo
  local user_install
  local version="master"

  assert_cmd curl

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d | --dest)
        dst_file="$2"
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -u | --user)
        dst_file="${HOME}/.local/bin/bootware"
        user_install=1
        shift 2
        ;;
      -v | --version)
        version="$2"
        shift 2
        ;;
      *)
        error_usage "No such option '$1'."
        ;;
    esac
  done

  src_url="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/${version}/bootware.sh"

  # Use sudo for system installation if user did not give the --user, does not
  # own the file, and is not root.
  #
  # Flags:
  #   -w: Check if file exists and is writable.
  #   -z: Check if the string has zero length or is null.
  if [[ -z "${user_install}" && ! -w "${dst_file}" && "${EUID}" -ne 0 ]]; then
    assert_cmd sudo
    use_sudo=1
  fi
  dst_dir="$(dirname "${dst_file}")"

  printf "Installing Bootware\n"

  "${use_sudo:+sudo}" mkdir -p "${dst_dir}"
  "${use_sudo:+sudo}" curl -LSfs "${src_url}" -o "${dst_file}"
  "${use_sudo:+sudo}" chmod 755 "${dst_file}"

  # Add Bootware to shell profile if not in system path.
  #
  # Flags:
  #   -e: Check if file exists.
  #   -v: Only show file path of command.
  if [[ ! -e "$(command -v bootware)" ]]; then
    configure_shell "${dst_dir}"
    export PATH="${dst_dir}:${PATH}"
  fi

  # Installl man pages if a system install.
  #
  # Flags:
  #   -n: Check if the string has nonzero length.
  if [[ -n "${use_sudo}" ]]; then
    man_url="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/${version}/bootware.1"
    sudo mkdir -p "/usr/local/share/man/man1"
    sudo curl -LSfs "${man_url}" -o "/usr/local/share/man/man1/bootware.1"
  fi

  printf "Installed %s\n" "$(bootware --version)"
}

# Only run main if invoked as script. Otherwise import functions as library.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
