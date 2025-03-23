#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2317

setup() {
  REPO_PATH="${BATS_TEST_DIRNAME}/../.."
  cd "${REPO_PATH}" || exit
  load "${REPO_PATH}/.vendor/lib/bats-assert/load"
  load "${REPO_PATH}/.vendor/lib/bats-file/load"
  load "${REPO_PATH}/.vendor/lib/bats-support/load"
  bats_require_minimum_version 1.5.0

  # Disable logging to simplify stdout for testing.
  export BOOTWARE_NOLOG='true'
  # Set BOOTWARE_NOPASSWD to a specific value, to avoid external effects from a
  # user's environment.
  export BOOTWARE_NOPASSWD=''
  # Disable installing software during test runs.
  export BOOTWARE_NOSETUP='true'

  # Mock functions for child processes by printing received arguments.
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

bootstrap_subcommand_finds_first_task_associated_with_role() { # @test
  export BOOTWARE_NOPASSWD='true'
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  run bash bootware.sh bootstrap --dev --start-at-role deno
  assert_success
  assert_output "ansible-playbook --extra-vars ansible_become_method=sudo \
--extra-vars ansible_python_interpreter=auto_silent \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, \
--start-at-task Install Deno for Alpine --connection local playbook.yaml"
}

bootstrap_subcommand_passes_pull_arguments_to_ansible() { # @test
  export BOOTWARE_NOPASSWD='true'
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  run bash bootware.sh bootstrap
  assert_success
  assert_output "ansible-pull --extra-vars ansible_become_method=sudo --extra-vars \
ansible_python_interpreter=auto_silent --extra-vars \
@${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --url \
https://github.com/scruffaluff/bootware.git playbook.yaml"
}

bootstrap_subcommand_passes_dev_arguments_to_ansible() { # @test
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  run bash bootware.sh bootstrap --dev --tags none
  assert_success
  assert_output "ansible-playbook --ask-become-pass --extra-vars \
ansible_become_method=sudo --extra-vars \
ansible_python_interpreter=auto_silent --extra-vars \
@${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none \
--connection local playbook.yaml"
}

bootstrap_subcommand_passes_extra_arguments_to_ansible() { # @test
  export BOOTWARE_SKIP=''
  export BOOTWARE_TAGS=''

  run bash bootware.sh bootstrap --check --dev --tags none --timeout 60
  assert_success
  assert_output "ansible-playbook --ask-become-pass --extra-vars \
ansible_become_method=sudo --extra-vars ansible_python_interpreter=auto_silent \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 127.0.0.1, --tags none \
--check --timeout 60 --connection local playbook.yaml"
}

bootstrap_subcommand_passes_windows_ssh_arguments_to_ansible() { # @test
  export BOOTWARE_TAGS=''

  run bash bootware.sh bootstrap --windows -i 192.23.0.5, --skip sometag \
    --ssh-key /fake/key/path --playbook main.yaml --user fakeuser
  assert_success
  assert_output "ansible-playbook --extra-vars ansible_pkg_mgr=scoop \
--extra-vars ansible_python_interpreter=auto_silent \
--extra-vars ansible_shell_type=powershell \
--extra-vars @${HOME}/.bootware/config.yaml --inventory 192.23.0.5, \
--skip-tags sometag --ssh-key /fake/key/path --user fakeuser --connection ssh \
main.yaml"
}

bootstrap_subcommand_does_not_set_snsible_environment_variable() { # @test
  BATS_SOURCE_ONLY='true' source bootware.sh
  bootstrap
  assert_equal "${ANSIBLE_ENABLE_TASK_DEBUGGER:-}" ''
}

bootstrap_subcommand_sets_ansible_environment_variable() { # @test
  BATS_SOURCE_ONLY='true' source bootware.sh
  bootstrap --debug
  assert_equal "${ANSIBLE_ENABLE_TASK_DEBUGGER:-}" 'True'
}

bootstrap_subcommand_uses_local_copy_during_start_at_task() { # @test
  local tmp_dir
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

  run bootstrap --start-at-role deno
  assert_success
  assert_output "ansible-playbook --extra-vars ansible_become_method=sudo \
--extra-vars ansible_python_interpreter=auto_silent --extra-vars \
@${HOME}/.bootware/config.yaml --inventory 127.0.0.1, \
--start-at-task Install Deno for Alpine --connection local \
${tmp_dir}/playbook.yaml"
}
