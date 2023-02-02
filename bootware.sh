#!/usr/bin/env bash
#
# Bootstrap software installations with Ansible.

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
  case "$1" in
    bootstrap)
      cat 1>&2 << EOF
Bootware bootstrap
Boostrap install computer software

USAGE:
    bootware bootstrap [OPTIONS]

OPTIONS:
        --check                     Perform dry run and show possible changes
        --checkout <REF>            Git reference to run against
    -c, --config <PATH>             Path to bootware user configuation file
        --debug                     Enable Ansible task debugger
    -d, --dev                       Run bootstrapping in development mode
    -h, --help                      Print help information
    -i, --inventory <IP-LIST>       Ansible host IP addesses
        --no-passwd                 Do not ask for user password
        --no-setup                  Skip Bootware dependency installation
        --password <PASSWORD>       Remote host user password
    -p, --playbook <FILE-NAME>      Path to playbook to execute
        --private-key <FILE-NAME>   Path to SSH private key
        --retries <INTEGER>         Playbook retry limit during failure
    -s, --skip <TAG-LIST>           Ansible playbook tags to skip
        --start-at-role <ROLE>      Begin execution with role
    -t, --tags <TAG-LIST>           Ansible playbook tags to select
    -u, --url <URL>                 URL of playbook repository
        --user <USER-NAME>          Remote host user login name
        --windows                   Connect to a Windows host with SSH

ANSIBLE-OPTIONS:
EOF
      ansible --help
      ;;
    config)
      cat 1>&2 << EOF
Bootware config
Download default Bootware configuration file

USAGE:
    bootware config [OPTIONS]

OPTIONS:
    -d, --dest <PATH>       Path to alternate download destination
    -e, --empty             Write empty configuration file
    -h, --help              Print help information
    -s, --source <URL>      URL to configuration file
EOF
      ;;
    main)
      cat 1>&2 << EOF
$(version)
Boostrapping software installer

USAGE:
    bootware [OPTIONS] [SUBCOMMAND]

OPTIONS:
        --debug      Enable Bash debug traces
    -h, --help       Print help information
    -v, --version    Print version information

SUBCOMMANDS:
    bootstrap        Boostrap install computer software
    config           Generate Bootware configuration file
    roles            List all Bootware roles
    setup            Install dependencies for Bootware
    uninstall        Remove Bootware files
    update           Update Bootware to latest version

ENVIRONMENT VARIABLES:
    BOOTWARE_CONFIG     Set the configuration file path
    BOOTWARE_NOPASSWD   Assume passwordless sudo
    BOOTWARE_NOSETUP    Skip Ansible install and system setup
    BOOTWARE_PLAYBOOK   Set Ansible playbook name
    BOOTWARE_SKIP       Set skip tags for Ansible roles
    BOOTWARE_TAGS       Set tags for Ansible roles
    BOOTWARE_URL        Set location of Ansible repository

See 'bootware <subcommand> --help' for more information on a specific command.
EOF
      ;;
    roles)
      cat 1>&2 << EOF
Bootware roles
List all Bootware roles

USAGE:
    bootware roles [OPTIONS]

OPTIONS:
    -h, --help        Print help information
    -u, --url <URL>   URL of playbook repository
EOF
      ;;
    setup)
      cat 1>&2 << EOF
Bootware setup
Install dependencies for Bootware

USAGE:
    bootware setup [OPTIONS]

OPTIONS:
    -h, --help      Print help information
EOF
      ;;
    uninstall)
      cat 1>&2 << EOF
Bootware uninstall
Remove Bootware files

USAGE:
    bootware uninstall

OPTIONS:
    -h, --help                  Print help information
EOF
      ;;
    update)
      cat 1>&2 << EOF
Bootware update
Update Bootware to latest version

USAGE:
    bootware update [OPTIONS]

OPTIONS:
    -h, --help                  Print help information
    -v, --version <VERSION>     Version override for update
EOF
      ;;
    *)
      error "No such usage option '$1'"
      ;;
  esac
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
    error "Cannot find required $1 command on computer"
  fi
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
#   USER
#######################################
bootstrap() {
  # /dev/null is never a normal file.
  local ask_passwd
  local cmd='pull'
  local config_path="${BOOTWARE_CONFIG:-'/dev/null'}"
  local connection='local'
  local extra_args=()
  local inventory='127.0.0.1,'
  local no_setup="${BOOTWARE_NOSETUP:-}"
  local passwd
  local playbook
  local retries=1
  local skip="${BOOTWARE_SKIP:-}"
  local start_role
  local status
  local tags="${BOOTWARE_TAGS:-}"
  local url="${BOOTWARE_URL:-https://github.com/scruffaluff/bootware.git}"
  local windows

  # Check if Ansible should ask for user password.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${BOOTWARE_NOPASSWD:-}" ]]; then
    ask_passwd='true'
  fi

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -c | --config)
        config_path="$2"
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
        inventory="$2"
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
        playbook="$2"
        shift 2
        ;;
      --password)
        passwd="$2"
        shift 2
        ;;
      --retries)
        retries=$2
        shift 2
        ;;
      -s | --skip)
        skip="$2"
        shift 2
        ;;
      --start-at-role)
        start_role="$2"
        cmd='playbook'
        shift 2
        ;;
      -t | --tags)
        tags="$2"
        shift 2
        ;;
      -u | --url)
        url="$2"
        shift 2
        ;;
      --windows)
        ask_passwd=''
        cmd='playbook'
        connection='ssh'
        windows='true'
        shift 1
        ;;
      *)
        extra_args+=("$1")
        shift 1
        ;;
    esac
  done

  # Check if Bootware setup should be run.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${no_setup:-}" ]]; then
    setup
  fi

  # Download repository if no playbook is selected.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ "${cmd}" == 'playbook' && -z "${playbook:-}" ]]; then
    # Do not use long form --dry-run flag. It is not supported on MacOS.
    tmp_dir="$(mktemp -u)"
    git clone --depth 1 "${url}" "${tmp_dir}" &> /dev/null
    playbook="${tmp_dir}/playbook.yaml"
  fi

  # Find task associated with start role.
  #
  # Flags:
  #   -n: Check if the string has nonzero length.
  if [[ -n "${start_role:-}" ]]; then
    assert_cmd yq
    repo_dir="$(dirname "${playbook}")"
    start_task="$(
      yq '.[0].name' "${repo_dir}/roles/${start_role}/tasks/main.yaml"
    )"
    extra_args+=('--start-at-task' "${start_task}")
  fi

  # Convenience logic for using a single host without a trailing comma.
  if [[ ! "${inventory}" =~ .*','.* ]]; then
    inventory="${inventory},"
  fi

  if [[ "${cmd}" == 'playbook' ]]; then
    extra_args+=('--connection' "${connection}")
  elif [[ "${cmd}" == 'pull' ]]; then
    playbook="${BOOTWARE_PLAYBOOK:-playbook.yaml}"
    extra_args+=('--url' "${url}")
  fi

  find_config_path "${config_path}"
  config_path="${RET_VAL}"

  log "Executing Ansible ${cmd}"
  log 'Enter your user account password if prompted'

  until "ansible-${cmd}" \
    ${ask_passwd:+--ask-become-pass} \
    ${checkout:+--checkout "${checkout}"} \
    ${passwd:+--extra-vars "ansible_password=${passwd}"} \
    ${windows:+--extra-vars 'ansible_pkg_mgr=scoop'} \
    --extra-vars 'ansible_python_interpreter=auto_silent' \
    ${windows:+--extra-vars 'ansible_shell_type=powershell'} \
    --extra-vars "@${config_path}" \
    --inventory "${inventory}" \
    ${tags:+--tags "${tags}"} \
    ${skip:+--skip-tags "${skip}"} \
    ${extra_args:+"${extra_args[@]}"} \
    "${playbook}"; do

    status=$?
    ((retries--)) && ((retries == 0)) && exit "${status}"
    printf "\nBootstrapping attempt failed with exit code %s." "${status}"
    printf "\nRetrying bootstrapping with %s attempts left.\n" "${retries}"
    sleep 4
  done
}

#######################################
# Subcommand to generate or download Bootware configuration file.
# Globals:
#   HOME
# Arguments:
#   Parent directory of Bootware script.
# Outputs:
#   Writes status information to stdout.
#######################################
config() {
  local src_url
  local dst_file="${HOME}/.bootware/config.yaml"
  local empty_cfg

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d | --dest)
        dst_file="$2"
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
        src_url="$2"
        shift 2
        ;;
      *)
        error_usage "No such option '$1'" "config"
        ;;
    esac
  done

  # Do not use long form --parents flag for mkdir. It is not supported on MacOS.
  mkdir -p "$(dirname "${dst_file}")"

  # Check if empty configuration file should be generated.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ "${empty_cfg:-}" == 'true' || -z "${src_url:-}" ]]; then
    log "Writing empty configuration file to ${dst_file}"
    printf 'passwordless_sudo: false' > "${dst_file}"
  else
    assert_cmd curl

    log "Downloading configuration file to ${dst_file}"

    # Download configuration file.
    #
    # FLAGS:
    #   -L: Follow redirect request.
    #   -S: Show errors.
    #   -f: Use archive file. Must be third flag.
    #   -o <path>: Write output to path instead of stdout.
    curl -LSfs "${src_url}" -o "${dst_file}"
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
#   Whether to use sudo command.
#######################################
dnf_check_update() {
  ${1:+sudo} dnf check-update || {
    code="$?"
    [[ "${code}" -eq 100 ]] && return 0
    return "${code}"
  }
}

#######################################
# Print error message and exit script with error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error() {
  local bold_red='\033[1;31m'
  local default='\033[0m'

  printf "${bold_red}error${default}: %s\n" "$1" >&2
  exit 1
}

#######################################
# Print error message and exit script with usage error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error_usage() {
  local bold_red='\033[1;31m'
  local default='\033[0m'

  printf "${bold_red}error${default}: %s\n" "$1" >&2
  printf "Run \'bootware %s--help\' for usage.\n" "${2:+$2 }" >&2
  exit 2
}

#######################################
# Find path of Bootware configuation file.
# Globals:
#   HOME
# Arguments:
#   User supplied configuration path.
# Outputs:
#   Writes error message to stderr if unable to find configuration file.
# Returns:
#   Configuration file path.
#######################################
find_config_path() {
  # Flags:
  #   -f: Check if file exists and is a regular file.
  #   -n: Check if the string has nonzero length.
  #   -v: Only show file path of command.
  if [[ -f "${1:-}" ]]; then
    RET_VAL="$1"
  elif [[ -n "${BOOTWARE_CONFIG:-}" ]]; then
    RET_VAL="${BOOTWARE_CONFIG}"
  elif [[ -f "${HOME}/.bootware/config.yaml" ]]; then
    RET_VAL="${HOME}/.bootware/config.yaml"
  else
    log 'Unable to find Bootware configuation file.'
    config --empty
    RET_VAL="${HOME}/.bootware/config.yaml"
  fi

  log "Using ${RET_VAL} as configuration file"
}

#######################################
# Get full normalized path for file.
# Alternative to realpath command, since it is not built into MacOS.
#######################################
fullpath() {
  local working_dir

  # Flags:
  #   -P: Resolve any symbolic links in the path.
  working_dir="$(cd "$(dirname "$1")" && pwd -P)"

  echo "${working_dir}/$(basename "$1")"
}

#######################################
# Install YQ parser for YAML files.
# Arguments:
#   Whether to use sudo command.
#######################################
install_yq() {
  local arch
  local os_type
  local url
  local version

  assert_cmd curl
  assert_cmd jq

  # Do not use long form --kernel-name or --machine flags for uname. They are
  # not supported on MacOS.
  arch="$(uname -m)"
  arch="${arch/#x86_64/amd64}"
  arch="${arch/%x64/amd64}"
  arch="${arch/#aarch64/arm64}"
  arch="${arch/%arm/arm64}"
  os_type="$(uname -s)"

  # Get latest YQ version.
  #
  # FLAGS:
  #   -L: Follow redirect request.
  #   -S: Show errors.
  #   -f: Fail silently on server errors.
  #   -o file: Save output to file.
  #   -s: Disable progress bars.
  version="$(
    curl -LSfs https://formulae.brew.sh/api/formula/yq.json |
      jq --exit-status --raw-output .versions.stable
  )"
  url="https://github.com/mikefarah/yq/releases/download/v${version}/yq_${os_type}_${arch}"

  # Do not quote the sudo parameter expansion. Bash will error due to be being
  # unable to find the "" command.
  ${1:+sudo} curl -LSfs "${url}" -o /usr/local/bin/yq
  ${1:+sudo} chmod 755 /usr/local/bin/yq
}

#######################################
# Print log message to stdout if logging is enabled.
# Globals:
#   BOOTWARE_NOLOG
# Outputs:
#   Log message to stdout.
#######################################
log() {
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${BOOTWARE_NOLOG:-}" ]]; then
    echo "$@"
  fi
}

#######################################
# Subcommand to list all Bootware roles.
#######################################
roles() {
  local url="${BOOTWARE_URL:-https://github.com/scruffaluff/bootware.git}"

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage 'roles'
        exit 0
        ;;
      -u | --url)
        url="$2"
        shift 2
        ;;
      *)
        error_usage "No such option '$1'" "roles"
        ;;
    esac
  done

  # Do not use long form --dry-run flag for mktemp. It is not supported on
  # MacOS.
  tmp_dir="$(mktemp -u)"
  git clone --depth 1 "${url}" "${tmp_dir}" &> /dev/null
  ls -1 "${tmp_dir}/roles"
}

#######################################
# Subcommand to configure boostrapping services and utilities.
#######################################
setup() {
  local os_type
  local tmp_dir
  local use_sudo=''

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage 'setup'
        exit 0
        ;;
      *)
        error_usage "No such option '$1'" "setup"
        ;;
    esac
  done

  assert_cmd uname

  # Check if user is not root.
  if [[ "${EUID}" -ne 0 ]]; then
    use_sudo='true'
  fi

  # Do not use long form --kernel-name flag for uname. It is not supported on
  # MacOS.
  os_type="$(uname -s)"
  case "${os_type}" in
    Darwin)
      setup_macos
      ;;
    FreeBSD)
      setup_freebsd "${use_sudo}"
      ;;
    Linux)
      setup_linux "${use_sudo}"
      ;;
    *)
      error "Operating system ${os_type} is not supported"
      ;;
  esac

  collections=('chocolatey.chocolatey' 'community.general' 'community.windows')
  for collection in "${collections[@]}"; do
    collection_status="$(ansible-galaxy collection list "${collection}" 2>&1)"
    if [[ "${collection_status}" =~ 'unable to find' ]]; then
      ansible-galaxy collection install "${collection}"
    fi
  done
}

#######################################
# Configure boostrapping services and utilities for Alpine.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_alpine() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log 'Installing Ansible'
    # Install Ansible with Python3 since most package managers provide an old
    # version of Ansible.
    ${1:+sudo} apk update
    ${1:+sudo} apk add python3 python3-dev py3-pip

    # There are no Alpine Ansible wheels. Additional libraries are required to
    # build Ansible from scratch.
    ${1:+sudo} apk add gcc libffi-dev musl-dev openssl-dev
    ${1:+sudo} python3 -m pip install --upgrade pip setuptools wheel
    ${1:+sudo} python3 -m pip install ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log 'Installing Curl'
    ${1:+sudo} apk update
    ${1:+sudo} apk add curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    ${1:+sudo} apk update
    ${1:+sudo} apk add git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    ${1:+sudo} apk update
    ${1:+sudo} apk add jq
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    install_yq "$1"
  fi
}

#######################################
# Configure boostrapping services and utilities for Arch.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_arch() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log 'Installing Ansible'
    # Installing Ansible via Python causes pacman conflicts with AWSCLI.
    ${1:+sudo} pacman -Suy --noconfirm
    ${1:+sudo} pacman -S --noconfirm ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log 'Installing Curl'
    ${1:+sudo} pacman -Suy --noconfirm
    ${1:+sudo} pacman -S --noconfirm curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    ${1:+sudo} pacman -Suy --noconfirm
    ${1:+sudo} pacman -S --noconfirm git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    ${1:+sudo} pacman -Suy --noconfirm
    ${1:+sudo} pacman -S --noconfirm jq
  fi

  if [[ ! -x "$(command -v yay)" ]]; then
    log 'Installing Yay package manager'
    ${1:+sudo} pacman -Suy --noconfirm
    ${1:+sudo} pacman -S --noconfirm base-devel

    # Do not use long form --dry-run flag for mktemp. It is not supported on
    # MacOS.
    tmp_dir="$(mktemp -u)"
    git clone --depth 1 'https://aur.archlinux.org/yay.git' "${tmp_dir}"
    (cd "${tmp_dir}" && makepkg --noconfirm -is)
    yay --noconfirm -Suy
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    install_yq "$1"
  fi
}

#######################################
# Configure boostrapping services and utilities for Debian.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_debian() {
  # Avoid APT interactively requesting to configure tzdata.
  export DEBIAN_FRONTEND='noninteractive'

  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    # Install Ansible with Python3 since most package managers provide an old
    # version of Ansible.
    log 'Installing Ansible'
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y python3 python3-pip python3-apt

    ${1:+sudo} python3 -m pip install --upgrade pip setuptools wheel
    ${1:+sudo} python3 -m pip install ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log 'Installing Curl'
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y jq
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    install_yq "$1"
  fi
}

#######################################
# Configure boostrapping services and utilities for Fedora.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_fedora() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log 'Installing Ansible'
    # Installing Ansible via Python causes issues installing remote DNF packages
    # with Ansible.
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log 'Installing Curl'
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y jq
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    install_yq "$1"
  fi
}

#######################################
# Configure boostrapping services and utilities for FreeBSD.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_freebsd() {
  assert_cmd pkg

  if [[ ! -x "$(command -v ansible)" ]]; then
    log 'Installing Ansible'
    # Install Ansible with Python3 since most package managers provide an old
    # version of Ansible.
    ${1:+sudo} pkg update
    # Python's cryptography package requires a Rust compiler on FreeBSD.
    ${1:+sudo} pkg install -y python3 rust

    py_ver="$(python3 -c 'import sys; print("{}{}".format(*sys.version_info[:2]))')"
    ${1:+sudo} pkg install -y "py${py_ver}-pip"

    ${1:+sudo} python3 -m pip install --upgrade pip setuptools wheel
    ${1:+sudo} python3 -m pip install ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log 'Installing Curl'
    ${1:+sudo} pkg update
    ${1:+sudo} pkg install -y curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    ${1:+sudo} pkg update
    ${1:+sudo} pkg install -y git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    ${1:+sudo} pkg update
    ${1:+sudo} pkg install -y jq
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    install_yq "$1"
  fi
}

#######################################
# Configure boostrapping services and utilities for Linux.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_linux() {
  # Install dependencies for Bootware base on available package manager.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ -x "$(command -v apk)" ]]; then
    setup_alpine "$1"
  elif [[ -x "$(command -v pacman)" ]]; then
    setup_arch "$1"
  elif [[ -x "$(command -v apt-get)" ]]; then
    setup_debian "$1"
  elif [[ -x "$(command -v dnf)" ]]; then
    setup_fedora "$1"
  elif [[ -x "$(command -v zypper)" ]]; then
    setup_suse "$1"
  else
    error 'Unable to find supported package manager'
  fi
}

#######################################
# Configure boostrapping services and utilities for MacOS.
#######################################
setup_macos() {
  assert_cmd curl

  # On Apple silicon, brew is not in the system path after installation.
  export PATH="/opt/homebrew/bin:${PATH}"

  # Install XCode command line tools if not already installed.
  #
  # Homebrew depends on the XCode command line tools.
  # Flags:
  #   -p: Print path to active developer directory.
  if ! xcode-select -p &> /dev/null; then
    log 'Installing command line tools for XCode'
    sudo xcode-select --install
  fi

  # Install Rosetta 2 for Apple Silicon if not already installed.
  #
  # # Do not use long form --processor flag for uname. It is not supported on
  # MacOS.
  #
  # Flags:
  #   -d: Check if path exists and is a directory.
  if [[ "$(uname -p)" == 'arm' && ! -d '/opt/homebrew' ]]; then
    softwareupdate --agree-to-license --install-rosetta
  fi

  # Install Homebrew if not already installed.
  #
  # FLAGS:
  #   -L: Follow redirect request.
  #   -S: Show errors.
  #   -f: Fail silently on server errors.
  #   -s: Disable progress bars.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v brew)" ]]; then
    log 'Installing Homebrew'
    curl -LSfs 'https://raw.githubusercontent.com/Homebrew/install/master/install.sh' | bash
  fi

  if [[ ! -x "$(command -v ansible)" ]]; then
    log 'Installing Ansible'
    brew install ansible
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    brew install git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    brew install jq
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    brew install yq
  fi
}

#######################################
# Configure boostrapping services and utilities for OpenSuse.
# Arguments:
#   Whether to use sudo command.
#######################################
setup_suse() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log 'Installing Ansible'
    ${1:+sudo} zypper update -y
    ${1:+sudo} zypper install -y python3 python3-pip

    ${1:+sudo} python3 -m pip install --upgrade pip setuptools wheel
    ${1:+sudo} python3 -m pip install ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log 'Installing Curl'
    ${1:+sudo} zypper update -y
    ${1:+sudo} zypper install -y curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log 'Installing Git'
    ${1:+sudo} zypper update -y
    ${1:+sudo} zypper install -y git
  fi

  if [[ ! -x "$(command -v jq)" ]]; then
    log 'Installing JQ'
    ${1:+sudo} zypper update -y
    ${1:+sudo} zypper install -y jq
  fi

  if [[ ! -x "$(command -v yq)" ]]; then
    log 'Installing YQ'
    install_yq "$1"
  fi
}

#######################################
# Subcommand to remove Bootware files.
# Outputs:
#   Writes status information about removed files.
#######################################
uninstall() {
  local dst_file
  local use_sudo=''

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage 'uninstall'
        exit 0
        ;;
      *)
        error_usage "No such option '$1'" "update"
        ;;
    esac
  done

  assert_cmd chmod

  dst_file="$(fullpath "$0")"

  # Use sudo for system installation if user is not root.
  #
  # Flags:
  #   -w: Check if file exists and it writable.
  if [[ ! -w "${dst_file}" && "${EUID}" -ne 0 ]]; then
    assert_cmd sudo
    use_sudo='true'
  fi

  # Do not quote the sudo parameter expansion. Bash will error due to be being
  # unable to find the "" command.
  ${use_sudo:+sudo} rm "${dst_file}"

  log 'Uninstalled Bootware'
}

#######################################
# Subcommand to update Bootware script.
# Arguments:
#   Parent directory of Bootware script.
# Outputs:
#   Writes status information and updated Bootware version to stdout.
#######################################
update() {
  local dst_file
  local src_url
  local use_sudo=''
  local version='main'

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage 'update'
        exit 0
        ;;
      -v | --version)
        version="$2"
        shift 2
        ;;
      *)
        error_usage "No such option '$1'" "update"
        ;;
    esac
  done

  assert_cmd chmod
  assert_cmd curl

  dst_file="$(fullpath "$0")"
  src_url="https://raw.githubusercontent.com/scruffaluff/bootware/${version}/bootware.sh"

  # Use sudo for system installation if user is not root.
  #
  # Flags:
  #   -w: Check if file exists and it writable.
  if [[ ! -w "${dst_file}" && "${EUID}" -ne 0 ]]; then
    assert_cmd sudo
    use_sudo='true'
  fi

  log 'Updating Bootware'

  # Do not quote the sudo parameter expansion. Bash will error due to be being
  # unable to find the "" command.
  ${use_sudo:+sudo} curl -LSfs "${src_url}" -o "${dst_file}"
  ${use_sudo:+sudo} chmod 755 "${dst_file}"

  log "Updated to version $(bootware --version)"
}

#######################################
# Print Bootware version string.
# Outputs:
#   Bootware version string.
#######################################
version() {
  echo 'Bootware 0.5.0'
}

#######################################
# Script entrypoint.
#######################################
main() {
  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --debug)
        set -o xtrace
        shift 1
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
      -h | --help)
        usage 'main'
        exit 0
        ;;
      -v | --version)
        version
        exit 0
        ;;
      *)
        error_usage "No such subcommand or option '$1'"
        ;;
    esac
  done
}

# Only run main if invoked as script. Otherwise import functions as library.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
