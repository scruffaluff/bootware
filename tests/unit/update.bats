#!/usr/bin/env bats

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
  }
  export -f curl
}

@test "Update subcommand passes Bootware executable path to Curl" {
  local actual
  local expected
  
  expected="curl -LSfs \
https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/develop/bootware.sh \
-o $(realpath "${BATS_TEST_DIRNAME}"/../../bootware.sh)"

  actual="$(bootware.sh update --version develop)"
  assert_equal "${actual}" "${expected}"
}

@test "Functon update uses sudo when destination is not writable" {
  local actual
  local expected="sudo curl -LSfs \
https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh \
-o /bin/bash"

  source bootware.sh

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  fullpath() {
    echo "/bin/bash"
  }
  export -f fullpath

  sudo() {
    echo "sudo $*"
    exit 0
  }
  export -f sudo

  actual="$(update)"
  assert_equal "${actual}" "${expected}"
}
