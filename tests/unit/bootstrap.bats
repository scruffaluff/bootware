#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031 shell=bash

setup() {
  export PATH="${BATS_TEST_DIRNAME}/../..:${PATH}"
  load '../../node_modules/bats-support/load'
  load '../../node_modules/bats-assert/load'
  BATS_SOURCE_ONLY='true' source bootware.sh

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'
  # Set BOOTWARE_NOPASSWD to a specific value, to avoid external effects from a
  # user's environment.
  export BOOTWARE_NOPASSWD=''

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  ansible-playbook() {
    # shellcheck disable=SC2317
    echo "ansible-playbook $*"
  }
  export -f ansible-playbook

  ansible-pull() {
    # shellcheck disable=SC2317
    echo "ansible-pull $*"
  }
  export -f ansible-pull
}

@test 'Bootstrap subcommand finds first task associated with role' {
  local actual expected
  export BOOTWARE_NOPASSWD='true'
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  expected="ansible-playbook --extra-vars ansible_become_method=sudo \
--extra-vars ansible_python_interpreter=auto_silent \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, \
--start-at-task Install Deno for Alpine --connection local playbook.yaml"

  actual="$(bootware.sh bootstrap --dev --start-at-role deno)"
  assert_equal "${actual}" "${expected}"
}

@test 'Bootstrap subcommand passes pull arguments to Ansible' {
  local actual expected
  export BOOTWARE_NOPASSWD='true'
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  expected="ansible-pull --extra-vars ansible_become_method=sudo --extra-vars \
ansible_python_interpreter=auto_silent --extra-vars \
@${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --url \
https://github.com/scruffaluff/bootware.git playbook.yaml"

  actual="$(bootware.sh bootstrap)"
  assert_equal "${actual}" "${expected}"
}

@test 'Bootstrap subcommand passes dev arguments to Ansible' {
  local actual expected
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  expected="ansible-playbook --ask-become-pass --extra-vars \
ansible_become_method=sudo --extra-vars \
ansible_python_interpreter=auto_silent --extra-vars \
@${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none \
--connection local playbook.yaml"

  actual="$(bootware.sh bootstrap --dev --tags none)"
  assert_equal "${actual}" "${expected}"
}

@test 'Bootstrap subcommand passes extra arguments to Ansible' {
  local actual expected
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  expected="ansible-playbook --ask-become-pass --extra-vars \
ansible_become_method=sudo --extra-vars ansible_python_interpreter=auto_silent \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none \
--check --timeout 60 --connection local playbook.yaml"

  actual="$(bootware.sh bootstrap --check --dev --tags none --timeout 60)"
  assert_equal "${actual}" "${expected}"
}

@test 'Bootstrap subcommand passes Windows SSH arguments to Ansible' {
  local actual expected
  export BOOTWARE_TAGS=''

  expected="ansible-playbook --extra-vars ansible_pkg_mgr=scoop \
--extra-vars ansible_python_interpreter=auto_silent \
--extra-vars ansible_shell_type=powershell \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 192.23.0.5, \
--skip-tags sometag --ssh-key /fake/key/path --user fakeuser --connection ssh \
main.yaml"

  actual="$(bootware.sh bootstrap --windows -i 192.23.0.5, --skip sometag \
    --ssh-key /fake/key/path --playbook main.yaml --user fakeuser)"
  assert_equal "${actual}" "${expected}"
}

@test 'Bootstrap subcommand does not set Ansible environment variable' {
  bootstrap
  assert_equal "${ANSIBLE_ENABLE_TASK_DEBUGGER:-}" ''
}

@test 'Bootstrap subcommand sets Ansible environment variable' {
  bootstrap --debug
  assert_equal "${ANSIBLE_ENABLE_TASK_DEBUGGER:-}" 'True'
}

@test 'Bootstrap subcommand uses local copy during start at task' {
  local actual expected tmp_dir
  # Do not use long form --dry-run flag for mktemp. It is not supported on
  # MacOS.
  tmp_dir="$(mktemp -u)"

  export BOOTWARE_NOPASSWD='true'
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  BATS_SOURCE_ONLY='true' source bootware.sh

  # Mock functions for child processes by printing received arguments.
  #
  # Args:
  #   -f: Use override as a function instead of a variable.
  mktemp() {
    echo "${tmp_dir}"
  }
  export -f mktemp

  expected="ansible-playbook --extra-vars ansible_become_method=sudo \
--extra-vars ansible_python_interpreter=auto_silent --extra-vars \
@${HOME}/.bootware/config.yaml --inventory 127.0.0.1, \
--start-at-task Install Deno for Alpine --connection local \
${tmp_dir}/playbook.yaml"

  actual="$(bootstrap --start-at-role deno)"
  assert_equal "${actual}" "${expected}"
}
