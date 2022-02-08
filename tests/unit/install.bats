#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load "../../node_modules/bats-support/load"
  load "../../node_modules/bats-assert/load"

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG="true"

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  command() {
    echo "/bin/bash"
  }
  export -f command

  curl() {
    echo "curl $*"
    exit 0
  }
  export -f curl
}

@test "Installer passes local path to Curl" {
  local actual
  local expected="curl -LSfs \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/bootware.sh \
-o ${HOME}/.local/bin/bootware"

  actual="$(install.sh --user --version develop)"
  assert_equal "${actual}" "${expected}"
}

@test "Installer uses sudo when destination is not writable" {
  local actual
  local expected

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  sudo() {
    echo "sudo $*"
    exit 0
  }
  export -f sudo

  expected="sudo mkdir -p /bin"
  actual="$(install.sh --dest /bin/bash)"
  assert_equal "${actual}" "${expected}"
}
