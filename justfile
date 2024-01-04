# Just configuration file for running commands.
#
# For more information, visit https://just.systems.

set windows-shell := ['powershell.exe', '-NoLogo', '-Command']

servers := 'cicd,dev,dns,media,sneakieboop'

# List all commands available in justfile.
list:
  just --list

docs:
  npx ts-node scripts/build_docs.ts

[unix]
format:
  npx prettier --check .
  shfmt --diff bootware.sh install.sh completions ansible_collections/scruffaluff

[windows]
format:
  npx prettier --check .
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path .

lint:
  ./scripts/shellcheck.sh
  poetry run ansible-lint ansible_collections/scruffaluff playbook.yaml

# Install package dependencies.
setup: setup-node setup-python setup-shell

setup-node:
  node --version
  npm --version
  npm ci

# Crate a Python virtual environment with Poetry.
[unix]
setup-python:
  python3 --version
  python3 -m venv .venv
  ./.venv/bin/pip install --upgrade pip setuptools wheel
  python3 -m pip --version
  poetry check --lock
  poetry install --no-root

[windows]
setup-python:
  python3 --version
  python3 -m venv .venv
  ./.venv/Scripts/pip.exe install --upgrade pip setuptools wheel
  python3 -m pip --version
  poetry check --lock
  poetry install --no-root

[unix]
setup-shell:
  #!/usr/bin/env sh
  set -eu
  if [ "$(id -u)" -eq 0 ]; then
    super=''
  elif [ -x "$(command -v sudo)" ]; then
    super='sudo'
  elif [ -x "$(command -v doas)" ]; then
    super='doas'
  fi
  arch="$(uname -m | sed s/x86_64/amd64/ | sed s/x64/amd64/ | sed s/aarch64/arm64/)"
  os="$(uname -s | tr '[A-Z]' '[a-z]')"
  if [ ! -x "$(command -v shfmt)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install shfmt
    elif [ -x "$(command -v brew)" ]; then
      ${super:+"${super}"} pkg update
      ${super:+"${super}"} pkg install --yes shfmt
    else
      shfmt_version="$(curl  --fail --location --show-error \
        https://formulae.brew.sh/api/formula/shfmt.json |
        jq --exit-status --raw-output .versions.stable)"
      curl --fail --location --show-error --output /tmp/shfmt \
        "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_${os}_${arch}"
      ${super:+"${super}"} install /tmp/shfmt /usr/local/bin/shfmt
    fi
  fi
  shfmt --version
  if [ ! -x "$(command -v yq)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install yq
    elif [ -x "$(command -v brew)" ]; then
      ${super:+"${super}"} pkg update
      ${super:+"${super}"} pkg install --yes yq
    else
      yq_version="$(curl  --fail --location --show-error \
        https://formulae.brew.sh/api/formula/yq.json |
        jq --exit-status --raw-output .versions.stable)"
      curl --fail --location --show-error --output /tmp/yq \
        "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_${os}_${arch}"
      ${super:+"${super}"} install /tmp/yq /usr/local/bin/yq
    fi
  fi
  yq --version

[windows]
setup-shell:
  Install-Module -Force -Name PSScriptAnalyzer
  Install-Module -Force -Name Pester

[unix]
test-unit:
  bats --recursive tests/unit

[windows]
test-unit:
  Invoke-Pester -Output Detailed tests/unit
