#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load '../../node_modules/bats-support/load'
  load '../../node_modules/bats-assert/load'
  BATS_SOURCE_ONLY='true' source bootware.sh

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'
}

@test 'Bootware throws error for unknown subcommand' {
  run bootware.sh notasubcommand
  assert_equal "${status}" 2
  assert_output --partial "No such subcommand or option 'notasubcommand'"
}

@test 'Function find_config_path returns given executable files' {
  local actual expected='/bin/bash'

  find_config_path "${expected}"
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}

@test 'Function find_config_path returns environment variable' {
  local actual expected='/usr/bin/cat'

  BOOTWARE_CONFIG="${expected}" find_config_path
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}

@test 'Function find_config_path returns default when given non-executable file' {
  local actual expected="${HOME}/.bootware/config.yaml"

  find_config_path '/dev/null'
  actual="${RET_VAL}"
  assert_equal "${actual}" "${expected}"
}
