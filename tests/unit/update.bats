#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load "../../node_modules/bats-support/load"
  load "../../node_modules/bats-assert/load"

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG="true"
}

@test "Check passing Ansible arguments for update subcommand" {
  local actual
  local expected

  command() {
    echo "/usr/bin/bash"
  }
  export -f command

  sudo() {
    echo "sudo $*"
    exit 0
  }
  export -f sudo

  expected="sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/develop/bootware.sh -o $(realpath "${BATS_TEST_DIRNAME}"/../../bootware.sh)"
  actual="$(bootware.sh update --version develop)"
  assert_equal "${actual}" "${expected}"
}
