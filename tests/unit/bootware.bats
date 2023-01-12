#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load '../../node_modules/bats-support/load'
  load '../../node_modules/bats-assert/load'
  source bootware.sh

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'
}

@test 'Bootware throws error for unkown subcommand' {
  run bootware.sh notasubcommand
  assert_equal "${status}" 2
  assert_output --partial "No such subcommand 'notasubcommand'"
}

@test 'Function find_config_path returns given executable files' {
  local actual
  local expected='/bin/bash'

  find_config_path "${expected}"
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}

@test 'Function find_config_path returns environment variable' {
  local actual
  local expected='/usr/bin/cat'

  BOOTWARE_CONFIG="${expected}" find_config_path
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}

@test 'Function find_config_path returns default when given non-executable file' {
  local actual
  local expected="${HOME}/.bootware/config.yaml"

  find_config_path '/dev/null'
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}
