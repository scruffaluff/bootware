#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load '../../node_modules/bats-support/load'
  load '../../node_modules/bats-assert/load'

  # Disable logging to simplify stdout for testing.
  export INSTALL_NOLOG='true'

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  command() {
    # shellcheck disable=SC2317
    if [[ "${2}" == 'doas' ]]; then
      echo ''
    else
      echo '/bin/bash'
    fi
  }
  export -f command

  curl() {
    # shellcheck disable=SC2317
    echo "curl $*"
    # shellcheck disable=SC2317
    exit 0
  }
  export -f curl
}

@test 'Installer passes local path to Curl' {
  local actual
  local expected="curl --fail --location --show-error --silent --output \
${HOME}/.local/bin/bootware \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/bootware.sh"

  actual="$(bash install.sh --user --version develop)"
  assert_equal "${actual}" "${expected}"
}

@test 'Installer uses sudo when destination is not writable' {
  local actual expected

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  sudo() {
    echo "sudo $*"
    exit 0
  }
  export -f sudo

  expected='sudo mkdir -p /bin'
  actual="$(bash install.sh --dest /bin/bash)"
  assert_equal "${actual}" "${expected}"
}
