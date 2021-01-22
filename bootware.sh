#!/bin/bash
# shellcheck shell=bash
# Exit immediately if a command exists with a non-zero status.
set -e


# Show CLI help information.
#
# Cannot use function name help, since help is a pre-existing command.
usage() {
    case "$1" in
        bootstrap)
            cat 1>&2 <<EOF
Bootware bootstrap
Boostrap install computer software

USAGE:
    bootware bootstrap [OPTIONS]

OPTIONS:
    -c, --config <PATH>             Path to bootware user configuation file
    -d, --dev                       Run bootstrapping in development mode
    -h, --help                      Print help information
        --no-passwd                 Do not ask for user password
        --no-setup                  Skip Ansible installation
    -s, --skip-tags <TAG-LIST>      Ansible playbook tag list
    -t, --tags <TAG-LIST>           Ansible playbook tag list
EOF
            ;;
        config)
            cat 1>&2 <<EOF
Bootware config
Download default Bootware configuration file

USAGE:
    bootware config [OPTIONS]

OPTIONS:
    -h, --help              Print help information
    -d, --dest <PATH>       Path to alternate download destination
        --empty             Write empty configuration file
    -s, --source <URL>      URL to configuration file
EOF
            ;;
        main)
            cat 1>&2 <<EOF
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
EOF
            ;;
        setup)
            cat 1>&2 <<EOF
Bootware setup
Install dependencies for Bootware

USAGE:
    bootware setup [OPTIONS]

OPTIONS:
    -h, --help      Print help information
EOF
            ;;
        update)
            cat 1>&2 <<EOF
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

# Assert that command can be found on machine.
assert_cmd() {
    if ! check_cmd "$1" ; then
        error "Cannot find $1 command on computer."
    fi
}

# Bootstrap subcommand.
bootstrap() {
    # Dev null is never a normal file.
    local _config_path="/dev/null"
    local _no_setup
    local _playbook
    local _pull="1"
    local _skip_tags
    local _tags
    local _use_passwd="1"

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "bootstrap"
                exit 0
                ;;
            -c|--config)
                _config_path="$2"
                shift
                shift
                ;;
            -d|--dev)
                _pull=""
                _playbook="playbook"
                shift
                ;;
            --no-passwd)
                _use_passwd=""
                shift
                ;;
            --no-setup)
                _no_setup="1"
                shift
                ;;
            -s|--skip-tags)
                _skip_tags="$2"
                shift
                shift
                ;;
            -t|--tags)
                _tags="$2"
                shift
                shift
                ;;
            *)
                ;;
        esac
    done

    if [[ ! "$_no_setup" ]]; then
        setup
    fi

    find_config_path "$_config_path"
    _config_path="$RET_VAL"

    echo "Executing Ansible ${_playbook:-pull}..."
    echo "Enter your user account password if prompted."

    ansible-${_playbook:-pull}  \
        ${_use_passwd:+--ask-become-pass} \
        ${_playbook:+--connection local} \
        --extra-vars "ansible_python_interpreter=auto_silent" \
        --extra-vars "user_account=${USER:-root}" \
        --extra-vars "@$_config_path" \
        --inventory 127.0.0.1, \
        ${_skip_tags:+--skip-tags "$_skip_tags"} \
        ${_tags:+--tags "$_tags"} \
        ${_pull:+--url "https://github.com/wolfgangwazzlestrauss/bootware.git"} \
        main.yaml
}

# Check if command can be found on machine.
check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

# Config subcommand.
config() {
    local _source="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml"
    local _dest="$HOME/.bootware/config.yaml"
    local _empty

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "config"
                exit 0
                ;;
            -d|--dest)
                _dest="$2"
                shift
                shift
                ;;
            --empty)
                _empty=1
                shift
                ;;
            -s|--source)
                _source="$2"
                shift
                shift
                ;;
            *)
                ;;
        esac
    done

    mkdir -p $(dirname "$_dest")

    if [ $_empty == 1 ]; then
        echo "Writing empty configuration file to $_dest..."
        echo "mock_data: true" > "$_dest"
    else
        assert_cmd curl

        echo "Downloading configuration file to $_dest..."

        # Download default configuration file.
        #
        # FLAGS:
        #     -L: Follow redirect request.
        #     -S: Show errors.
        #     -f: Use archive file. Must be third flag.
        #     -o <path>: Write output to path instead of stdout. 
        curl -LSf "$_source" -o "$_dest"
    fi
}

# Print error message and exit with error code.
error() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

# Find path of Bootware configuation file.
find_config_path() {
    if test -f "$1" ; then
        RET_VAL="$1"
    elif test -f "$(pwd)/bootware.yaml" ; then
        RET_VAL="$(pwd)/bootware.yaml"
    elif [[ -n "${BOOTWARE_CONFIG}" ]] ; then
        RET_VAL="$BOOTWARE_CONFIG"
    elif test -f "$HOME/.bootware/config.yaml" ; then
        RET_VAL="$HOME/.bootware/config.yaml"
    else
        error "Unable to find Bootware configuation file."
    fi

    echo "Using $RET_VAL as configuration file."
}

# Configure boostrapping services and utilities.
setup() {
    local _os_type

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "setup"
                exit 0
                ;;
            *)
                ;;
        esac
    done

    # Get operating system for local machine.
    #
    # FLAGS:
    #     -s: Print the kernel name.
    _os_type=$(uname -s)

    case "$_os_type" in
        Darwin)
            setup_macos
            ;;
        Linux)
            setup_linux
            ;;
        *)
            error "Operting system $_os_type is not supported."
            ;;
    esac

    ansible-galaxy collection install community.general > /dev/null
    ansible-galaxy collection install community.windows > /dev/null
}

# Configure boostrapping services and utilities for Arch distributions.
setup_arch() {
    # Install dependencies for Bootware.
    #
    # dpkg -l does not always return the correct exit code. dpkg -s does. See
    # https://github.com/bitrise-io/bitrise/issues/433#issuecomment-256116057
    # for more information.
    #
    # Flags:
    #     -Q:
    #     -i:
    if ! pacman -Qi ansible &>/dev/null ; then
        echo "Installing Ansible..."
        ${1:+sudo} pacman --noconfirm -Suy
        ${1:+sudo} pacman --noconfirm -S ansible
    fi

    if ! pacman -Qi curl &>/dev/null ; then
        echo "Installing Curl..."
        ${1:+sudo} pacman --noconfirm -Suy
        ${1:+sudo} pacman -S --noconfirm curl
    fi

    if ! pacman -Qi git &>/dev/null ; then
        echo "Installing Git..."
        ${1:+sudo} pacman --noconfirm -Suy
        ${1:+sudo} pacman -S --noconfirm git
    fi
}

# Configure boostrapping services and utilities for Debian distributions.
setup_debian() {
    # Install dependencies for Bootware.
    #
    # dpkg -l does not always return the correct exit code. dpkg -s does. See
    # https://github.com/bitrise-io/bitrise/issues/433#issuecomment-256116057
    # for more information.
    #
    # Flags:
    #     -s
    if ! dpkg -s ansible &>/dev/null ; then
        echo "Installing Ansible..."
        ${1:+sudo} apt-get -qq update
        ${1:+sudo} apt-get -qq install -y ansible python3-apt
    fi

    if ! dpkg -s curl &>/dev/null ; then
        echo "Installing Curl..."
        ${1:+sudo} apt-get -qq update
        ${1:+sudo} apt-get -qq install -y curl
    fi

    if ! dpkg -s git &>/dev/null ; then
        echo "Installing Git..."
        ${1:+sudo} apt-get -qq update
        ${1:+sudo} apt-get -qq install -y git
    fi
}

# Configure boostrapping services and utilities for Linux.
setup_linux() {
    local _sudo=1

    if [ $EUID == 0 ]; then
        _sudo=""
    fi

    # Install dependencies for Bootware base on available package manager.
    #
    # Flags:
    #     -v
    if command -v pacman &>/dev/null ; then
        setup_arch "$_sudo"
    elif command -v apt-get &>/dev/null ; then
        setup_debian "$_sudo"
    elif command -v yum &>/dev/null ; then
        setup_redhat "$_sudo"
    else
        error "Unable to find supported package manager."
    fi
}

# Configure boostrapping services and utilities for MacOS.
setup_macos() {
    # Install XCode command line tools if not already installed.
    #
    # Homebrew depends on the XCode command line tools.
    if ! xcode-select -p &>/dev/null ; then
        echo "Installing command line tools for XCode..."
        sudo xcode-select --install
    fi

    # Install Homebrew if not already installed.
    #
    # FLAGS:
    #     -L: Follow redirect request.
    #     -S: Show errors.
    #     -f: Fail silently on server errors.
    #     -s: Disable progress bars.
    if ! check_cmd brew ; then
        echo "Installing Homebrew..."
        curl -LSfs "https://raw.githubusercontent.com/Homebrew/install/master/install.sh" | bash
    fi

    # Install Ansible if not already installed.
    if ! brew list ansible &>/dev/null ; then
        echo "Installing Ansible..."
        brew install ansible
    fi

    # Install Git if not already installed.
    if ! brew list git &>/dev/null ; then
        echo "Installing Git.."
        brew install git
    fi
}

# Configure boostrapping services and utilities for Red Hat distributions.
setup_redhat() {
    # Install dependencies for Bootware.
    if ! yum list installed ansible &>/dev/null ; then
        echo "Installing Ansible..."
        ${1:+sudo} yum check-update
        ${1:+sudo} yum install -y ansible
    fi

    if ! yum list installed curl &>/dev/null ; then
        echo "Installing Curl..."
        ${1:+sudo} yum check-update
        ${1:+sudo} yum install -y curl
    fi

    if ! yum list installed git &>/dev/null ; then
        echo "Installing Git..."
        ${1:+sudo} yum check-update
        ${1:+sudo} yum install git
    fi
}

# Update subcommand.
update() {
    assert_cmd curl

    local _dest
    local _source
    local _sudo=1
    local _version="master"

    _dest=$(realpath $0)

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "update"
                exit 0
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
    if [ -O "$_dest" ] || [ $EUID == 0 ]; then
        _sudo=""
    fi

    echo "Updating Bootware..."

    ${_sudo:+sudo} curl -LSfs "$_source" -o "$_dest"
    ${_sudo:+sudo} chmod 755 "$_dest"

    echo "Updated to version $(bootware --version)."
}

# Get Bootware version string
version() {
    echo "Bootware 0.0.5"
}

# Script entrypoint.
main() {
    assert_cmd chmod
    assert_cmd mkdir
    assert_cmd mktemp
    assert_cmd uname

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            config)
                shift
                config "$@"
                exit 0
                ;;
            bootstrap)
                shift
                bootstrap "$@"
                exit 0
                ;;
            setup)
                shift
                setup "$@"
                exit 0
                ;;
            update)
                shift
                update "$@"
                exit 0
                ;;
            -v|--version)
                version
                exit 0
                ;;
            *)
                ;;
        esac
    done

    usage "main"
}

# Execute main with command line arguments.
main "$@"
