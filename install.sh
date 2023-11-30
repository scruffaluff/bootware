#!/usr/bin/env sh
#
# Install Bootware for FreeBSD, MacOS, or Linux systems.

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
Installer script for Bootware.

Usage: install [OPTIONS]

Options:
      --debug               Enable shell debug traces
  -d, --dest <PATH>         Path to install bootware
  -h, --help                Print help information
  -u, --user                Install bootware for current user
  -v, --version <VERSION>   Version of Bootware to install
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
  if [ ! -x "$(command -v "${1}")" ]; then
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
  export_cmd="export PATH=\"${1}:\$PATH\""
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
      echo "Shell ${shell_name} is not supported for configuration."
      return 0
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
  bold_red='\033[1;31m' default='\033[0m'
  printf "${bold_red}error${default}: %s\n" "${1}" >&2
  exit 1
}

#######################################
# Print error message and exit script with usage error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error_usage() {
  bold_red='\033[1;31m' default='\033[0m'
  printf "${bold_red}error${default}: %s\n" "${1}" >&2
  printf "Run 'bootware --help' for usage.\n" >&2
  exit 2
}

#######################################
# Find command to elevate as super user.
#######################################
find_super() {
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ -x "$(command -v sudo)" ]; then
    echo 'sudo'
  elif [ -x "$(command -v doas)" ]; then
    echo 'doas'
  else
    echo ''
  fi
}

#######################################
# Install completion scripts for Bootware.
# Arguments:
#   Super user command for installation.
#   Whether to install for entire system.
#   GitHub version reference.
#######################################
install_completions() {
  repo_url="https://raw.githubusercontent.com/scruffaluff/bootware/${3}"
  bash_url="${repo_url}/completions/bootware.bash"
  fish_url="${repo_url}/completions/bootware.fish"

  # Flags:
  #   -z: Check if the string has zero length or is null.
  if [ -z "${2:-}" ]; then
    # Do not use long form --parents flag for mkdir. It is not supported on
    # MacOS.
    ${1:+"${1}"} mkdir -p '/etc/bash_completion.d'
    ${1:+"${1}"} curl -LSfs "${bash_url}" -o '/etc/bash_completion.d/bootware.bash'
    ${1:+"${1}"} chmod 664 '/etc/bash_completion.d/bootware.bash'

    ${1:+"${1}"} mkdir -p '/etc/fish/completions'
    ${1:+"${1}"} curl -LSfs "${fish_url}" -o '/etc/fish/completions/bootware.fish'
    ${1:+"${1}"} chmod 664 '/etc/fish/completions/bootware.fish'
  else
    mkdir -p "${HOME}/.config/fish/completions"
    curl -LSfs "${fish_url}" -o "${HOME}/.config/fish/completions/bootware.fish"
    chmod 664 "${HOME}/.config/fish/completions/bootware.fish"
  fi
}

#######################################
# Install Man pages for Bootware.
# Arguments:
#   Super user command for installation.
#   GitHub version reference.
#######################################
install_man() {
  man_url="https://raw.githubusercontent.com/scruffaluff/bootware/${2}/bootware.1"

  # Do not use long form --parents flag for mkdir. It is not supported on MacOS.
  ${1:+"${1}"} mkdir -p '/usr/local/share/man/man1'
  ${1:+"${1}"} curl -LSfs "${man_url}" -o '/usr/local/share/man/man1/bootware.1'
  ${1:+"${1}"} chmod 664 '/usr/local/share/man/man1/bootware.1'
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
  if [ -z "${BOOTWARE_NOLOG:-}" ]; then
    echo "$@"
  fi
}

#######################################
# Script entrypoint.
#######################################
main() {
  dst_file='/usr/local/bin/bootware'
  super=''
  version='main'

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
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

  # Use super user command for system installation if user did not give the
  # --user, does not own the file, and is not root. Do not use long form --user
  # flag for id command. It is not supported on MacOS.
  #
  # Flags:
  #   -u: Print only the user id.
  #   -w: Check if file exists and is writable.
  #   -z: Check if the string has zero length or is null.
  if [ -z "${user_install:-}" ] && [ ! -w "${dst_file}" ] &&
    [ "$(id -u)" -ne 0 ]; then
    super="$(find_super)"
    if [ -z "${super:-}" ]; then
      error 'No command found to elevate user.'
    fi
  fi
  dst_dir="$(dirname "${dst_file}")"

  log 'Installing Bootware...'

  # Do not quote the outer super parameter expansion. Bash will error due to be
  # being unable to find the "" command. Do not use long form --parents flag for
  # mkdir. It is not supported on MacOS.
  ${super:+"${super}"} mkdir -p "${dst_dir}"
  ${super:+"${super}"} curl -LSfs "${src_url}" --output "${dst_file}"
  ${super:+"${super}"} chmod 755 "${dst_file}"

  # Add Bootware to shell profile if not in system path.
  #
  # Flags:
  #   -e: Check if file exists.
  #   -v: Only show file path of command.
  if [ ! -e "$(command -v bootware)" ]; then
    configure_shell "${dst_dir}"
    export PATH="${dst_dir}:${PATH}"
  fi

  install_completions "${super}" "${user_install:-}" "${version}"

  # Installl man pages if a system install.
  #
  # Flags:
  #   -z: Check if the string has zero length or is null.
  if [ -z "${user_install:-}" ]; then
    install_man "${super}" "${version}"
  fi

  log "Installed $(bootware --version)."
}

main "$@"
