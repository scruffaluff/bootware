#!/usr/bin/env bats


load "../../node_modules/bats-support/load"
load "../../node_modules/bats-assert/load"

# Disable logging to simplify stdout for testing.
export BOOTWARE_NOLOG=1
export BOOTWARE_NOPASSWD=""

# Mock ansible-pull for child processes by printing received arguments.
#
# Args:
#   -f: Use override as a function instead of a variable.
ansible-pull() { 
  echo "ansible-pull ${*}" 
}
export -f ansible-pull

# Mock ansible-playbook for child processes by printing received arguments.
#
# Args:
#   -f: Use override as a function instead of a variable.
ansible-playbook() { 
  echo "ansible-playbook ${*}" 
}
export -f ansible-playbook


@test "Throw error for unkown subcommand" {
  run ./bootware.sh notasubcommand
  assert_equal "${status}" 2
  assert_output --partial "No such subcommand 'notasubcommand'."
}

@test "Check passing Ansible arguments" {
  local actual
  local expected="ansible-playbook --ask-become-pass --connection local --extra-vars ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none main.yaml"

  actual="$(./bootware.sh bootstrap --dev --tags none)"
  assert_equal "${actual}" "${expected}"
}
