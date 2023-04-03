#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load '../../node_modules/bats-support/load'
  load '../../node_modules/bats-assert/load'

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  command() {
    # shellcheck disable=SC2317
    echo '/bin/bash'
  }
  export -f command

  curl() {
    # shellcheck disable=SC2317
    echo "curl $*"
  }
  export -f curl
}

@test 'Config subcommand makes empty configuration log' {
  local actual expected

  expected='Writing empty configuration file to /dev/null'
  actual="$(bootware.sh config -e --dest /dev/null)"
  assert_equal "${actual}" "${expected}"
}

@test 'Config subcommand passes source to Curl' {
  local actual expected

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'

  expected="curl -LSfs https://fakedomain.com --output ${HOME}/.bootware/config.yaml"
  actual="$(bootware.sh config --source https://fakedomain.com)"
  assert_equal "${actual}" "${expected}"
}
