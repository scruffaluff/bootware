#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
  REPO_PATH="${BATS_TEST_DIRNAME}/../.."
  cd "${REPO_PATH}" || exit
  load "${REPO_PATH}/.vendor/lib/bats-assert/load"
  load "${REPO_PATH}/.vendor/lib/bats-file/load"
  load "${REPO_PATH}/.vendor/lib/bats-support/load"
  bats_require_minimum_version 1.5.0

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'
}

bootware_throws_error_for_unknown_subcommand() { # @test
  run bash src/bootware.sh notasubcommand
  assert_failure 2
  assert_output --partial "No such subcommand or option 'notasubcommand'"
}

function_find_config_path_returns_given_executable_files() { # @test
  BATS_SOURCE_ONLY='true' source src/bootware.sh
  find_config_path '/bin/bash'
  actual="${RET_VAL}"
  assert_equal "${actual}" '/bin/bash'
}

function_find_config_path_returns_environment_variable() { # @test
  BATS_SOURCE_ONLY='true' source src/bootware.sh
  BOOTWARE_CONFIG='/usr/bin/cat' find_config_path
  actual="${RET_VAL}"
  assert_equal "${actual}" '/usr/bin/cat'
}

function_find_config_path_returns_default_when_given_non_executable_file() { # @test
  BATS_SOURCE_ONLY='true' source src/bootware.sh
  find_config_path '/dev/null'
  actual="${RET_VAL}"
  assert_equal "${actual}" "${HOME}/.bootware/config.yaml"
}
