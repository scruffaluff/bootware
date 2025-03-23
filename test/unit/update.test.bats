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

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  command() {
    # shellcheck disable=SC2317
    echo '/bin/bash'
  }
  export -f command

  chmod() {
    # shellcheck disable=SC2317
    :
  }
  export -f chmod

  curl() {
    # shellcheck disable=SC2317
    echo "curl $*"
  }
  export -f curl

  mkdir() {
    # shellcheck disable=SC2317
    :
  }
  export -f mkdir
}

update_subcommand_passes_bootware_executable_path_to_curl() { # @test
  run bash bootware.sh update --version develop
  assert_success
  assert_output "curl -LSfs \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/bootware.sh \
--output $(realpath "${BATS_TEST_DIRNAME}"/../../bootware.sh)
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/develop/completions/bootware.bash \
--output ${HOME}/.local/share/bash-completion/completions/bootware
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/develop/completions/bootware.fish \
--output ${HOME}/.config/fish/completions/bootware.fish"
}

functon_update_uses_sudo_when_destination_is_not_writable() { # @test
  BATS_SOURCE_ONLY='true' source bootware.sh
  fullpath() {
    echo '/bin/bash'
  }
  sudo() {
    echo "sudo $*"
    exit 0
  }
  export -f fullpath sudo

  run update
  assert_success
  assert_output "sudo curl -LSfs \
https://raw.githubusercontent.com/scruffaluff/bootware/main/bootware.sh \
--output /bin/bash"
}
