#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
  REPO_PATH="${BATS_TEST_DIRNAME}/../.."
  cd "${REPO_PATH}" || exit
  load "${REPO_PATH}/.vendor/lib/bats-assert/load"
  load "${REPO_PATH}/.vendor/lib/bats-file/load"
  load "${REPO_PATH}/.vendor/lib/bats-support/load"
  bats_require_minimum_version 1.5.0

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

config_subcommand_makes_empty_configuration_log() { # @test
  run bash src/bootware.sh config -e --dest /dev/null
  assert_success
  assert_output 'Writing empty configuration file to /dev/null'
}

config_subcommand_passes_source_to_curl() { # @test
  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'

  run bash src/bootware.sh config --source https://fakedomain.com
  assert_success
  assert_output "curl --fail --location --show-error --silent --output ${HOME}/.bootware/config.yaml https://fakedomain.com"
}
