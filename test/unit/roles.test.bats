#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
  REPO_PATH="${BATS_TEST_DIRNAME}/../.."
  cd "${REPO_PATH}" || exit
  load "${REPO_PATH}/.vendor/lib/bats-assert/load"
  load "${REPO_PATH}/.vendor/lib/bats-file/load"
  load "${REPO_PATH}/.vendor/lib/bats-support/load"
  bats_require_minimum_version 1.5.0
}

roles_subcommand_applies_all_tag() { # @test
  run bash src/bootware.sh roles --tags all,never
  assert_success
  assert_output --partial 'chrome'
  assert_output --partial 'firefox'
}

roles_subcommand_applies_multiple_tags() { # @test
  run bash src/bootware.sh roles --skip firefox,language --tags \
    browser,server
  assert_success
  assert_output --partial 'build'
  assert_output --partial 'chrome'
  refute_output --partial 'deno'
  refute_output --partial 'firefox'
}

roles_subcommand_default_hides_never_roles() { # @test
  run bash src/bootware.sh roles
  assert_success
  assert_output --partial 'wezterm'
  refute_output --partial 'podman'
}

roles_subcommand_never_shows_hidden_roles() { # @test
  run bash src/bootware.sh roles --tags never
  assert_success
  assert_output --partial 'podman'
  refute_output --partial 'bash'
}

roles_subcommand_skip_hides_desktop_roles() { # @test
  run bash src/bootware.sh roles --skip bash --tags sysadmin
  assert_success
  assert_output --partial 'deno'
  refute_output --partial 'bash'
}

roles_subcommand_tag_hides_desktop_roles() { # @test
  run bash src/bootware.sh roles --tags container
  assert_success
  assert_output --partial 'podman'
  refute_output --partial 'wezterm'
}
