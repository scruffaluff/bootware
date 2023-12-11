#!/usr/bin/env bats
# shellcheck shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load '../../node_modules/bats-support/load'
  load '../../node_modules/bats-assert/load'

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

@test 'Update subcommand passes Bootware executable path to Curl' {
  local actual expected

  expected="curl -LSfs \
https://raw.githubusercontent.com/scruffaluff/bootware/develop/bootware.sh \
--output $(realpath "${BATS_TEST_DIRNAME}"/../../bootware.sh)
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/develop/completions/bootware.bash \
-o ${HOME}/.local/share/bash-completion/completions/bootware
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/develop/completions/bootware.fish \
-o ${HOME}/.config/fish/completions/bootware.fish"

  actual="$(bootware.sh update --version develop)"
  assert_equal "${actual}" "${expected}"
}

@test 'Functon update uses sudo when destination is not writable' {
  local actual
  local expected="sudo curl -LSfs \
https://raw.githubusercontent.com/scruffaluff/bootware/main/bootware.sh \
--output /bin/bash"

  BATS_SOURCE_ONLY='true' source bootware.sh

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  fullpath() {
    echo '/bin/bash'
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
