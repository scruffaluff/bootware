#!/usr/bin/env bash
#
# Bootstrap software installations with Ansible.

# Exit immediately if a command exists with a non-zero status.
set -e

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
    -c, --config <PATH>             Path to bootware user configuation file
    -d, --dev                       Run bootstrapping in development mode
    -h, --help                      Print help information
    -i, --inventory <IP-List>       Ansible host IP addesses
        --no-passwd                 Do not ask for user password
        --no-setup                  Skip Bootware dependency installation
    -p, --playbook <FILE-NAME>      Name of play to execute
        --password <PASSWORD>       Remote host user password
    -s, --skip <TAG-LIST>           Ansible playbook tags to skip
    -t, --tags <TAG-LIST>           Ansible playbook tags to select
    -u, --url <URL>                 URL of playbook repository
        --user <USER-NAME>          Remote host user login name
        --winrm                     Use WinRM connection instead of SSH
EOF
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
    -h, --help       Print help information
    -v, --version    Print version information

SUBCOMMANDS:
    bootstrap        Boostrap install computer software
    config           Generate default Bootware configuration file
    setup            Install dependencies for Bootware
    update           Update Bootware to latest version

See 'bootware <subcommand> --help' for more information on a specific command.
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
  local ask_passwd_winrm
  local cmd="pull"
  local config_path="${BOOTWARE_CONFIG:-"/dev/null"}"
  local connection="local"
  local inventory="127.0.0.1,"
  local no_setup="${BOOTWARE_NOSETUP:-""}"
  local passwd
  local playbook="${BOOTWARE_PLAYBOOK:-"main.yaml"}"
  local skip="${BOOTWARE_SKIP:-""}"
  local tags="${BOOTWARE_TAGS:-""}"
  local url="${BOOTWARE_URL:-"https://github.com/wolfgangwazzlestrauss/bootware.git"}"
  local use_playbook
  local use_pull=1
  local user_account="${USER:-root}"
  local winrm

  # Check if Ansible should ask for user password.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${BOOTWARE_NOPASSWD}" ]]; then
    ask_passwd=1
  fi

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -c | --config)
        config_path="$2"
        shift 2
        ;;
      -d | --dev)
        cmd="playbook"
        use_playbook=1
        use_pull=""
        shift 1
        ;;
      -h | --help)
        usage "bootstrap"
        exit 0
        ;;
      -i | --inventory)
        inventory="$2"
        shift 2
        ;;
      --no-passwd)
        ask_passwd=""
        shift 1
        ;;
      --no-setup)
        no_setup=1
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
      -s | --skip)
        skip="$2"
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
      --user)
        user_account="$2"
        shift 2
        ;;
      --winrm)
        ask_passwd=""
        cmd="playbook"
        connection="winrm"
        use_playbook=1
        use_pull=""
        winrm=1
        shift 1
        ;;
      *)
        error_usage "No such option '$1'"
        ;;
    esac
  done

  # Check if Ansible should ask for user password for WinRM connections.
  #
  # Flags:
  #   -n: Check if the string has nonzero length.
  #   -z: Check if string has zero length.
  if [[ -n "${winrm}" && -z "${passwd}" ]]; then
    ask_passwd_winrm=1
  fi

  # Check if Bootware setup should be run.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${no_setup}" ]]; then
    setup
  fi

  find_config_path "${config_path}"
  config_path="${RET_VAL}"

  log "Executing Ansible ${cmd:-pull}"
  log "Enter your user account password if prompted"

  "ansible-${cmd}" \
    ${ask_passwd:+--ask-become-pass} \
    ${ask_passwd_winrm:+--ask-pass} \
    ${use_playbook:+--connection "$connection"} \
    ${passwd:+--extra-vars "ansible_password=$passwd"} \
    ${winrm:+--extra-vars "ansible_pkg_mgr=scoop"} \
    --extra-vars "ansible_python_interpreter=auto_silent" \
    ${winrm:+--extra-vars "ansible_user=$user_account"} \
    ${winrm:+--extra-vars "ansible_winrm_server_cert_validation=ignore"} \
    ${winrm:+--extra-vars "ansible_winrm_transport=basic"} \
    --extra-vars "user_account=${user_account}" \
    --extra-vars "@${config_path}" \
    --inventory "${inventory}" \
    ${use_pull:+--url "$url"} \
    ${tags:+--tags "$tags"} \
    ${skip:+--skip-tags "$skip"} \
    "${playbook}"
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
  local src_url="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml"
  local dst_file="${HOME}/.bootware/config.yaml"
  local empty_cfg

  assert_cmd mkdir

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d | --dest)
        dst_file="$2"
        shift 2
        ;;
      -e | --empty)
        empty_cfg="true"
        shift 1
        ;;
      -h | --help)
        usage "config"
        exit 0
        ;;
      -s | --source)
        src_url="$2"
        shift 2
        ;;
      *)
        error_usage "No such option '$1'"
        ;;
    esac
  done

  mkdir -p "$(dirname "${dst_file}")"

  if [[ "${empty_cfg}" == "true" ]]; then
    log "Writing empty configuration file to ${dst_file}"
    printf "passwordless_sudo: false" > "${dst_file}"
  else
    assert_cmd curl

    log "Downloading configuration file to ${dst_file}"

    # Download default configuration file.
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
# Find path of Bootware configuation file.
# Globals:
#   HOME
# Arguments:
#   User supplied configuration path.
# Outputs:
#   Writes error message to stderr if unable to find configuration file.
# Retunrs:
#   Configuration file path.
#######################################
find_config_path() {
  # Flags:
  #   -f: Check if file exists and is a regular file.
  #   -n: Check if the string has nonzero length.
  #   -v: Only show file path of command.
  if [[ -f "$1" ]]; then
    RET_VAL="$1"
  elif [[ -n "${BOOTWARE_CONFIG}" ]]; then
    RET_VAL="${BOOTWARE_CONFIG}"
  elif [[ -f "${HOME}/.bootware/config.yaml" ]]; then
    RET_VAL="${HOME}/.bootware/config.yaml"
  else
    log "Unable to find Bootware configuation file.\n"
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
# Print log message to stdout if logging is enabled.
# Globals:
#   BOOTWARE_NOLOG
# Outputs:
#   Log message to stdout.
#######################################
log() {
  # Flags:
  #   -z: Check if string has zero length.
  if [[ -z "${BOOTWARE_NOLOG}" ]]; then
    echo "$@"
  fi
}

#######################################
# Subcommand to configure boostrapping services and utilities.
#######################################
setup() {
  local os_type
  local tmp_dir

  assert_cmd uname

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage "setup"
        exit 0
        ;;
      *)
        error_usage "No such option '$1'"
        ;;
    esac
  done

  # Get operating system.
  #
  # FLAGS:
  #   -s: Print the kernel name.
  os_type="$(uname -s)"

  case "${os_type}" in
    Darwin)
      setup_macos
      ;;
    Linux)
      setup_linux
      ;;
    *)
      error "Operting system ${os_type} is not supported"
      ;;
  esac

  ansible-galaxy collection install community.general > /dev/null
  ansible-galaxy collection install community.windows > /dev/null
}

#######################################
# Configure boostrapping services and utilities for Arch distributions.
#######################################
setup_arch() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log "Installing Ansible"
    ${1:+sudo} pacman --noconfirm -Suy
    ${1:+sudo} pacman --noconfirm -S ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log "Installing Curl"
    ${1:+sudo} pacman --noconfirm -Suy
    ${1:+sudo} pacman -S --noconfirm curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log "Installing Git"
    ${1:+sudo} pacman --noconfirm -Suy
    ${1:+sudo} pacman -S --noconfirm git
  fi

  if [[ ! -x "$(command -v yay)" ]]; then
    log "Installing Yay package manager"
    ${1:+sudo} pacman --noconfirm -Suy
    ${1:+sudo} pacman -S --noconfirm base-devel

    tmp_dir="$(mktemp -u)"
    git clone --depth 1 "https://aur.archlinux.org/yay.git" "${tmp_dir}"
    (cd "${tmp_dir}" && makepkg --noconfirm -is)
    yay --noconfirm -Suy
  fi
}

#######################################
# Configure boostrapping services and utilities for Debian distributions.
#######################################
setup_debian() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    # Ansible is install with Python3, since many Debian systems package Ansible
    # version 2.7, which does not support Ansible collections.
    log "Installing Ansible"
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y python3 python3-pip python3-apt

    # Not all Python installations have setuptools or wheel installed and it
    # must be installed as a separate step before other packages.
    ${1:+sudo} python3 -m pip install setuptools wheel
    ${1:+sudo} python3 -m pip install ansible pywinrm
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log "Installing Curl"
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log "Installing Git"
    ${1:+sudo} apt-get -qq update
    ${1:+sudo} apt-get -qq install -y git
  fi
}

#######################################
# Configure boostrapping services and utilities for Fedora distributions.
#######################################
setup_fedora() {
  # Install dependencies for Bootware.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log "Installing Ansible"
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y ansible
  fi

  if [[ ! -x "$(command -v curl)" ]]; then
    log "Installing Curl"
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y curl
  fi

  if [[ ! -x "$(command -v git)" ]]; then
    log "Installing Git"
    dnf_check_update "$1"
    ${1:+sudo} dnf install -y git
  fi
}

#######################################
# Configure boostrapping services and utilities for Linux.
#######################################
setup_linux() {
  local use_sudo

  # Check if user is not root.
  if [[ "${EUID}" -ne 0 ]]; then
    use_sudo=1
  fi

  # Install dependencies for Bootware base on available package manager.
  #
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [[ -x "$(command -v pacman)" ]]; then
    setup_arch "${use_sudo}"
  elif [[ -x "$(command -v apt-get)" ]]; then
    setup_debian "${use_sudo}"
  elif [[ -x "$(command -v dnf)" ]]; then
    setup_fedora "${use_sudo}"
  else
    error "Unable to find supported package manager"
  fi
}

#######################################
# Configure boostrapping services and utilities for MacOS.
#######################################
setup_macos() {
  assert_cmd curl

  # Install XCode command line tools if not already installed.
  #
  # Homebrew depends on the XCode command line tools.
  # Flags:
  #   -p: Print path to active developer directory.
  if ! xcode-select -p &> /dev/null; then
    log "Installing command line tools for XCode"
    sudo xcode-select --install
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
    log "Installing Homebrew"
    curl -LSfs "https://raw.githubusercontent.com/Homebrew/install/master/install.sh" | bash
  fi

  # Install Ansible if not already installed.
  if [[ ! -x "$(command -v ansible)" ]]; then
    log "Installing Ansible"
    brew install ansible
  fi

  # Install Git if not already installed.
  if [[ ! -x "$(command -v git)" ]]; then
    log "Installing Git"
    brew install git
  fi
}

#######################################
# Subcommand to update Bootware script
# Arguments:
#   Parent directory of Bootware script.
# Outputs:
#   Writes status information and updated Bootware version to stdout.
#######################################
update() {
  local dst_file
  local src_url
  local use_sudo
  local version="master"

  assert_cmd chmod
  assert_cmd curl

  # Parse command line arguments.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage "update"
        exit 0
        ;;
      -v | --version)
        version="$2"
        shift 2
        ;;
      *)
        error_usage "No such option '$1'"
        ;;
    esac
  done

  dst_file="$(fullpath "$0")"
  src_url="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/${version}/bootware.sh"

  # Use sudo for system installation if user is not root.
  #
  # Flags:
  #   -w: Check if file exists and it writable.
  if [[ ! -w "${dst_file}" && "${EUID}" -ne 0 ]]; then
    assert_cmd sudo
    use_sudo=1
  fi

  log "Updating Bootware"

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
  echo "Bootware 0.3.0"
}

#######################################
# Script entrypoint.
#######################################
main() {
  # Parse command line arguments.
  case "$1" in
    bootstrap)
      shift 1
      bootstrap "$@"
      ;;
    config)
      shift 1
      config "$@"
      ;;
    setup)
      shift 1
      setup "$@"
      ;;
    update)
      shift 1
      update "$@"
      ;;
    -h | --help)
      usage "main"
      ;;
    -v | --version)
      version
      ;;
    *)
      error_usage "No such subcommand '$1'"
      ;;
  esac
}

# Only run main if invoked as script. Otherwise import functions as library.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
