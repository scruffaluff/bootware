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
# Download file to local path.
# Arguments:
#   Super user command for installation.
#   Remote source URL.
#   Local destination path.
#######################################
download() {
  # Flags:
  #   -O <PATH>: Save download to path.
  #   -q: Hide log output.
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ -x "$(command -v curl)" ]; then
    ${1:+"${1}"} curl --fail --location --show-error --silent --output "${3}" \
      "${2}"
  else
    ${1:+"${1}"} wget -q -O "${3}" "${2}"
  fi
}

#######################################
# Print error message and exit script with error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error() {
  bold_red='\033[1;31m' default='\033[0m'
  # Flags:
  #   -t <FD>: Check if file descriptor is a terminal.
  if [ -t 2 ]; then
    printf "${bold_red}error${default}: %s\n" "${1}" >&2
  else
    printf "error: %s\n" "${1}" >&2
  fi
  exit 1
}

#######################################
# Print error message and exit script with usage error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error_usage() {
  bold_red='\033[1;31m' default='\033[0m'
  # Flags:
  #   -t <FD>: Check if file descriptor is a terminal.
  if [ -t 2 ]; then
    printf "${bold_red}error${default}: %s\n" "${1}" >&2
  else
    printf "error: %s\n" "${1}" >&2
  fi
  printf "Run 'install --help' for usage.\n" >&2
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
    error 'Unable to find a command for super user elevation'
  fi
}

#######################################
# Install Bash shell.
# Arguments:
#   Super user command for installation.
#######################################
install_bash() {
  # Do not quote the outer super parameter expansion. Shell will error due to be
  # being unable to find the "" command.
  if [ -x "$(command -v apk)" ]; then
    ${1:+"${1}"} apk update
    ${1:+"${1}"} apk add bash
  elif [ -x "$(command -v apt-get)" ]; then
    ${1:+"${1}"} apt-get update
    ${1:+"${1}"} apt-get install --quiet --yes bash
  elif [ -x "$(command -v dnf)" ]; then
    ${1:+"${1}"} dnf check-update || {
      code="$?"
      [ "${code}" -ne 100 ] && exit "${code}"
    }
    ${1:+"${1}"} dnf install --assumeyes bash
  elif [ -x "$(command -v pacman)" ]; then
    ${1:+"${1}"} pacman --noconfirm --refresh --sync --sysupgrade
    ${1:+"${1}"} pacman --noconfirm --sync bash
  elif [ -x "$(command -v pkg)" ]; then
    ${1:+"${1}"} pkg update
    ${1:+"${1}"} pkg install --yes bash
  elif [ -x "$(command -v zypper)" ]; then
    ${1:+"${1}"} zypper update --no-confirm
    ${1:+"${1}"} zypper install --no-confirm bash
  else
    error 'No supported package manager found to install Bash.'
  fi
}

#######################################
# Install completion scripts for Bootware.
# Arguments:
#   Super user elevation command.
#   Whether to install for entire system.
#   GitHub version reference.
#######################################
install_completions() {
  repo_url="https://raw.githubusercontent.com/scruffaluff/bootware/${3}"
  bash_url="${repo_url}/completions/bootware.bash"
  fish_url="${repo_url}/completions/bootware.fish"

  # Flags:
  #   -z: Check if the string is empty.
  if [ -z "${2:-}" ]; then
    if [ "$(uname -m)" = 'arm64' ]; then
      brew_prefix='/opt/homebrew'
    else
      brew_prefix='/usr/local'
    fi
    os_type="$(uname -s)"

    # Do not use long form --parents flag for mkdir. It is not supported on
    # MacOS.
    if [ "${os_type}" = 'Darwin' ]; then
      ${1:+"${1}"} mkdir -p "${brew_prefix}/share/bash-completion/completions"
      download "${1}" "${bash_url}" "${brew_prefix}/share/bash-completion/completions/bootware"
      ${1:+"${1}"} chmod 644 "${brew_prefix}/share/bash-completion/completions/bootware"

      ${1:+"${1}"} mkdir -p "${brew_prefix}/etc/fish/completions"
      download "${1}" "${fish_url}" "${brew_prefix}/etc/fish/completions/bootware.fish"
      ${1:+"${1}"} chmod 644 "${brew_prefix}/etc/fish/completions/bootware.fish"
    elif [ "${os_type}" = 'FreeBSD' ]; then
      ${1:+"${1}"} mkdir -p '/usr/local/share/bash-completion/completions'
      download "${1}" "${bash_url}" '/usr/local/share/bash-completion/completions/bootware'
      ${1:+"${1}"} chmod 644 '/usr/local/share/bash-completion/completions/bootware'

      ${1:+"${1}"} mkdir -p '/usr/local/etc/fish/completions'
      download "${1}" "${fish_url}" '/usr/local/etc/fish/completions/bootware.fish'
      ${1:+"${1}"} chmod 644 '/usr/local/etc/fish/completions/bootware.fish'
    else
      ${1:+"${1}"} mkdir -p '/usr/share/bash-completion/completions'
      download "${1}" "${bash_url}" '/usr/share/bash-completion/completions/bootware'
      ${1:+"${1}"} chmod 644 '/usr/share/bash-completion/completions/bootware'

      ${1:+"${1}"} mkdir -p '/etc/fish/completions'
      download "${1}" "${fish_url}" '/etc/fish/completions/bootware.fish'
      ${1:+"${1}"} chmod 644 '/etc/fish/completions/bootware.fish'
    fi
  else
    mkdir -p "${HOME}/.local/share/bash-completion/completions"
    download "" "${bash_url}" "${HOME}/.local/share/bash-completion/completions/bootware"
    chmod 644 "${HOME}/.local/share/bash-completion/completions/bootware"

    mkdir -p "${HOME}/.config/fish/completions"
    download "" "${fish_url}" "${HOME}/.config/fish/completions/bootware.fish"
    chmod 644 "${HOME}/.config/fish/completions/bootware.fish"
  fi
}

#######################################
# Install Man pages for Bootware.
# Arguments:
#   Super user command for installation.
#   GitHub version reference.
#######################################
install_man() {
  man_url="https://raw.githubusercontent.com/scruffaluff/bootware/${2}/completions/bootware.man"

  # Do not use long form --parents flag for mkdir. It is not supported on MacOS.
  ${1:+"${1}"} mkdir -p '/usr/local/share/man/man1'
  download "${1}" "${man_url}" '/usr/local/share/man/man1/bootware.1'
  ${1:+"${1}"} chmod 664 '/usr/local/share/man/man1/bootware.1'
}

#######################################
# Print log message to stdout if logging is enabled.
# Globals:
#   INSTALL_NOLOG
# Outputs:
#   Log message to stdout.
#######################################
log() {
  # Log if environment variable is not set.
  #
  # Flags:
  #   -z: Check if the string is empty.
  if [ -z "${INSTALL_NOLOG:-}" ]; then
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

  src_url="https://raw.githubusercontent.com/scruffaluff/bootware/${version}/bootware.sh"

  # Use super user command for system installation if user did not give the
  # --user, does not own the file, and is not root. Do not use long form --user
  # flag for id command. It is not supported on MacOS.
  #
  # Flags:
  #   -u: Print only the user id.
  #   -w: Check if file exists and is writable.
  #   -z: Check if the string is empty.
  if [ -z "${user_install:-}" ] && [ ! -w "${dst_file}" ] &&
    [ "$(id -u)" -ne 0 ]; then
    super="$(find_super)"
    if [ -z "${super:-}" ]; then
      error 'No command found to elevate user.'
    fi
  fi

  # Install Bash shell if necessary.
  #
  # Flags:
  #   -v: Only show file path of command.
  if [ ! -x "$(command -v bash)" ]; then
    install_bash "${super}"
  fi

  dst_dir="$(dirname "${dst_file}")"
  log 'Installing Bootware...'

  # Do not quote the outer super parameter expansion. Shell will error due to be
  # being unable to find the "" command. Do not use long form --parents flag for
  # mkdir. It is not supported on MacOS.
  ${super:+"${super}"} mkdir -p "${dst_dir}"
  download "${super}" "${src_url}" "${dst_file}"
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

  # Install man pages if a system install.
  #
  # Flags:
  #   -z: Check if the string is empty.
  if [ -z "${user_install:-}" ]; then
    install_man "${super}" "${version}"
  fi

  log "Installed $(bootware --version)."
}

# Add ability to selectively skip main function during test suite.
if [ -z "${BATS_SOURCE_ONLY:-}" ]; then
  main "$@"
fi
