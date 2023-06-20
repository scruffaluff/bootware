#!/usr/bin/env bash
#
# Install Bootware for MacOS or Linux systems.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -o: Persist nonzero exit codes through a Bash pipe.
#   -u: Throw an error when an unset variable is encountered.
set -eou pipefail

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
        --debug                 Enable shell debug traces
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
  if [[ ! -x "$(command -v "${1}")" ]]; then
    error "Cannot find required ${1} command on computer."
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
  local export_cmd="export PATH=\"${1}:\$PATH\"" profile shell_name
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
      export_cmd="set --export PATH \"${1}\" \$PATH"
      profile="${HOME}/.config/fish/config.fish"
      ;;
    *)
      error "Shell ${shell_name} is not supported."
      ;;
  esac

  printf "\n# Added by Bootware installer.\n%s\n" "${export_cmd}" \
    >> "${profile}"
}

#######################################
# Print error message and exit script with error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error() {
  local bold_red='\033[1;31m' default='\033[0m'
  printf "${bold_red}error${default}: %s\n" "${1}" >&2
  exit 1
}

#######################################
# Print error message and exit script with usage error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error_usage() {
  local bold_red='\033[1;31m' default='\033[0m'
  printf "${bold_red}error${default}: %s\n" "${1}" >&2
  printf "Run 'bootware --help' for usage.\n" >&2
  exit 2
}

#######################################
# Install completion scripts for Bootware.
# Arguments:
#   Whether to use sudo for installation.
#   Whether to install for entire system.
#   GitHub version reference.
#######################################
install_completions() {
  local repo_url="https://raw.githubusercontent.com/scruffaluff/bootware/${3}"
  local bash_url="${repo_url}/completions/bootware.bash"
  local fish_url="${repo_url}/completions/bootware.fish"

  # Flags:
  #   -z: Check if the string has zero length or is null.
  if [[ -z "${2:-}" ]]; then
    # Do not use long form --parents flag for mkdir. It is not supported on
    # MacOS.
    ${1:+sudo} mkdir -p '/etc/bash_completion.d'
    ${1:+sudo} curl -LSfs "${bash_url}" -o '/etc/bash_completion.d/bootware.bash'
    ${1:+sudo} chmod 664 '/etc/bash_completion.d/bootware.bash'

    ${1:+sudo} mkdir -p '/etc/fish/completions'
    ${1:+sudo} curl -LSfs "${fish_url}" -o '/etc/fish/completions/bootware.fish'
    ${1:+sudo} chmod 664 '/etc/fish/completions/bootware.fish'
  else
    mkdir -p "${HOME}/.config/fish/completions"
    curl -LSfs "${fish_url}" -o "${HOME}/.config/fish/completions/bootware.fish"
    chmod 664 "${HOME}/.config/fish/completions/bootware.fish"
  fi
}

#######################################
# Install Man pages for Bootware.
# Arguments:
#   Whether to use sudo for installation.
#   GitHub version reference.
#######################################
install_man() {
  local man_url="https://raw.githubusercontent.com/scruffaluff/bootware/${2}/bootware.1"

  # Do not use long form --parents flag for mkdir. It is not supported on MacOS.
  ${1:+sudo} mkdir -p '/usr/local/share/man/man1'
  ${1:+sudo} curl -LSfs "${man_url}" -o '/usr/local/share/man/man1/bootware.1'
  ${1:+sudo} chmod 664 '/usr/local/share/man/man1/bootware.1'
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
  if [[ -z "${BOOTWARE_NOLOG:-}" ]]; then
    echo "$@"
  fi
}

#######################################
# Script entrypoint.
#######################################
main() {
  local dst_dir dst_file='/usr/local/bin/bootware' src_url use_sudo='' \
    user_install version='main'

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "${1}" in
      --debug)
        set -o xtrace
        shift 1
        ;;
      -d | --dest)
        dst_file="${2}"
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -u | --user)
        dst_file="${HOME}/.local/bin/bootware"
        user_install='true'
        shift 1
        ;;
      -v | --version)
        version="${2}"
        shift 2
        ;;
      *)
        error_usage "No such option '${1}'."
        ;;
    esac
  done

  assert_cmd curl

  src_url="https://raw.githubusercontent.com/scruffaluff/bootware/${version}/bootware.sh"

  # Use sudo for system installation if user did not give the --user, does not
  # own the file, and is not root.
  #
  # Flags:
  #   -w: Check if file exists and is writable.
  #   -z: Check if the string has zero length or is null.
  if [[ -z "${user_install:-}" && ! -w "${dst_file}" && "${EUID}" -ne 0 ]]; then
    assert_cmd sudo
    use_sudo='true'
  fi
  dst_dir="$(dirname "${dst_file}")"

  log 'Installing Bootware'

  # Do not quote the sudo parameter expansion. Bash will error due to be being
  # unable to find the "" command.
  # Do not use long form --parents flag for mkdir. It is not supported on MacOS.
  ${use_sudo:+sudo} mkdir -p "${dst_dir}"
  ${use_sudo:+sudo} curl -LSfs "${src_url}" --output "${dst_file}"
  ${use_sudo:+sudo} chmod 755 "${dst_file}"

  # Add Bootware to shell profile if not in system path.
  #
  # Flags:
  #   -e: Check if file exists.
  #   -v: Only show file path of command.
  if [[ ! -e "$(command -v bootware)" ]]; then
    configure_shell "${dst_dir}"
    export PATH="${dst_dir}:${PATH}"
  fi

  install_completions "${use_sudo}" "${user_install:-}" "${version}"

  # Installl man pages if a system install.
  #
  # Flags:
  #   -z: Check if the string has zero length or is null.
  if [[ -z "${user_install:-}" ]]; then
    install_man "${use_sudo}" "${version}"
  fi

  log "Installed $(bootware --version)"
}

# Variable BASH_SOURCE cannot be used to load script as a library. Piping the
# script to Bash gives the same BASH_SOURCE result as sourcing the script.
main "$@"
