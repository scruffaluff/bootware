#!/bin/bash
# shellcheck shell=bash
# Exit immediately if a command exists with a non-zero status.
set -e


# Show CLI help information.
#
# Cannot use function name help, since help is a pre-existing command.
usage() {
    case "$1" in
        config)
            cat 1>&2 <<EOF
Bootware config
Generate default Bootware configuration file

USAGE:
    bootware config [OPTIONS]

OPTIONS:
    -h, --help       Print help information
EOF
            ;;
        install)
            cat 1>&2 <<EOF
Bootware install
Boostrap install computer software

USAGE:
    bootware install [OPTIONS]

OPTIONS:
    -c, --config     Path to bootware user configuation file
    -h, --help       Print help information
        --tag string Ansible playbook tag
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
    config           Generate default Bootware configuration file
    install          Boostrap install computer software
    update           Update Bootware to latest version
EOF
            ;;
        update)
            cat 1>&2 <<EOF
Bootware update
Update Bootware to latest version

USAGE:
    bootware update [OPTIONS]

OPTIONS:
    -h, --help       Print help information
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

# Launch Docker container to boostrap software installation.
bootstrap() {
    echo "Launching Ansible pipeline..."
    echo "Enter your user account password when prompted."

    if [[ "$BOOTWARE_NOPASSWD" ]]; then
        ansible-pull \
            --extra-vars "user_account=$USER" \
            --extra-vars "@$1" \
            --inventory 127.0.0.1, \
            --tag "$2" \
            --url https://github.com/wolfgangwazzlestrauss/bootware.git \
            main.yaml
    else
        ansible-pull \
            --ask-become-pass \
            --extra-vars "user_account=$USER" \
            --extra-vars "@$1" \
            --inventory 127.0.0.1, \
            --tag "$2" \
            --url https://github.com/wolfgangwazzlestrauss/bootware.git \
            main.yaml
    fi
}

# Check if command can be found on machine.
check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

# Config subcommand.
config() {
    assert_cmd curl

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "config"
                exit 0
                ;;
            *)
                ;;
        esac
    done

    echo "Downloading default configuration file to $HOME/bootware.yaml..."

    # Download default configuration file.
    #
    # FLAGS:
    #     -L: Follow redirect request.
    #     -S: Show errors.
    #     -f: Use archive file. Must be third flag.
    #     -o <path>: Write output to path instead of stdout. 
    curl -LSf \
        "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml" \
        -o "$HOME/bootware.yaml"
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
    elif test -f "$HOME/bootware.yaml" ; then
        RET_VAL="$HOME/bootware.yaml"
    else
        error "Unable to find Bootware configuation file."
    fi

    echo "Using $RET_VAL as configuration file."
}

# Install subcommand.
install() {
    # Dev null is never a normal file.
    local _config_path="/dev/null"
    local _tag="all"

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "install"
                exit 0
                ;;
            -c|--config)
                _config_path="$2"
                # Remove two arguments from arguments list.
                shift
                shift
                ;;
            --tag)
                _tag="$2"
                # Remove two arguments from arguments list.
                shift
                shift
                ;;
            *)
                ;;
        esac
    done

    if [[ ! "$BOOTWARE_NOSETUP" ]]; then
        setup
    fi

    find_config_path "$_config_path"
    _config_path="$RET_VAL"

    bootstrap "$_config_path" "$_tag"
}

# Configure boostrapping services and utilities.
setup() {
    local _os_type

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

# Configure boostrapping services and utilities for Linux.
setup_linux() {
    assert_cmd apt-get
    assert_cmd dpkg

    # dpkg -l does not always return the correct exit code. dpkg -s does. See
    # https://github.com/bitrise-io/bitrise/issues/433#issuecomment-256116057
    # for more information.
    if ! dpkg -s ansible &>/dev/null ; then
        echo "Installing Ansible..."
        sudo apt-get -qq update && sudo apt-get -qq install -y ansible
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
    #
    # FLAGS:
    #     ---background:
    if ! brew list ansible &>/dev/null ; then
        echo "Installing Docker..."
        brew install ansible
    fi
}

# Update subcommand.
update() {
    local _os_type

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage "update"
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

    echo "Updating Bootware..."

    case "$_os_type" in
        Darwin)
            sudo mkdir -p "/usr/local/bin/"
            sudo curl -LSfs "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh" -o "/usr/local/bin/bootware"
            sudo chmod 755 "/usr/local/bin/bootware"
            if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
                printf "# Added by Bootware installer.\nexport PATH=\"/usr/local/bin\":\$PATH" >> "$HOME/.bashrc"
                export PATH="$PATH:/usr/local/bin"
            fi
            ;;
        Linux)
            sudo curl -LSfs "https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh" -o "/usr/local/bin/bootware"
            sudo chmod 755 "/usr/local/bin/bootware"
            ;;
        *)
            error "Operting system $_os_type is not supported."
            ;;
    esac

    echo "Updated to version $(bootware --version)"
}

# Get Bootware version string
version() {
    echo "Bootware 0.0.4"
}

# Script entrypoint.
main() {
    assert_cmd chmod
    assert_cmd git
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
            install)
                shift
                install "$@"
                exit 0
                ;;
            update)
                shift
                update "$@"
                exit 0
                ;;
            -v|--version)
                shift
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
