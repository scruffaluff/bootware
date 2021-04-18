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

@test "Check passing Ansible arguments for bootstrap subcommand" {
  local actual
  local expected="ansible-playbook --ask-become-pass --connection local --extra-vars ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none main.yaml"

  actual="$(bootware.sh bootstrap --dev --tags none)"
  assert_equal "${actual}" "${expected}"
}
