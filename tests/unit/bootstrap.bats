#!/usr/bin/env bats
# shellcheck shell=bash

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
  local expected

  export BOOTWARE_NOPASSWD=1
  export BOOTWARE_TAGS=""

  expected="ansible-pull --extra-vars ansible_python_interpreter=auto_silent \
--extra-vars user_account=${USER} --extra-vars @${HOME}/.bootware/config.yaml \
--inventory 127.0.0.1, --url \
https://github.com/wolfgangwazzlestrauss/bootware.git main.yaml"

  actual="$(bootware.sh bootstrap)"
  assert_equal "${actual}" "${expected}"
}

@test "Bootstrap subcommand passes dev arguments to Ansible" {
  local actual
  local expected
  
  expected="ansible-playbook --ask-become-pass --connection local --extra-vars \
ansible_python_interpreter=auto_silent --extra-vars user_account=${USER} \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none \
main.yaml"

  actual="$(bootware.sh bootstrap --dev --tags none)"
  assert_equal "${actual}" "${expected}"
}

@test "Bootstrap subcommand passes Windows SSH arguments to Ansible" {
  local actual
  local expected

  export BOOTWARE_TAGS=""
  
  expected="ansible-playbook --connection ssh --extra-vars \
ansible_pkg_mgr=scoop --extra-vars ansible_python_interpreter=auto_silent \
--extra-vars ansible_shell_type=powershell --extra-vars \
ansible_ssh_private_key_file=/fake/key/path --extra-vars ansible_user=fakeuser \
--extra-vars user_account=fakeuser --extra-vars @${HOME}/.bootware/config.yaml \
--inventory 192.23.0.5, --skip-tags sometag main.yaml"

  actual="$(bootware.sh bootstrap --windows -i 192.23.0.5, --skip sometag \
    --ssh-key /fake/key/path --user fakeuser)"
  assert_equal "${actual}" "${expected}"
}
