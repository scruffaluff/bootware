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

  command() {
    echo '/bin/bash'
  }
  chmod() { :; }
  curl() {
    echo "curl $*"
  }
  mkdir() { :; }
  export -f command chmod curl mkdir
}

update_subcommand_passes_bootware_executable_path_to_curl() { # @test
  bootware() { :; }
  export -f bootware

  run bash src/bootware.sh update --version develop
  assert_success
  assert_output "curl --fail --location --show-error --silent \
--output $(realpath "${BATS_TEST_DIRNAME}"/../../src/bootware.sh) \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/src/bootware.sh
curl --fail --location --show-error --silent \
--output ${HOME}/.local/share/bash-completion/completions/bootware \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/src/completion/bootware.bash
curl --fail --location --show-error --silent \
--output ${HOME}/.config/fish/completions/bootware.fish \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/src/completion/bootware.fish"
}

functon_update_uses_sudo_when_destination_is_not_writable() { # @test
  BATS_SOURCE_ONLY='true' source src/bootware.sh
  find_super() {
    echo 'sudo'
  }
  fullpath() {
    echo '/bin/bash'
  }
  sudo() {
    echo "sudo $*"
    exit 0
  }
  export -f find_super fullpath sudo

  run update
  assert_success
  assert_output 'sudo mkdir -p /bin'
}
