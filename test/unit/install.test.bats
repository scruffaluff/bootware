#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
  REPO_PATH="${BATS_TEST_DIRNAME}/../.."
  cd "${REPO_PATH}" || exit
  load "${REPO_PATH}/.vendor/lib/bats-assert/load"
  load "${REPO_PATH}/.vendor/lib/bats-file/load"
  load "${REPO_PATH}/.vendor/lib/bats-support/load"
  bats_require_minimum_version 1.5.0

  # Avoid mutating user shell configuration during testing.
  install_completions() {
    echo "$@"
  }
  export -f install_completions
}

global_owner_is_root() { # @test
  local dst_dir
  dst_dir="$(mktemp -d)"

  run bash src/install.sh --preserve-env --quiet --global --dest "${dst_dir}"
  assert_success
  assert_file_owner root "${dst_dir}/bootware"
}

prints_version() { # @test
  run bash src/install.sh --preserve-env --dest "$(mktemp -d)"
  assert_success
  assert_output --partial 'Installed Bootware 0.'
}

quiet_is_silent() { # @test
  run bash src/install.sh --preserve-env --quiet --dest "$(mktemp -d)"
  assert_success
  assert_output ''
}

shows_error_usage_for_bad_argument() { # @test
  run bash src/install.sh --dst
  assert_failure
  assert_output "$(
    cat << EOF
error: No such option '--dst'.
Run 'install-bootware --help' for usage.
EOF
  )"
}
