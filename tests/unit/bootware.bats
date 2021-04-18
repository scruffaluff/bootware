#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load "../../node_modules/bats-support/load"
  load "../../node_modules/bats-assert/load"
  source bootware.sh

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG="true"
}

@test "Throw error for unkown subcommand" {
  run bootware.sh notasubcommand
  assert_equal "${status}" 2
  assert_output --partial "No such subcommand 'notasubcommand'"
}

@test "Find config returns given file if it is executable" {
  local actual
  local expected="/bin/bash"

  find_config_path "${expected}"
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}

@test "Find config returns environment variable if set" {
  local actual
  local expected="/usr/bin/cat"

  BOOTWARE_CONFIG="${expected}" find_config_path
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}

@test "Find config returns default if given file is not executable" {
  local actual
  local expected="${HOME}/.bootware/config.yaml"

  find_config_path "/dev/null"
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}
