#!/usr/bin/env bash
# shellcheck shell=bash
# Exit immediately if a command exists with a non-zero status.
set -e


# Show CLI help information.
#
# Cannot use function name help, since help is a pre-existing command.
usage() {
    cat 1>&2 <<EOF
$(version)
Installer script for Bootware

USAGE:
    bootware-installer [OPTIONS]

OPTIONS:
    -d, --dest string       Location to install bootware
    -h, --help              Print help information
    -u, --user              Install bootware for current user
    -v, --version string    Version of Bootware to install
EOF
}

# Assert that command can be found on machine.
assert_cmd() {
    if ! check_cmd "$1" ; then
        error "Cannot find $1 command on computer. Please install and retry installation."
    fi
}

# Check if command can be found on machine.
check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

# Configure path for user's shell.
configure_shell() {
    local _export="export PATH=\"$1:\$PATH\""
    local _profile
    local _shell

    _shell=$(basename "$SHELL")

    case "$_shell" in
        bash)
            _profile="$HOME/.bashrc"
            ;;
        zsh)
            _profile="$HOME/.zshrc"
            ;;
        ksh)
            _profile="$HOME/.profile"
            ;;
        fish)
            _export="set -x PATH \"$1\" \$PATH"
            _profile="$HOME/.config/fish/config.fish"
            ;;
        *)
            error "Shell $_shell is not supported."
            ;;
    esac

    printf "\n# Added by Bootware installer.\n$_export\n" >> "$_profile"
}

# Print error message and exit with error code.
error() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

# Script entrypoint.
main() {
    assert_cmd curl

    local _dest
    local _dest_dir
    local _source
    local _user
    local _version="master"

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--dest)
                shift
                _dest="$2"
                ;;
            -u|--user)
                _user=1
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
    if [[ "$_user" == 1 ]] ; then
        _dest="$HOME/.local/bin/bootware"
        _sudo=""
    else
        assert_cmd sudo
        _dest="/usr/local/bin/bootware"
        _sudo=sudo
    fi
    _dest_dir=$(dirname "$_dest")

    echo "Installing Bootware..."

    ${_sudo} mkdir -p "$_dest_dir"
    ${_sudo} curl -LSfs "$_source" -o "$_dest"
    ${_sudo} chmod 755 "$_dest"

    if ! command -v bootware > /dev/null; then
        configure_shell "$_dest_dir"
        export PATH="$_dest_dir:$PATH"
    fi

    echo "Installed $(bootware --version)."
}

# Execute main with command line arguments.
main "$@"
