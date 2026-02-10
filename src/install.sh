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
# Outputs:
#   Writes help information to stdout.
#######################################
usage() {
  cat 1>&2 << EOF
Installer script for Bootware.

Usage: install-bootware [OPTIONS]

Options:
      --debug               Show shell debug traces.
  -d, --dest <PATH>         Directory to install Bootware.
  -g, --global              Install Bootware for all users.
  -h, --help                Print help information.
  -p, --preserve-env        Do not update system environment.
  -q, --quiet               Print only error messages.
  -v, --version <VERSION>   Version of Bootware to install.
EOF
}

#######################################
# Add Bootware to system path in shell profile.
# Arguments:
#   Parent directory of Bootware script.
# Globals:
#   SHELL
#######################################
configure_shell() {
  local dst_dir="${1}"
  export_cmd="export PATH=\"${dst_dir}:\${PATH}\""
  shell_name="$(basename "${SHELL:-}")"

  case "${shell_name}" in
    bash)
      profile="${HOME}/.bashrc"
      ;;
    fish)
      export_cmd="set --export PATH \"${dst_dir}\" \$PATH"
      profile="${HOME}/.config/fish/config.fish"
      ;;
    nu)
      export_cmd="\$env.PATH = [\"${dst_dir}\" ...\$env.PATH]"
      if [ "$(uname -s)" = 'Darwin' ]; then
        profile="${HOME}/Library/Application Support/nushell/config.nu"
      else
        profile="${HOME}/.config/nushell/config.nu"
      fi
      ;;
    zsh)
      profile="${HOME}/.zshrc"
      ;;
    *)
      profile="${HOME}/.profile"
      ;;
  esac

  # Create profile parent directory and add export command to profile
  #
  # Flags:
  #   -p: Make parent directories if necessary.
  mkdir -p "$(dirname "${profile}")"
  printf '\n# Added by Bootware installer.\n%s\n' "${export_cmd}" >> "${profile}"
  log "Added '${export_cmd}' to the '${profile}' shell profile."
  log 'Source shell profile or restart shell after installation.'
}

#######################################
# Perform network request.
#######################################
fetch() {
  local dst_file='-' mode='' super='' url=''

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -d | --dest)
        dst_file="${2}"
        shift 2
        ;;
      -m | --mode)
        mode="${2}"
        shift 2
        ;;
      -s | --super)
        super="${2}"
        shift 2
        ;;
      *)
        url="${1}"
        shift 1
        ;;
    esac
  done

  # Create parent directory if it does not exist.
  #
  # Flags:
  #   -p: Make parent directories if necessary.
  if [ "${dst_file}" != '-' ]; then
    ${super:+"${super}"} mkdir -p "$(dirname "${dst_file}")"
  fi

  # Download with Curl or Wget.
  #
  # Flags:
  #   -O <PATH>: Save download to path.
  #   -q: Hide log output.
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if command -v curl > /dev/null 2>&1; then
    ${super:+"${super}"} curl --fail --location --show-error --silent --output \
      "${dst_file}" "${url}"
  elif command -v wget > /dev/null 2>&1; then
    ${super:+"${super}"} wget -q -O "${dst_file}" "${url}"
  else
    log --stderr 'error: Unable to find a network file downloader.'
    log --stderr 'Install curl, https://curl.se, manually before continuing.'
    exit 1
  fi

  # Change file permissions if chmod parameter was passed.
  #
  # Flags:
  #   -n: Check if string has nonzero length.
  if [ -n "${mode:-}" ]; then
    ${super:+"${super}"} chmod "${mode}" "${dst_file}"
  fi
}

#######################################
# Find command to elevate as super user.
# Outputs:
#   Super user command.
#######################################
find_super() {
  # Do not use long form flags for id. They are not supported on some systems.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ "$(id -u)" -eq 0 ]; then
    echo ''
  elif command -v doas > /dev/null 2>&1; then
    echo 'doas'
  elif command -v sudo > /dev/null 2>&1; then
    echo 'sudo'
  else
    log --stderr 'error: Unable to find a command for super user elevation.'
    exit 1
  fi
}

#######################################
# Download and install Bootware.
# Arguments:
#   Super user command for installation.
#   Whether to install for all users.
#   Bootware version.
#   Destination path.
#   Whether to update system environment.
#######################################
install_bootware() {
  local super="${1}" global_="${2}" version="${3}" dst_dir="${4}" \
    preserve_env="${5}"
  local repo="https://raw.githubusercontent.com/scruffaluff/bootware/${version}"

  log "Installing Bootware to '${dst_dir}/bootware'."
  fetch --dest "${dst_dir}/bootware" --mode 755 --super "${super}" \
    "${repo}/src/bootware.sh"

  install_completions "${super}" "${global_}" "${repo}"

  # Update shell profile if destination is not in system path.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [ -z "${preserve_env}" ]; then
    case ":${PATH:-}:" in
      *:${dst_dir}:*) ;;
      *)
        configure_shell "${dst_dir}"
        ;;
    esac
  fi

  export PATH="${dst_dir}:${PATH}"
  log "Installed $(bootware --version)."
}

#######################################
# Install completion scripts for Bootware.
# Arguments:
#   Super user command for installation.
#   Whether to install for entire system.
#   Bootware repository.
#######################################
install_completions() {
  local super="${1}" global_="${2}" repo="${3}"
  local arch='' brew_prefix='' os=''
  local bash_url="${repo}/src/completion/bootware.bash"
  local fish_url="${repo}/src/completion/bootware.fish"

  # Flags:
  #   -n: Check if string has nonzero length.
  if [ -n "${global_}" ]; then
    os="$(uname -s)"

    if [ "${os}" = 'Darwin' ]; then
      arch="$(uname -m | sed 's/aarch64/arm64/')"
      if [ "${arch}" = 'arm64' ]; then
        brew_prefix='/opt/homebrew'
      else
        brew_prefix='/usr/local'
      fi

      fetch --dest "${brew_prefix}/share/bash-completion/completions/bootware" \
        --mode 644 --super "${super}" "${bash_url}"
      fetch --dest "${brew_prefix}/etc/fish/completions/bootware.fish" \
        --mode 644 --super "${super}" "${fish_url}"
    elif [ "${os}" = 'FreeBSD' ]; then
      fetch --dest '/usr/local/share/bash-completion/completions/bootware' \
        --mode 644 --super "${super}" "${bash_url}"
      fetch --dest '/usr/local/etc/fish/completions/bootware.fish' \
        --mode 644 --super "${super}" "${fish_url}"
    else
      fetch --dest '/usr/share/bash-completion/completions/bootware' \
        --mode 644 --super "${super}" "${bash_url}"
      fetch --dest '/etc/fish/completions/bootware.fish' --mode 644 \
        --super "${super}" "${fish_url}"
    fi

    fetch --dest '/usr/local/share/man/man1/bootware.1' --mode 644 \
      --super "${super}" "${repo}/src/completion/bootware.man"
  else
    fetch --dest "${HOME}/.local/share/bash-completion/completions/bootware" \
      --mode 644 "${bash_url}"
    fetch --dest "${HOME}/.config/fish/completions/bootware.fish" \
      --mode 644 "${fish_url}"
  fi
}

#######################################
# Print message if error or logging is enabled.
# Arguments:
#   Message to print.
# Globals:
#   BOOTWARE_NOLOG
# Outputs:
#   Message argument.
#######################################
log() {
  local file='1' newline="\n" text=''

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -e | --stderr)
        file='2'
        shift 1
        ;;
      -n | --no-newline)
        newline=''
        shift 1
        ;;
      *)
        text="${text}${1}"
        shift 1
        ;;
    esac
  done

  # Print if error or using quiet configuration.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [ -z "${BOOTWARE_NOLOG:-}" ] || [ "${file}" = '2' ]; then
    printf "%s${newline}" "${text}" >&"${file}"
  fi
}

#######################################
# Script entrypoint.
#######################################
main() {
  local dst_dir='' global_='' preserve_env='' super='' version='main'

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      --debug)
        set -o xtrace
        shift 1
        ;;
      -d | --dest)
        dst_dir="${2}"
        shift 2
        ;;
      -g | --global)
        dst_dir="${dst_dir:-/usr/local/bin}"
        global_='true'
        shift 1
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -p | --preserve-env)
        preserve_env='true'
        shift 1
        ;;
      -q | --quiet)
        export BOOTWARE_NOLOG='true'
        shift 1
        ;;
      -v | --version)
        version="${2}"
        shift 2
        ;;
      *)
        log --stderr "error: No such option '${1}'."
        log --stderr "Run 'install-bootware --help' for usage."
        exit 2
        ;;
    esac
  done

  # Choose destination if not selected.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [ -z "${dst_dir}" ]; then
    if [ "$(id -u)" -eq 0 ]; then
      global_='true'
      dst_dir='/usr/local/bin'
    else
      dst_dir="${HOME}/.local/bin"
    fi
  fi

  # Find super user command if destination is not writable.
  #
  # Flags:
  #   -n: Check if string has nonzero length.
  #   -p: Make parent directories if necessary.
  #   -w: Check if file exists and is writable.
  if [ -n "${global_}" ] || ! mkdir -p "${dst_dir}" > /dev/null 2>&1 ||
    [ ! -w "${dst_dir}" ]; then
    global_='true'
    super="$(find_super)"
  fi

  install_bootware "${super}" "${global_}" "${version}" "${dst_dir}" \
    "${preserve_env}"
}

# Add ability to selectively skip main function during test suite.
if [ -z "${BATS_SOURCE_ONLY:-}" ]; then
  main "$@"
fi
