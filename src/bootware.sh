#!/usr/bin/env sh
#
# Bootstrap software installations with Ansible.

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
  case "${1}" in
    bootstrap)
      cat 1>&2 << EOF
Bootstrap install computer software.

Usage: bootware bootstrap [OPTIONS]

Options:
      --check                     Perform dry run and show possible changes
      --checkout <REF>            Git reference to run against
  -c, --config <PATH>             Path to bootware user configuration file
      --debug                     Enable Ansible task debugger
  -d, --dev                       Run bootstrapping in development mode
  -h, --help                      Print help information
      --install-group <GROUP>     Remote group to install software for
      --install-user <USER>       Remote user to install software for
  -i, --inventory <IP-LIST>       Ansible remote hosts IP addresses
      --no-passwd                 Do not ask for user password
      --no-setup                  Skip Bootware dependency installation
      --password <PASSWORD>       Remote user login password
  -p, --playbook <FILE>           Path to playbook to execute
      --port <INTEGER>            Port for SSH connection
      --private-key <FILE>        Path to SSH private key
      --retries <INTEGER>         Playbook retry limit during failure
  -s, --skip <TAG-LIST>           Ansible playbook tags to skip
      --start-at-role <ROLE>      Begin execution with role
  -t, --tags <TAG-LIST>           Ansible playbook tags to select
      --temp-key <FILE>           Path to SSH private key for one time connection
  -u, --url <URL>                 URL of playbook repository
      --user <USER>               Remote user login name
EOF
      if [ -x "$(command -v ansible)" ]; then
        printf '\nAnsible Options:\n'
        ansible --help
      fi
      ;;
    config)
      cat 1>&2 << EOF
Download default Bootware configuration file.

Usage: bootware config [OPTIONS]

Options:
  -d, --dest <PATH>     Path to alternate download destination
  -e, --empty           Write empty configuration file
  -h, --help            Print help information
  -s, --source <URL>    URL to configuration file
EOF
      ;;
    main)
      cat 1>&2 << EOF
Bootstrapping software installer.

Usage: bootware [OPTIONS] <SUBCOMMAND>

Options:
      --debug     Enable shell debug traces
  -h, --help      Print help information
  -v, --version   Print version information

Subcommands:
  bootstrap   Bootstrap install computer software
  config      Generate Bootware configuration file
  roles       List all Bootware roles
  setup       Install dependencies for Bootware
  uninstall   Remove Bootware files
  update      Update Bootware to latest version

Environment Variables:
  BOOTWARE_CONFIG         Set the configuration file path
  BOOTWARE_GITHUB_TOKEN   GitHub API authentication token
  BOOTWARE_NOLOG          Silence log messages
  BOOTWARE_NOPASSWD       Assume password less doas or sudo
  BOOTWARE_NOSETUP        Skip Ansible install and system setup
  BOOTWARE_PLAYBOOK       Set Ansible playbook name
  BOOTWARE_SKIP           Set skip tags for Ansible roles
  BOOTWARE_TAGS           Set tags for Ansible roles
  BOOTWARE_URL            Set location of Ansible repository

Run 'bootware <subcommand> --help' for usage on a subcommand.
EOF
      ;;
    roles)
      cat 1>&2 << EOF
List all Bootware roles.

Usage: bootware roles [OPTIONS]

Options:
  -h, --help              Print help information
  -t, --tags <TAG-LIST>   Ansible playbook tags to select
  -u, --url <URL>         URL of playbook repository
EOF
      ;;
    setup)
      cat 1>&2 << EOF
Install dependencies for Bootware.

Usage: bootware setup [OPTIONS]

Options:
  -h, --help    Print help information
EOF
      ;;
    uninstall)
      cat 1>&2 << EOF
Remove Bootware files.

Usage: bootware uninstall

Options:
  -h, --help    Print help information
EOF
      ;;
    update)
      cat 1>&2 << EOF
Update Bootware to latest version.

Usage: bootware update [OPTIONS]

Options:
  -h, --help                Print help information
  -v, --version <VERSION>   Version override for update
EOF
      ;;
    *)
      log --stderr "No such usage option '${1}'."
      exit 1
      ;;
  esac
}

#######################################
# Subcommand to bootstrap software installations.
# Globals:
#   BOOTWARE_CONFIG
#   BOOTWARE_NOPASSWD
#   BOOTWARE_NOSETUP
#   BOOTWARE_PLAYBOOK
#   BOOTWARE_SKIP
#   BOOTWARE_TAGS
#   BOOTWARE_URL
#######################################
bootstrap() {
  # /dev/null is never a normal file.
  local ansible_config_path
  local ask_passwd
  local become_method
  local cmd='pull'
  local config_path="${BOOTWARE_CONFIG:-'/dev/null'}"
  local connection='local'
  local arg_idx=0
  local install_group
  local install_user
  local inventory='127.0.0.1,'
  local no_setup="${BOOTWARE_NOSETUP:-}"
  local passwd
  local playbook
  local port
  local retries=1
  local skip="${BOOTWARE_SKIP:-}"
  local start_role
  local status
  local tags="${BOOTWARE_TAGS:-}"
  local temp_ssh_args='-o IdentitiesOnly=yes -o LogLevel=ERROR \
-o PreferredAuthentications=publickey,password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null'
  local url="${BOOTWARE_URL:-https://github.com/scruffaluff/bootware.git}"

  # Check if Ansible should ask for user password.
  #
  # Flags:
  #   -z: Check if the string is empty.
  if [ -z "${BOOTWARE_NOPASSWD:-}" ]; then
    ask_passwd='true'
  fi

  # Parse command line arguments.
  while [ "${#}" -gt 0 ] && [ "${arg_idx}" -lt "${#}" ]; do
    case "${1}" in
      --ansible-config)
        export ANSIBLE_CONFIG="${2}"
        shift 2
        ;;
      --become-method)
        become_method="${2}"
        shift 2
        ;;
      -c | --config)
        config_path="${2}"
        shift 2
        ;;
      -d | --dev)
        cmd='playbook'
        playbook="${BOOTWARE_PLAYBOOK:-playbook.yaml}"
        shift 1
        ;;
      --debug)
        export ANSIBLE_ENABLE_TASK_DEBUGGER='True'
        shift 1
        ;;
      -h | --help)
        usage 'bootstrap'
        exit 0
        ;;
      -i | --inventory)
        cmd='playbook'
        connection='ssh'
        inventory="${2}"
        shift 2
        ;;
      --install-group)
        install_group="${2}"
        shift 2
        ;;
      --install-user)
        install_user="${2}"
        shift 2
        ;;
      --no-passwd)
        ask_passwd=''
        shift 1
        ;;
      --no-setup)
        no_setup='true'
        shift 1
        ;;
      -p | --playbook)
        playbook="${2}"
        shift 2
        ;;
      --password)
        passwd="${2}"
        shift 2
        ;;
      --port)
        port="${2}"
        shift 2
        ;;
      --retries)
        retries=${2}
        shift 2
        ;;
      -s | --skip)
        skip="${2}"
        shift 2
        ;;
      --start-at-role)
        start_role="${2}"
        cmd='playbook'
        shift 2
        ;;
      -t | --tags)
        tags="${2}"
        shift 2
        ;;
      --temp-key)
        set -- "$@" --private-key "${2}" --ssh-extra-args "${temp_ssh_args}"
        shift 2
        arg_idx="$((arg_idx + 4))"
        ;;
      -u | --url)
        url="${2}"
        shift 2
        ;;
      *)
        set -- "$@" "${1}"
        shift 1
        arg_idx="$((arg_idx + 1))"
        ;;
    esac
  done

  # Check if Bootware setup should be run.
  #
  # Flags:
  #   -z: Check if the string is empty.
  if [ -z "${no_setup:-}" ]; then
    setup
  fi

  # Download repository if no playbook is selected.
  #
  # Flags:
  #   -z: Check if the string is empty.
  if [ "${cmd}" = 'playbook' ] && [ -z "${playbook:-}" ]; then
    # Do not use long form flags for mktemp. They are not supported on some
    # systems.
    tmp_dir="$(mktemp -u)"
    git clone --depth 1 "${url}" "${tmp_dir}" > /dev/null 2>&1
    playbook="${tmp_dir}/playbook.yaml"
  fi

  # Find task associated with start role.
  #
  # Flags:
  #   -n: Check if string is nonempty.
  if [ -n "${start_role:-}" ]; then
    start_task="$(
      yq --exit-status \
        ".[0].tasks[] | select(.\"ansible.builtin.include_role\".name == \"scruffaluff.bootware.${start_role}\") | .name" \
        "${playbook}"
    )"
    set -- "$@" '--extra-vars' 'connect_role_executed=false' '--start-at-task' \
      "${start_task}"
  fi

  # Convenience logic for using a single host without a trailing comma.
  case "${inventory}" in
    *,*) ;;
    *)
      inventory="${inventory},"
      ;;
  esac

  if [ "${cmd}" = 'playbook' ]; then
    ansible_config_path="$(dirname "${playbook}")/ansible.cfg"
    if [ -z "${ANSIBLE_CONFIG:-}" ] && [ -f "${ansible_config_path}" ]; then
      export ANSIBLE_CONFIG="${ansible_config_path}"
    fi
    set -- "$@" '--connection' "${connection}"
  elif [ "${cmd}" = 'pull' ]; then
    playbook="${BOOTWARE_PLAYBOOK:-playbook.yaml}"
    set -- "$@" '--url' "${url}"
  fi

  find_config_path "${config_path}"
  config_path="${RET_VAL}"

  log "Executing Ansible ${cmd}."
  if [ -n "${ask_passwd:-}" ]; then
    log 'Enter your user account password when prompted.'
  fi

  # Do not quote extra_args. Otherwise extra_args will be interpreted as a
  # single argument.
  # shellcheck disable=SC2086
  until "ansible-${cmd}" \
    ${ask_passwd:+--ask-become-pass} \
    ${checkout:+--checkout "${checkout}"} \
    --extra-vars "@${config_path}" \
    ${become_method:+--extra-vars "ansible_become_method=${become_method}"} \
    ${passwd:+--extra-vars "ansible_password=${passwd}"} \
    --extra-vars 'ansible_pipelining=false' \
    --extra-vars 'ansible_python_interpreter=auto_silent' \
    ${port:+--extra-vars "ansible_ssh_port=${port}"} \
    ${install_group:+--extra-vars "group_id=${install_group}"} \
    ${install_user:+--extra-vars "user_id=${install_user}"} \
    --inventory "${inventory}" \
    ${tags:+--tags "${tags}"} \
    ${skip:+--skip-tags "${skip}"} \
    "$@" \
    "${playbook}"; do

    status=$?
    retries="$((retries - 1))"
    if [ "${retries}" -eq 0 ]; then
      exit "${status}"
    fi
    printf "\nBootstrapping attempt failed with exit code %s." "${status}"
    printf "\nRetrying bootstrapping with %s attempts left.\n" "${retries}"
    sleep 4
  done
}

#######################################
# Subcommand to generate or download Bootware configuration file.
# Outputs:
#   Writes status information to stdout.
#######################################
config() {
  local src_url dst_file="${HOME}/.bootware/config.yaml" empty_cfg

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -d | --dest)
        dst_file="${2}"
        shift 2
        ;;
      -e | --empty)
        empty_cfg='true'
        shift 1
        ;;
      -h | --help)
        usage 'config'
        exit 0
        ;;
      -s | --source)
        src_url="${2}"
        shift 2
        ;;
      *)
        log --stderr "error: No such option '${1}'."
        log --stderr "Run 'bootware config --help' for usage."
        exit 2
        ;;
    esac
  done

  # Do not use long form flags for mkdir. They are not supported on some
  # systems.
  mkdir -p "$(dirname "${dst_file}")"

  # Check if empty configuration file should be generated.
  #
  # Flags:
  #   -z: Check if the string is empty.
  if [ "${empty_cfg:-}" = 'true' ] || [ -z "${src_url:-}" ]; then
    log "Writing empty configuration file to ${dst_file}."
    printf 'super_passwordless: false' > "${dst_file}"
  else
    log "Downloading configuration file to ${dst_file}."
    fetch --dest "${dst_file}" "${src_url}"
  fi
}

#######################################
# Update dnf package lists.
#
# DNF's check-update command will give a 100 exit code if there are packages
# available to update. Thus both 0 and 100 must be treated as successful exit
# codes.
#
# Arguments:
#   Super user elevation command.
#######################################
dnf_check_update() {
  local code super="${1:-}"
  ${super:+"${super}"} dnf check-update || {
    code="$?"
    [ "${code}" -eq 100 ] && return 0
    return "${code}"
  }
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
  if [ -x "$(command -v curl)" ]; then
    ${super:+"${super}"} curl --fail --location --show-error --silent --output \
      "${dst_file}" "${url}"
  elif [ -x "$(command -v wget)" ]; then
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
# Find path of Bootware configuration file.
# Arguments:
#   User supplied configuration path.
# Outputs:
#   Writes error message to stderr if unable to find configuration file.
# Returns:
#   Configuration file path.
#######################################
find_config_path() {
  local path="${1:-}"

  # Flags:
  #   -f: Check if file exists and is a regular file.
  #   -n: Check if string is nonempty.
  #   -v: Only show file path of command.
  if [ -f "${path}" ]; then
    RET_VAL="${path}"
  elif [ -n "${BOOTWARE_CONFIG:-}" ]; then
    RET_VAL="${BOOTWARE_CONFIG}"
  elif [ -f "${HOME}/.bootware/config.yaml" ]; then
    RET_VAL="${HOME}/.bootware/config.yaml"
  else
    log 'Unable to find Bootware configuration file.'
    config --empty
    RET_VAL="${HOME}/.bootware/config.yaml"
  fi

  log "Using ${RET_VAL} as configuration file."
}

#######################################
# Find command to elevate as super user.
#######################################
find_super() {
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ -x "$(command -v doas)" ]; then
    echo 'doas'
  elif [ -x "$(command -v sudo)" ]; then
    echo 'sudo'
  else
    log --stderr 'Unable to find a command for super user elevation.'
    exit 1
  fi
}

#######################################
# Get full normalized path for file.
#
# Alternative to realpath command, since it is not built into MacOS.
#
# Arguments:
#   File system path.
# Outputs:
#   Full file system path.
#######################################
fullpath() {
  local path="${1}" working_dir
  working_dir="$(cd "$(dirname "${path}")" && pwd)"
  echo "${working_dir}/$(basename "${path}")"
}

#######################################
# Install Yq parser for YAML files.
# Arguments:
#   Super user elevation command.
#######################################
install_yq() {
  local arch os url super="${1:-}" version

  # Do not use long form flags for uname. They are not supported on some
  # systems.
  arch="$(uname -m | sed 's/x86_64/amd64/;s/x64/amd64/;s/aarch64/arm64/')"
  os="$(uname -s)"

  # Get latest Yq version.
  #
  # Flags:
  #   -L: Follow redirect request.
  #   -S: Show errors.
  #   -f: Fail silently on server errors.
  #   -o <FILE>: Save output to file.
  #   -s: Disable progress bars.
  version="$(
    fetch https://formulae.brew.sh/api/formula/yq.json |
      jq --exit-status --raw-output .versions.stable
  )"
  url="https://github.com/mikefarah/yq/releases/download/v${version}/yq_${os}_${arch}"
  fetch --dest /usr/local/bin/yq --mode 755 --super "${super}" "${url}"
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
# Subcommand to list all Bootware roles.
#######################################
roles() {
  local repo_dir
  local skip=''
  local tags=''
  local url="${BOOTWARE_URL:-https://github.com/scruffaluff/bootware.git}"

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -h | --help)
        usage 'roles'
        exit 0
        ;;
      -s | --skip)
        skip="${2}"
        shift 2
        ;;
      -t | --tags)
        tags="${2}"
        shift 2
        ;;
      -u | --url)
        url="${2}"
        shift 2
        ;;
      *)
        log --stderr "error: No such option '${1}'."
        log --stderr "Run 'bootware roles --help' for usage."
        exit 2
        ;;
    esac
  done

  # Do not use long form flags for mkdir. They are not supported on some
  # systems.
  #
  # Flags:
  #   -d: Check if path is a directory.
  mkdir -p "${HOME}/.cache/bootware"
  repo_dir="${HOME}/.cache/bootware/repo"

  # Update repository if more than a day since last modification.
  if [ ! -d "${repo_dir}" ] ||
    [ "$(($(date +%s) - $(stat -c %Y "${repo_dir}")))" -gt 86400 ]; then
    rm -fr "${repo_dir}"
    git clone --depth 1 "${url}" "${repo_dir}" > /dev/null 2>&1
  fi

  case "${tags}," in
    *all,*)
      contains="((map(. != \"never\") | all) or (map(. == \"$(echo "${tags}" | sed 's/,/\") | any) or (map(. == \"/g')\") | any))"
      ;;
    *)
      contains="(map(. == \"$(echo "${tags}" | sed 's/,/\") | any) or (map(. == \"/g')\") | any)"
      ;;
  esac
  rejects="(map(. != \"$(echo "${skip}" | sed 's/,/\") | all) and (map(. != \"/g')\") | all)"

  # Flags:
  #   -n: Check if string is nonempty.
  if [ -n "${skip}" ] && [ -n "${tags}" ]; then
    filter=".[0].tasks[] | select(.tags | ((${contains}) and (${rejects})))"
  elif [ -n "${skip}" ]; then
    filter=".[0].tasks[] | select(.tags | ${rejects})"
  elif [ -n "${tags}" ]; then
    filter=".[0].tasks[] | select(.tags | ${contains})"
  else
    filter='.[0].tasks[] | select(.tags | (map(. != "never") | all))'
  fi

  format='."ansible.builtin.include_role".name  | sub("scruffaluff.bootware.", "")'
  yq "${filter} | ${format}" "${repo_dir}/playbook.yaml"
}

#######################################
# Subcommand to configure bootstrapping services and utilities.
#######################################
setup() {
  local collections collection_status os tmp_dir super=''

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -h | --help)
        usage 'setup'
        exit 0
        ;;
      *)
        log --stderr "error: No such option '${1}'."
        log --stderr "Run 'bootware setup --help' for usage."
        exit 2
        ;;
    esac
  done

  # Check if user is not root.
  if [ "$(id -u)" -ne 0 ]; then
    super="$(find_super)"
  fi

  # Do not use long form flags for uname. They are not supported on some
  # systems.
  os="$(uname -s)"
  case "${os}" in
    Darwin)
      setup_macos
      ;;
    FreeBSD)
      setup_freebsd "${super}"
      ;;
    Linux)
      setup_linux "${super}"
      ;;
    *)
      log --stderr "Operating system '${os}' is not supported."
      exit 1
      ;;
  esac

  collections='chocolatey.chocolatey community.general community.windows'
  for collection in ${collections}; do
    collection_status="$(ansible-galaxy collection list "${collection}" 2>&1)"
    case "${collection_status}" in
      *'unable to find'*)
        ansible-galaxy collection install "${collection}"
        ;;
      *) ;;
    esac
  done
}

#######################################
# Configure bootstrapping services and utilities for Alpine.
# Arguments:
#   Super user elevation command.
#######################################
setup_alpine() {
  local super="${1:-}"

  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ ! -x "$(command -v ansible)" ]; then
    log 'Installing Ansible.'
    ${super:+"${super}"} apk update
    ${super:+"${super}"} apk add ansible
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v curl)" ]; then
    log 'Installing Curl.'
    ${super:+"${super}"} apk update
    ${super:+"${super}"} apk add curl
    log "Installed $(curl --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    ${super:+"${super}"} apk update
    ${super:+"${super}"} apk add git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    ${super:+"${super}"} apk update
    ${super:+"${super}"} apk add jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    install_yq "${1}"
    log "Installed $(yq --version)."
  fi
}

#######################################
# Configure bootstrapping services and utilities for Arch.
# Arguments:
#   Super user elevation command.
#######################################
setup_arch() {
  local super="${1:-}" tmp_dir

  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ ! -x "$(command -v ansible)" ]; then
    log 'Installing Ansible.'
    # Installing Ansible via Python causes pacman conflicts with AWS CLI.
    ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
    ${super:+"${super}"} pacman --noconfirm --sync ansible
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v curl)" ]; then
    log 'Installing Curl.'
    ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
    ${super:+"${super}"} pacman --noconfirm --sync curl
    log "Installed $(curl --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
    ${super:+"${super}"} pacman --noconfirm --sync git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
    ${super:+"${super}"} pacman --noconfirm --sync jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yay)" ]; then
    log 'Installing Yay package manager'
    ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
    ${super:+"${super}"} pacman --noconfirm --sync base-devel

    tmp_dir="$(mktemp --dry-run)"
    git clone --depth 1 'https://aur.archlinux.org/yay.git' "${tmp_dir}"
    (cd "${tmp_dir}" && makepkg --install --noconfirm --syncdeps)
    yay --noconfirm --refresh --sync --sysupgrade
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    install_yq "${1}"
    log "Installed $(yq --version)."
  fi
}

#######################################
# Configure bootstrapping services and utilities for Debian.
# Arguments:
#   Super user elevation command.
#######################################
setup_debian() {
  local super="${1:-}"

  # Avoid APT interactively requesting to configure tzdata.
  export DEBIAN_FRONTEND='noninteractive'

  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ ! -x "$(command -v ansible)" ]; then
    # Install Ansible with Python3 since most package managers provide an old
    # version of Ansible.
    log 'Installing Ansible.'
    ${super:+"${super}"} apt-get --quiet update
    ${super:+"${super}"} apt-get --quiet install --yes ansible
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v curl)" ]; then
    log 'Installing Curl.'
    ${super:+"${super}"} apt-get --quiet update
    ${super:+"${super}"} apt-get --quiet install --yes curl
    log "Installed $(curl --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    ${super:+"${super}"} apt-get --quiet update
    ${super:+"${super}"} apt-get --quiet install --yes git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    ${super:+"${super}"} apt-get --quiet update
    ${super:+"${super}"} apt-get --quiet install --yes jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    install_yq "${1}"
    log "Installed $(yq --version)."
  fi
}

#######################################
# Configure bootstrapping services and utilities for Fedora.
# Arguments:
#   Super user elevation command.
#######################################
setup_fedora() {
  local super="${1:-}"

  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ ! -x "$(command -v ansible)" ]; then
    log 'Installing Ansible.'
    # Installing Ansible via Python causes issues installing remote DNF packages
    # with Ansible.
    dnf_check_update "${1}"
    ${super:+"${super}"} dnf install --assumeyes ansible
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v curl)" ]; then
    log 'Installing Curl.'
    dnf_check_update "${1}"
    ${super:+"${super}"} dnf install --assumeyes curl
    log "Installed $(curl --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    dnf_check_update "${1}"
    ${super:+"${super}"} dnf install --assumeyes git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    dnf_check_update "${1}"
    ${super:+"${super}"} dnf install --assumeyes jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    install_yq "${1}"
    log "Installed $(yq --version)."
  fi
}

#######################################
# Configure bootstrapping services and utilities for FreeBSD.
# Arguments:
#   Super user elevation command.
#######################################
setup_freebsd() {
  local ansible_package super="${1:-}"

  if [ ! -x "$(command -v ansible)" ]; then
    log 'Installing Ansible.'
    ${super:+"${super}"} pkg update

    ansible_package="$(
      pkg search --quiet --regex 'py[0-9]+-ansible-[^A-Za-z]'
    )"
    ${super:+"${super}"} pkg install --yes "${ansible_package}"
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v curl)" ]; then
    log 'Installing Curl.'
    ${super:+"${super}"} pkg update
    ${super:+"${super}"} pkg install --yes curl
    log "Installed $(curl --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    ${super:+"${super}"} pkg update
    ${super:+"${super}"} pkg install --yes git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    ${super:+"${super}"} pkg update
    ${super:+"${super}"} pkg install --yes jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    install_yq "${1}"
    log "Installed $(yq --version)."
  fi
}

#######################################
# Configure bootstrapping services and utilities for Linux.
# Arguments:
#   Super user elevation command.
#######################################
setup_linux() {
  local super="${1:-}"

  # Install dependencies for Bootware base on available package manager.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ -x "$(command -v apk)" ]; then
    setup_alpine "${super}"
  elif [ -x "$(command -v pacman)" ]; then
    setup_arch "${super}"
  elif [ -x "$(command -v apt-get)" ]; then
    setup_debian "${super}"
  elif [ -x "$(command -v dnf)" ]; then
    setup_fedora "${super}"
  elif [ -x "$(command -v zypper)" ]; then
    setup_suse "${super}"
  else
    log --stderr 'Unable to find supported package manager.'
    exit 1
  fi
}

#######################################
# Configure bootstrapping services and utilities for MacOS.
#######################################
setup_macos() {
  # On Apple silicon, brew is not in the system path after installation.
  export PATH="/opt/homebrew/bin:${PATH}"

  # Install XCode command line tools if not already installed.
  #
  # Homebrew depends on the XCode command line tools.
  # Flags:
  #   -p: Print path to active developer directory.
  if ! xcode-select -p > /dev/null 2>&1; then
    log 'Installing command line tools for XCode'
    sudo xcode-select --install
  fi

  # Install Homebrew if not already installed.
  #
  # Flags:
  #   -L: Follow redirect request.
  #   -S: Show errors.
  #   -f: Fail silently on server errors.
  #   -s: Disable progress bars.
  #   -x: Check if file exists and execute permission is granted.
  if [ ! -x "$(command -v brew)" ]; then
    log 'Installing Homebrew.'
    fetch 'https://raw.githubusercontent.com/Homebrew/install/master/install.sh' |
      bash
    brew analytics off
  fi

  if [ ! -x "$(command -v ansible)" ]; then
    log 'Installing Ansible.'
    brew install ansible
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    brew install git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    brew install jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    brew install yq
    log "Installed $(yq --version)."
  fi
}

#######################################
# Configure bootstrapping services and utilities for OpenSuse.
# Arguments:
#   Super user elevation command.
#######################################
setup_suse() {
  local super="${1:-}"

  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ ! -x "$(command -v ansible)" ]; then
    log 'Installing Ansible.'
    ${super:+"${super}"} zypper update --no-confirm
    ${super:+"${super}"} zypper install --no-confirm ansible
    log "Installed $(ansible --version)."
  fi

  if [ ! -x "$(command -v curl)" ]; then
    log 'Installing Curl.'
    ${super:+"${super}"} zypper update --no-confirm
    ${super:+"${super}"} zypper install --no-confirm curl
    log "Installed $(curl --version)."
  fi

  if [ ! -x "$(command -v git)" ]; then
    log 'Installing Git.'
    ${super:+"${super}"} zypper update --no-confirm
    ${super:+"${super}"} zypper install --no-confirm git
    log "Installed $(git --version)."
  fi

  if [ ! -x "$(command -v jq)" ]; then
    log 'Installing Jq.'
    ${super:+"${super}"} zypper update --no-confirm
    ${super:+"${super}"} zypper install --no-confirm jq
    log "Installed $(jq --version)."
  fi

  if [ ! -x "$(command -v yq)" ]; then
    log 'Installing Yq.'
    install_yq "${super}"
    log "Installed $(yq --version)."
  fi
}

#######################################
# Subcommand to remove Bootware files.
# Outputs:
#   Writes status information about removed files.
#######################################
uninstall() {
  local dst_file super=''

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -h | --help)
        usage 'uninstall'
        exit 0
        ;;
      *)
        log --stderr "error: No such option '${1}'."
        log --stderr "Run 'bootware uninstall --help' for usage."
        exit 2
        ;;
    esac
  done

  dst_file="$(fullpath "$0")"

  # Use doas or sudo for system installation if user is not root.
  #
  # Flags:
  #   -w: Check if file exists and it writable.
  if [ ! -w "${dst_file}" ] && [ "$(id -u)" -ne 0 ]; then
    super="$(find_super)"
  fi

  # Do not quote the outer super parameter expansion. Shell will error due to be
  # being unable to find the "" command.
  ${super:+"${super}"} rm "${dst_file}"

  log 'Uninstalled Bootware.'
}

#######################################
# Subcommand to update Bootware script.
# Arguments:
#   Parent directory of Bootware script.
# Outputs:
#   Writes status information and updated Bootware version to stdout.
#######################################
update() {
  local dst_file src_url super='' user_install version='main'

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -h | --help)
        usage 'update'
        exit 0
        ;;
      -v | --version)
        version="${2}"
        shift 2
        ;;
      *)
        log --stderr "error: No such option '${1}'."
        log --stderr "Run 'bootware update --help' for usage."
        exit 2
        ;;
    esac
  done

  dst_file="$(fullpath "$0")"
  src_url="https://raw.githubusercontent.com/scruffaluff/bootware/${version}/src/bootware.sh"

  # Use doas or sudo for system installation if user is not root.
  #
  # Flags:
  #   -w: Check if file exists and it writable.
  if [ ! -w "${dst_file}" ] && [ "$(id -u)" -ne 0 ]; then
    super="$(find_super)"
  elif [ -w "${dst_file}" ] && [ "$(id -u)" -ne 0 ]; then
    user_install='true'
  fi

  log 'Updating Bootware.'
  fetch --dest "${dst_file}" --mode 755 --super "${super}" "${src_url}"
  update_completions "${super}" "${user_install:-}" "${version}"
  log "Updated to $(bootware --version)."
}

#######################################
# Update completion scripts for Bootware.
# Arguments:
#   Super user elevation command.
#   Whether to install for entire system.
#   GitHub version reference.
#######################################
update_completions() {
  local brew_prefix global_="${2}" os super="${1}" version="${3}"
  local repo_url="https://raw.githubusercontent.com/scruffaluff/bootware/${version}"
  local bash_url="${repo_url}/src/completion/bootware.bash"
  local fish_url="${repo_url}/src/completion/bootware.fish"

  # Flags:
  #  -z: Check if the string is empty.
  if [ -z "${global_}" ]; then
    if [ "$(uname -m)" = 'arm64' ]; then
      brew_prefix='/opt/homebrew'
    else
      brew_prefix='/usr/local'
    fi
    os="$(uname -s)"

    if [ "${os}" = 'Darwin' ]; then
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
      fetch --dest '/etc/fish/completions/bootware.fish' \
        --mode 644 --super "${super}" "${fish_url}"
    fi
  else
    fetch --dest "${HOME}/.local/share/bash-completion/completions/bootware" \
      --mode 644 "${bash_url}"
    fetch --dest "${HOME}/.config/fish/completions/bootware.fish" \
      --mode 644 "${fish_url}"
  fi
}

#######################################
# Print Bootware version string.
# Outputs:
#   Bootware version string.
#######################################
version() {
  echo 'Bootware 0.9.1'
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
        usage 'main'
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      bootstrap)
        shift 1
        bootstrap "$@"
        exit 0
        ;;
      config)
        shift 1
        config "$@"
        exit 0
        ;;
      roles)
        shift 1
        roles "$@"
        exit 0
        ;;
      setup)
        shift 1
        setup "$@"
        exit 0
        ;;
      uninstall)
        shift 1
        uninstall "$@"
        exit 0
        ;;
      update)
        shift 1
        update "$@"
        exit 0
        ;;
      *)
        log --stderr "error: No such subcommand or option '${1}'."
        log --stderr "Run 'bootware --help' for usage."
        exit 2
        ;;
    esac
  done

  usage 'main'
}

# Add ability to selectively skip main function during test suite.
if [ -z "${BATS_SOURCE_ONLY:-}" ]; then
  main "$@"
fi
