#!/usr/bin/env bats


# Disable logging to simplify stdout for testing.
export BOOTWARE_NOLOG=1

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
  [ "${status}" -eq 2 ]
}

@test "Check passing Ansible arguments" {
  expected="ansible-playbook --connection local --extra-vars ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none main.yaml"
  actual="$(./bootware.sh bootstrap --dev --tags none)"
  [ "${actual}" = "${expected}" ]
}
