#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  REPO_PATH="${BATS_TEST_DIRNAME}/../.."
  cd "${REPO_PATH}" || exit
  load "${REPO_PATH}/.vendor/lib/bats-assert/load"
  load "${REPO_PATH}/.vendor/lib/bats-file/load"
  load "${REPO_PATH}/.vendor/lib/bats-support/load"
  bats_require_minimum_version 1.5.0

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

installer_passes_local_path_to_curl() { # @test
  local actual
  local expected="curl --fail --location --show-error --silent --output \
${HOME}/.local/bin/bootware \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/bootware.sh"

  actual="$(bash install.sh --user --version develop)"
  assert_equal "${actual}" "${expected}"
}

installer_uses_sudo_when_destination_is_not_writable() { # @test
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
