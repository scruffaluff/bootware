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
    bootware config [FLAGS]

FLAGS:
    -h, --help       Print help information
    -v, --version    Print version information
EOF
            ;;
        install)
            cat 1>&2 <<EOF
Bootware install
Boostrap install computer software

USAGE:
    bootware [FLAGS] [OPTIONS]

FLAGS:
    -h, --help       Print help information
    -v, --version    Print version information

OPTIONS:
    -c, --config     Path to bootware user configuation file
        --tag        Ansible playbook tag
EOF
            ;;
        main)
            cat 1>&2 <<EOF
Bootware $(version)
Boostrapping software installer

USAGE:
    bootware [FLAGS] [SUBCOMMAND]

FLAGS:
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
    bootware update [FLAGS]

FLAGS:
    -h, --help       Print help information
    -v, --version    Print version information
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
    local _ip_flag
    local _os_type

    # Get operating system for local machine.
    #
    # Flags:
    #     -s: Print the kernel name.
    _os_type=$(uname -s)

    echo "Launching Bootware Docker container..."
    echo "Enter your user account password when prompted."

    case "$_os_type" in
        Darwin)
            _ip_flag=()
            ;;
        Linux)
            find_docker_ip
            _ip_flag=( "--add-host" "host.docker.internal:$RET_VAL" )
            ;;
        *)
            error "Operting system $_os_type is not supported."
            ;;
    esac

    if [ -z ${EUCLID_PASSWORDLESS_SUDO+x} ]; then
        bootstrap_password "$1" "$2" "$3" "${_ip_flag[@]}"
    else
        bootstrap_passwordless "$1" "$2" "$3" "${_ip_flag[@]}"
    fi
}

# Launch Docker container to boostrap software installation for Linux.
bootstrap_password() {
    sudo docker run \
        -it \
        -v "$1:/root/.ssh/bootware" \
        -v "$2:/bootware/host_vars/host.docker.internal.yaml" \
        --rm \
        ${4:+"$4"} ${5:+"$5"} \
        wolfgangwazzlestrauss/bootware:latest \
        --ask-become-pass \
        --tag "$3" \
        --user "$USER" \
        main.yaml
}

# Launch Docker container to boostrap software installation for MacOS.
bootstrap_passwordless() {
    sudo docker run \
        -v "$1:/root/.ssh/bootware" \
        -v "$2:/bootware/host_vars/host.docker.internal.yaml" \
        --rm \
        ${4:+"$4"} ${5:+"$5"} \
        wolfgangwazzlestrauss/bootware:latest \
        --tag "$3" \
        --user "$USER" \
        main.yaml
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
    # Flags:
    #     -L: Follow redirect request.
    #     -S: Show errors.
    #     -f: Use archive file. Must be third flag.
    #     -o <path>: Write output to path instead of stdout. 
    curl -LSf \
        https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml \
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
    elif [[ -n "${EUCLID_CONFIG}" ]] ; then
        RET_VAL="$EUCLID_CONFIG"
    elif test -f "$HOME/bootware.yaml" ; then
        RET_VAL="$HOME/bootware.yaml"
    else
        error "Unable to find Bootware configuation file."
    fi

    echo "Using $RET_VAL as configuration file."
}

# Find IP address of host machine that is accessible from Docker.
find_docker_ip() {
    local _docker_ip
    _docker_ip=$(sudo docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')

    # Check if Docker IP is not null.
    #
    # Flags:
    #     -z: True if string has zero length.
    if [ -z "$_docker_ip" ]; then
        error "Unable to find Docker host IP address. Restart Docker and try again."
    fi

    RET_VAL="$_docker_ip"
}

# Create temporary SSH key for Ansible.
generate_keys() {
    local _private_key
    local _public_key

    echo "Generating and authorizing temporary SSH keys..."

    # Generate a temporary paths.
    #
    # Flags:
    #     -u: Do not create files. Only print path name.
    _private_key=$(mktemp -u)
    _public_key="$_private_key.pub"

    # Generate SSH private and public keys.
    #
    # Flags:
    #     -q: Silence ssh-keygen.
    #     -N "": Do not associate a password with the key.
    #     -b 4096: Number of bits in key to create.
    #     -f <path>: Filename of the key file.
    #     -t rsa: Use RSA cryptosystem.
    ssh-keygen -q -N "" -b 4096 -f "$_private_key" -t rsa

    # Create SSH directory with correct permissions.
    #
    # Flags:
    #     -p: Make parent directories as needed.
    #     -R: Apply modifications recursivley to a directory.
    #     700: Give no permissions to other users.
    mkdir -p "$HOME/.ssh/" && chmod -R 700 "$HOME/.ssh/"
    cat "$_public_key" >> "$HOME/.ssh/authorized_keys"

    RET_VAL="$_private_key"
}

# Install subcommand.
install() {
    # Dev null is never a normal file.
    local _config_path="/dev/null"
    local _private_key
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

    prepare

    find_config_path "$_config_path"
    _config_path="$RET_VAL"

    generate_keys
    _private_key="$RET_VAL"

    bootstrap "$_private_key" "$_config_path" "$_tag"
}

# Configure boostrapping services and utilities.
prepare() {
    local _os_type

    # Get operating system for local machine.
    #
    # Flags:
    #     -s: Print the kernel name.
    _os_type=$(uname -s)

    case "$_os_type" in
        Darwin)
            prepare_macos
            ;;
        Linux)
            prepare_linux
            ;;
        *)
            error "Operting system $_os_type is not supported."
            ;;
    esac
}

# Configure boostrapping services and utilities for Linux.
prepare_linux() {
    assert_cmd apt-get
    assert_cmd dpkg

    # dpkg -l does not always return the correct exit code. dpkg -s does. See
    # https://github.com/bitrise-io/bitrise/issues/433#issuecomment-256116057
    # for more information.
    if ! dpkg -s docker.io &>/dev/null ; then
        echo "Installing Docker..."
        sudo apt-get -qq update && sudo apt-get -qq install -y docker.io

        # Docker gateway IP is not always available after installation. A
        # restart is believed to help.
        sudo systemctl restart docker
    fi

    # dpkg -l does not always return the correct exit code. dpkg -s does. See
    # https://github.com/bitrise-io/bitrise/issues/433#issuecomment-256116057
    # for more information.
    if ! dpkg -s ssh &>/dev/null ; then
        echo "Installing OpenSSH..."
        sudo apt-get -qq update && sudo apt-get -qq install -y ssh

        # OpenSSH server is not always available after installation. A restart
        # is believed to help.
        sudo systemctl restart ssh
    fi
}

# Configure boostrapping services and utilities for MacOS.
prepare_macos() {
    local _remote_login

    # Check if remote login is available.
    #
    # Remote login is required for SSH connections.
    _remote_login=$(sudo systemsetup -getremotelogin)
    if ! grep -q "On" <<< "$_remote_login" ; then
        error "Remote login is not enabled. Turn it on in System Preferences > Sharing."

        # echo "Enabling remote login for current user..."
        # sudo systemsetup -setremotelogin on
    fi

    # Install XCode command line tools if not already installed.
    #
    # Homebrew depends on the XCode command line tools.
    if ! xcode-select -p &>/dev/null ; then
        echo "Installing command line tools for XCode..."
        sudo xcode-select --install
    fi

    # Install Homebrew if not already installed.
    #
    # Flags:
    #     -L: Follow redirect request.
    #     -S: Show errors.
    #     -f: Fail silently on server errors.
    #     -s: Disable progress bars.
    if ! check_cmd brew ; then
        echo "Installing Homebrew..."
        curl -LSfs https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash
    fi

    # Install Docker Desktop if not already installed.
    #
    # Flags:
    #     ---background:
    if ! brew list --cask docker &>/dev/null ; then
        echo "Installing Docker..."
        brew cask install docker
        open --background /Applications/Docker.app
    fi

    # Install OpenSSH client and server if not already installed.
    if ! brew list openssh &>/dev/null ; then
        echo "Installing OpenSSH..."
        brew install openssh
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
    # Flags:
    #     -s: Print the kernel name.
    _os_type=$(uname -s)

    echo "Updating Bootware..."

    case "$_os_type" in
        Darwin)
            sudo mkdir -p /usr/local/bin/
            sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh -o /usr/local/bin/bootware
            sudo chmod 755 /usr/local/bin/bootware
            echo 'export PATH="$PATH:/usr/local/bin"' >> "$HOME/.profile"
            export PATH="$PATH:/usr/local/bin"
            ;;
        Linux)
            sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh -o /usr/local/bin/bootware
            sudo chmod 755 /usr/local/bin/bootware
            ;;
        *)
            error "Operting system $_os_type is not supported."
            ;;
    esac

    echo "Updated Bootware to version $(bootware --version)"
}

# Get Bootware version string
version() {
    echo "0.0.1"
}

# Script entrypoint.
main() {
    assert_cmd chmod
    assert_cmd mkdir
    assert_cmd mktemp
    assert_cmd uname

    local _version

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
                version
                exit 0
                ;;
            *)
                ;;
        esac
    done

    usage "main"
}

# Execute main with command line arguments and call exit on failure.
main "$@" || exit 1
