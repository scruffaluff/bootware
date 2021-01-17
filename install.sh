#!/bin/bash
# shellcheck shell=bash
# Exit immediately if a command exists with a non-zero status.
set -e


# Show CLI help information.
#
# Cannot use function name help, since help is a pre-existing command.
usage() {
    cat 1>&2 <<EOF
$(version)
Boostrapping software installer

USAGE:
    bootware [OPTIONS]

OPTIONS:
    -h, --help       Print help information
    -v, --version    Print version information
EOF
}

# Assert that command can be found on machine.
assert_cmd() {
    if ! check_cmd "$1" ; then
        error "Cannot find $1 command on computer."
    fi
}

# Check if command can be found on machine.
check_cmd() {
    command -v "$1" > /dev/null 2>&1
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
    local _version
    local _source

    _version="master"

    # Parse command line arguments.
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                _version="$2"
                ;;
            *)
                ;;
        esac
    done

    _source="https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/$_version/bootware.sh"

    echo "Installing Bootware..."

    if [[ "$EUID" == 0 ]] ; then
        _dest="/usr/local/bin/bootware"
        _dest_dir="/usr/local/bin/"
    else
        _dest="$HOME/.local/bin/bootware"
        _dest_dir="$HOME/.local/bin/"
    fi

    mkdir -p "$_dest_dir"
    curl -LSfs "$_source" -o "$_dest"
    chmod 755 "$_dest"

    if [[ ":$PATH:" == *":$_dest_dir:"* ]]; then
        printf "# Added by Bootware installer.\nexport PATH=\"$_dest_dir:\$PATH\"" >> "$HOME/.bashrc"
    fi

    echo "Installed $(bootware --version)."
}

# Execute main with command line arguments.
main "$@"
