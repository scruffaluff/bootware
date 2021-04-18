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

@test "Bootstrap subcommand passes pull arguments to Ansible" {
  local actual
  local expected="ansible-pull --extra-vars ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --url https://github.com/wolfgangwazzlestrauss/bootware.git main.yaml"

  export BOOTWARE_NOPASSWD=1

  actual="$(bootware.sh bootstrap)"
  assert_equal "${actual}" "${expected}"
}

@test "Bootstrap subcommand passes dev arguments to Ansible" {
  local actual
  local expected="ansible-playbook --ask-become-pass --connection local --extra-vars ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none main.yaml"

  actual="$(bootware.sh bootstrap --dev --tags none)"
  assert_equal "${actual}" "${expected}"
}

@test "Bootstrap subcommand passes WinRM arguments to Ansible" {
  local actual
  local expected="ansible-playbook --ask-pass --connection winrm --extra-vars ansible_pkg_mgr=scoop --extra-vars ansible_python_interpreter=auto_silent --extra-vars ansible_user=fakeuser --extra-vars ansible_winrm_server_cert_validation=ignore --extra-vars ansible_winrm_transport=basic --extra-vars user_account=fakeuser --extra-vars @${HOME}/.bootware/config.yaml --inventory 192.23.0.5, --skip-tags sometag main.yaml"

  actual="$(bootware.sh bootstrap --winrm -i 192.23.0.5, --skip sometag --user fakeuser)"
  assert_equal "${actual}" "${expected}"
}
