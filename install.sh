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
    cat 1>&2 <<EOF
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
  if ! command -v "$1" > /dev/null; then
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

  shell_name=$(basename "${SHELL}")

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
#   Writes error message to stderr if command is not in system path.
#######################################
error() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

#######################################
# Script entrypoint.
#######################################
main() {
  local arg
  local dst_dir
  local dst_file="/usr/local/bin/bootware"
  local src_url
  local use_sudo
  local user_install
  local version="master"

  assert_cmd curl

  # Parse command line arguments.
  for arg in "$@"; do
    case "${arg}" in
      -h|--help)
        usage
        exit 0
        ;;
      -d|--dest)
        shift
        dst_file="$2"
        ;;
      -u|--user)
        dst_file="${HOME}/.local/bin/bootware"
        user_install=1
        ;;
      -v|--version)
        shift
        version="$2"
        ;;
      *)
        ;;
    esac
  done

  src_url="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/${version}/bootware.sh"

  # Use sudo for system installation if user did not give the --user, does not
  # own the file, and is not root.
  #
  # Flags: 
  #   -O: True if file is owned by the current user.
  if [[ -z ${user_install} && ! -O "${dst_file}" && ${EUID} != 0 ]]; then
    assert_cmd sudo
    use_sudo=1
  fi
  dst_dir=$(dirname "${dst_file}")

  echo "Installing Bootware..."

  ${use_sudo:+sudo} mkdir -p "${dst_dir}"
  ${use_sudo:+sudo} curl -LSfs "${src_url}" -o "${dst_file}"
  ${use_sudo:+sudo} chmod 755 "${dst_file}"

  # Add Bootware to shell profile if not in system path.
  #
  # Flags:
  #   -v: Only show file path of command.
  if ! command -v bootware > /dev/null; then
    configure_shell "${dst_dir}"
    export PATH="${dst_dir}:${PATH}"
  fi

  echo "Installed $(bootware --version)."
}

main "$@"
