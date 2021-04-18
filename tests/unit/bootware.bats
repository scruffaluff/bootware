#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load "../../node_modules/bats-support/load"
  load "../../node_modules/bats-assert/load"
  source bootware.sh

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG="true"
  export BOOTWARE_NOPASSWD=""

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  ansible-playbook() {
    echo "ansible-playbook $*"
  }
  export -f ansible-playbook

  ansible-pull() {
    echo "ansible-pull $*"
  }
  export -f ansible-pull
}

@test "Throw error for unkown subcommand" {
  run bootware.sh notasubcommand
  assert_equal "${status}" 2
  assert_output --partial "No such subcommand 'notasubcommand'"
}

@test "Find config returns given file if it is executable" {
  local actual
  local expected="/usr/bin/bash"

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

@test "Check passing Ansible arguments for bootstrap subcommand" {
  local actual
  local expected="ansible-playbook --ask-become-pass --connection local --extra-vars ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none main.yaml"

  actual="$(bootware.sh bootstrap --dev --tags none)"
  assert_equal "${actual}" "${expected}"
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
