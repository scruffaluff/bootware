# Just configuration file for running commands.
#
# For more information, visit https://just.systems.

set ignore-comments := true
set windows-shell := ['powershell.exe', '-NoLogo', '-Command']
export PATH := home_dir() / ".local/bin:" + env_var("PATH")

# List all commands available in justfile.
list:
  @just --list

# Execute all commands.
all: setup format lint docs test

# Build distribution packages.
[unix]
dist version:
  scripts/package.sh --version {{version}} ansible
  scripts/package.sh --version {{version}} dist alpm apk deb rpm

# Build documentation.
docs:
  npx tsx scripts/build_docs.ts

# Check code formatting.
[unix]
format:
  npx prettier --check .
  shfmt --diff bootware.sh install.sh completions ansible_collections/scruffaluff

# Check code formatting.
[windows]
format:
  npx prettier --check .
  Invoke-ScriptAnalyzer -EnableExit -Path bootware.ps1 -Setting CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Path install.ps1 -Setting CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path ansible_collections -Setting CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path tests -Setting CodeFormatting

# Run code analyses.
[unix]
lint:
  scripts/shellcheck.sh
  poetry run ansible-lint ansible_collections/scruffaluff playbook.yaml

# Run code analyses.
[windows]
lint:
  Invoke-ScriptAnalyzer -EnableExit -Path bootware.ps1 -Settings PSScriptAnalyzerSettings.psd1
  Invoke-ScriptAnalyzer -EnableExit -Path install.ps1 -Settings PSScriptAnalyzerSettings.psd1
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path ansible_collections -Settings PSScriptAnalyzerSettings.psd1
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path tests -Settings PSScriptAnalyzerSettings.psd1

# Install development dependencies.
setup: _setup
  node --version
  npm --version
  npm ci

[unix]
_setup: _setup-unix
  python3 --version
  python3 -m venv .venv
  poetry --version
  poetry check --lock
  poetry install

[unix]
_setup-unix:
  #!/usr/bin/env sh
  set -eu
  arch='{{replace(replace(arch(), "x86_64", "amd64"), "aarch64", "arm64")}}'
  os='{{replace(os(), "macos", "darwin")}}'
  if [ ! -x "$(command -v node)" ] || [ ! -x "$(command -v npm)" ]; then
    echo 'Error: Unable to find NodeJS and NPM.' >&2
    echo 'Install NodeJS, https://nodejs.org, manually before continuing.' >&2
    exit 1
  fi
  if [ ! -x "$(command -v python3)" ]; then
    echo 'Error: Unable to find Python.' >&2
    echo 'Install Python, https://python.org, manually before continuing.' >&2
    exit 1
  fi
  if [ ! -x "$(command -v poetry)" ]; then
    curl -LSfs https://install.python-poetry.org | python3 -
  fi
  if [ ! -x "$(command -v shellcheck)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install shellcheck
    else
      # TODO: Check for installation of curl, jq, and tar.
      shellcheck_version="$(curl  --fail --location --show-error \
        https://formulae.brew.sh/api/formula/shellcheck.json |
        jq --exit-status --raw-output .versions.stable)"
      curl --fail --location --show-error --output /tmp/shellcheck.tar.xz \
        "https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.${os}.{{arch()}}.tar.xz"
      tar fx /tmp/shellcheck.tar.xz -C /tmp
      install "/tmp/shellcheck-v${shellcheck_version}/shellcheck" "${HOME}/.local/bin/shellcheck"
    fi
  fi
  if [ ! -x "$(command -v shfmt)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install shfmt
    else
      shfmt_version="$(curl  --fail --location --show-error \
        https://formulae.brew.sh/api/formula/shfmt.json |
        jq --exit-status --raw-output .versions.stable)"
      curl --fail --location --show-error --output /tmp/shfmt \
        "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_${os}_${arch}"
      install /tmp/shfmt "${HOME}/.local/bin/shfmt"
    fi
  fi
  echo "shfmt version $(shfmt --version)"
  if [ ! -x "$(command -v yq)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install yq
    else
      yq_version="$(curl  --fail --location --show-error \
        https://formulae.brew.sh/api/formula/yq.json |
        jq --exit-status --raw-output .versions.stable)"
      curl --fail --location --show-error --output /tmp/yq \
        "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_${os}_${arch}"
      install /tmp/yq "${HOME}/.local/bin/yq"
    fi
  fi
  yq --version

[windows]
_setup:
  #!powershell.exe
  $ErrorActionPreference = 'Stop'
  $PSNativeCommandUseErrorActionPreference = $True
  If (-Not (
    (Get-Command -ErrorAction SilentlyContinue node) -And 
    (Get-Command -ErrorAction SilentlyContinue npm)
  )) {
    Write-Error 'Error: Unable to find NodeJS and NPM.'
    Write-Error 'Install NodeJS, https://nodejs.org, manually before continuing.'
    Exit 1
  }
  If (-Not (Get-Command -ErrorAction SilentlyContinue yq)) {
    If (Get-Command -ErrorAction SilentlyContinue choco) {
      choco install --yes yq
    }
    ElseIf (Get-Command -ErrorAction SilentlyContinue scoop) {
      scoop install yq
    }
    ElseIf (Get-Command -ErrorAction SilentlyContinue winget) {
      winget install --disable-interactivity --exact --id mikefarah.yq
    } 
    Else {
      Write-Error 'Error: Unable to install Yq with system package managers.'
      Write-Error 'Install Yq, https://mikefarah.gitbook.io/yq, manually before continuing.'
      Exit 1
    }
  }
  # If executing task from PowerShell Core, error such as "'Install-Module'
  # command was found in the module 'PowerShellGet', but the module could not be
  # loaded" unless earlier versions of PackageManagement and PowerShellGet are
  # imported.
  Import-Module -MaximumVersion 1.1.0 -MinimumVersion 1.0.0 PackageManagement
  Import-Module -MaximumVersion 1.9.9 -MinimumVersion 1.0.0 PowerShellGet
  Get-PackageProvider -Force Nuget | Out-Null
  If (-Not (Get-Module -ListAvailable -FullyQualifiedName @{ModuleName="PSScriptAnalyzer";ModuleVersion="1.0.0"})) {
    Install-Module -Force -MinimumVersion 1.0.0 -Name PSScriptAnalyzer
  }
  If (-Not (Get-Module -ListAvailable -FullyQualifiedName @{ModuleName="Pester";ModuleVersion="5.0.0"})) {
    Install-Module -Force -SkipPublisherCheck -MinimumVersion 5.0.0 -Name Pester
  }

# Run unit test suites.
[unix]
test:
  npx bats --recursive tests

# Run unit test suites.
[windows]
test:
  Invoke-Pester -CI -Output Detailed tests
