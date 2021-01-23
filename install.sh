#!/usr/bin/env bash
#
# Install Bootware for MacOS or Linux systems.
# shellcheck shell=bash
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
  if ! command -v "$1" > /dev/null ; then
    error "Cannot find $1 command on computer. Please install and retry installation."
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
  local _export="export PATH=\"$1:\$PATH\""
  local _profile
  local _shell

  _shell=$(basename "$SHELL")

  case "$_shell" in
    bash)
      _profile="$HOME/.bashrc"
      ;;
    zsh)
      _profile="$HOME/.zshrc"
      ;;
    ksh)
      _profile="$HOME/.profile"
      ;;
    fish)
      _export="set -x PATH \"$1\" \$PATH"
      _profile="$HOME/.config/fish/config.fish"
      ;;
    *)
      error "Shell $_shell is not supported."
      ;;
  esac

  printf "\n# Added by Bootware installer.\n%s\n" "$_export" >> "$_profile"
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
  assert_cmd curl

  local _dest
  local _dest_dir
  local _source
  local _user
  local _version="master"

  # Parse command line arguments.
  for arg in "$@"; do
    case "$arg" in
      -h|--help)
        usage
        exit 0
        ;;
      -d|--dest)
        shift
        _dest="$2"
        ;;
      -u|--user)
        _user=1
        ;;
      -v|--version)
        shift
        _version="$2"
        ;;
      *)
        ;;
    esac
  done

  _source="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/$_version/bootware.sh"
  if [[ "$_user" == 1 ]] ; then
    _dest="$HOME/.local/bin/bootware"
    _sudo=""
  else
    assert_cmd sudo
    _dest="/usr/local/bin/bootware"
    _sudo=sudo
  fi
  _dest_dir=$(dirname "$_dest")

  echo "Installing Bootware..."

  ${_sudo} mkdir -p "$_dest_dir"
  ${_sudo} curl -LSfs "$_source" -o "$_dest"
  ${_sudo} chmod 755 "$_dest"

  if ! command -v bootware > /dev/null; then
    configure_shell "$_dest_dir"
    export PATH="$_dest_dir:$PATH"
  fi

  echo "Installed $(bootware --version)."
}

# Execute main with command line arguments.
main "$@"
