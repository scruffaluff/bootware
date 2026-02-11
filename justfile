# Just configuration file for running commands.
#
# For more information, visit https://just.systems.

set unstable := true
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
export PATH := if os() == "windows" {
  join(justfile_directory(), ".vendor\\bin;") + env("Path")
} else {
  justfile_directory() / ".vendor/bin:" + justfile_directory() /
  ".vendor/lib/bats-core/bin:" + env("PATH")
}
export PSModulePath := if os() == "windows" {
  join(justfile_directory(), ".vendor\\lib\\powershell\\modules;") +
  env("PSModulePath", "")
} else { "" }

# Execute CI workflow commands.
ci: setup lint doc test-shell test-nushell test-python

# Build distribution packages.
dist version="0.10.0":
  nu script/pkg.nu ansible --version {{version}}
  nu script/pkg.nu dist --version {{version}} alpm apk deb rpm

# Build documentation.
doc:
  npx tsx script/doc.ts

# Fix code formatting.
[unix]
format:
  npx prettier --write .
  shfmt --write ansible_collections script src test
  uv run ruff format .

# Fix code formatting.
[windows]
format:
  #!powershell.exe
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  $PSNativeCommandUseErrorActionPreference = $True
  npx prettier --write .
  Invoke-ScriptAnalyzer -Fix -Recurse -Path ansible_collections -Settings `
    CodeFormatting
  Invoke-ScriptAnalyzer -Fix -Recurse -Path src -Settings CodeFormatting
  Invoke-ScriptAnalyzer -Fix -Recurse -Path test -Settings CodeFormatting
  $Scripts = Get-ChildItem -Recurse -Filter *.ps1 -Path `
    ansible_collections, src, test
  foreach ($Script in $Scripts) {
    $Text = Get-Content -Raw $Script.FullName
    [System.IO.File]::WriteAllText($Script.FullName, $Text)
  }

# Install project programs.
install *args:
  nu src/install.nu --version {{justfile_directory()}} {{args}}

# Run code analyses.
[unix]
lint:
  #!/usr/bin/env sh
  set -eu
  npx prettier --check .
  shfmt --diff ansible_collections script src test
  files="$(find ansible_collections script src test -name '*.bats' -or -name '*.sh')"
  for file in ${files}; do
    shellcheck "${file}"
  done
  uv run ansible-lint ansible_collections playbook.yaml
  uv run ruff check .
  uv run ty check .

# Run code analyses.
[windows]
lint:
  npx prettier --check .
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path ansible_collections \
    -Settings CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path src -Settings CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path test -Settings CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path ansible_collections \
    -Settings data/config/script_analyzer.psd1
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path src -Settings \
    data/config/script_analyzer.psd1
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path test -Settings \
    data/config/script_analyzer.psd1

# List all commands available in justfile.
[default]
list:
  @just --list

# Wrapper to Nushell.
[no-exit-message]
@nu *args:
  nu {{args}}

# Install development dependencies.
[unix]
setup:
  #!/usr/bin/env sh
  set -eu
  arch='{{replace(replace(arch(), "x86_64", "amd64"), "aarch64", "arm64")}}'
  os='{{replace(os(), "macos", "darwin")}}'
  mkdir -p .vendor/bin .vendor/lib
  if ! command -v node > /dev/null 2>&1 || ! command -v npm > /dev/null 2>&1;
  then
    echo 'Error: Unable to find NodeJS and NPM.' >&2
    echo 'Install NodeJS, https://nodejs.org, manually before continuing.' >&2
    exit 1
  fi
  if ! command -v nu > /dev/null 2>&1; then
    curl --fail --location --show-error \
      https://scruffaluff.github.io/picoware/install/nushell.sh | sh -s -- \
      --preserve-env --dest .vendor/bin
  fi
  echo "Nushell $(nu --version)"
  if ! command -v uv > /dev/null 2>&1; then
    curl --fail --location --show-error \
      https://scruffaluff.github.io/picoware/install/uv.sh | sh -s -- \
      --preserve-env --dest .vendor/bin
  fi
  uv --version
  for spec in 'assert:v2.1.0' 'core:v1.11.1' 'file:v0.4.0' 'support:v0.3.0'; do
    pkg="${spec%:*}"
    tag="${spec#*:}"
    if [ ! -d ".vendor/lib/bats-${pkg}" ]; then
      git clone -c advice.detachedHead=false --branch "${tag}" --depth 1 \
        "https://github.com/bats-core/bats-${pkg}.git" ".vendor/lib/bats-${pkg}"
    fi
  done
  bats --version
  if [ ! -d .vendor/lib/nutest ]; then
    git clone -c advice.detachedHead=false --branch main \
      --depth 1 https://github.com/vyadh/nutest.git .vendor/lib/nutest
  fi
  if ! command -v shellcheck > /dev/null 2>&1; then
    shellcheck_arch='{{arch()}}'
    shellcheck_version="$(curl  --fail --location --show-error \
      https://formulae.brew.sh/api/formula/shellcheck.json |
      jq --exit-status --raw-output .versions.stable)"
    curl --fail --location --show-error --output /tmp/shellcheck.tar.xz \
    "https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.${os}.${shellcheck_arch}.tar.xz"
    tar fx /tmp/shellcheck.tar.xz -C /tmp
    install "/tmp/shellcheck-v${shellcheck_version}/shellcheck" .vendor/bin/
  fi
  shellcheck --version
  if ! command -v shfmt > /dev/null 2>&1; then
    shfmt_version="$(curl  --fail --location --show-error \
      https://formulae.brew.sh/api/formula/shfmt.json |
      jq --exit-status --raw-output .versions.stable)"
    curl --fail --location --show-error --output .vendor/bin/shfmt \
      "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_${os}_${arch}"
    chmod 755 .vendor/bin/shfmt
  fi
  echo "Shfmt version $(shfmt --version)"
  if ! command -v yq > /dev/null 2>&1; then
    curl --fail --location --show-error --output .vendor/bin/yq \
      "https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}"
    chmod 755 .vendor/bin/yq
  fi
  yq --version
  node --version
  npm --version
  if [ -n "${JUST_INIT:-}" ]; then
    npm install
    uv sync --locked
  else
    npm ci
    uv sync
  fi

# Install development dependencies.
[windows]
setup:
  #!powershell.exe
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  $PSNativeCommandUseErrorActionPreference = $True
  $Arch = '{{replace(replace(arch(), "x86_64", "amd64"), "aarch64", "arm64")}}'
  $ModulePath = '.vendor\lib\powershell\modules'
  New-Item -Force -ItemType Directory -Path $ModulePath | Out-Null
  if (-not (
    (Get-Command -ErrorAction SilentlyContinue node) -And
    (Get-Command -ErrorAction SilentlyContinue npm)
  )) {
    Write-Error 'Error: Unable to find NodeJS and NPM.'
    Write-Error 'Install NodeJS, https://nodejs.org, manually before continuing.'
    Exit 1
  }
  if (-not (Get-Command -ErrorAction SilentlyContinue nu)) {
    $NushellScript = Invoke-WebRequest -UseBasicParsing -Uri `
      https://scruffaluff.github.io/picoware/install/nushell.ps1
    Invoke-Expression "& { $NushellScript } --preserve-env --dest .vendor/bin"
  }
  Write-Output "Nushell $(nu --version)"
  if (-not (Test-Path -Path .vendor/lib/nutest -PathType Container)) {
    git clone -c advice.detachedHead=false --branch main --depth 1 `
      https://github.com/vyadh/nutest.git .vendor/lib/nutest
  }
  # If executing task from PowerShell Core, error such as "'Install-Module'
  # command was found in the module 'PowerShellGet', but the module could not be
  # loaded" unless earlier versions of PackageManagement and PowerShellGet are
  # imported.
  Import-Module -MaximumVersion 1.1.0 -MinimumVersion 1.0.0 PackageManagement
  Import-Module -MaximumVersion 1.9.9 -MinimumVersion 1.0.0 PowerShellGet
  Get-PackageProvider -Force Nuget | Out-Null
  if (
    -not (Get-Module -ListAvailable -FullyQualifiedName `
    @{ModuleName = "PSScriptAnalyzer"; ModuleVersion = "1.0.0" })
  ) {
    Find-Module -MinimumVersion 1.0.0 -Name PSScriptAnalyzer | Save-Module `
      -Force -Path $ModulePath
  }
  if (
    -not (Get-Module -ListAvailable -FullyQualifiedName `
    @{ModuleName = "Pester"; ModuleVersion = "5.0.0" })
  ) {
    Find-Module -MinimumVersion 5.0.0 -Name Pester | Save-Module -Force -Path `
      $ModulePath
  }
  if (-not (Get-Command -ErrorAction SilentlyContinue yq)) {
    Invoke-WebRequest -UseBasicParsing -OutFile .vendor/bin/yq.exe -Uri `
      "https://github.com/mikefarah/yq/releases/latest/download/yq_windows_$Arch.exe"
  }
  yq --version
  node --version
  npm --version
  if ("$Env:JUST_INIT") {
    npm install
  }
  else {
    npm ci
  }

# Run test suites.
test: test-shell test-nushell test-python test-pkg test-e2e

# Run end to end test suite.
test-e2e *args:
  nu script/test_e2e.nu {{args}}

# Run Nushell test suite.
test-nushell *args:
  nu --commands \
    "use .vendor/lib/nutest/nutest run-tests; run-tests --fail --path test {{args}}"

# Run packaging test suite.
test-pkg *args:
  nu script/pkg.nu test {{args}}

# Run Python test suite.
[unix]
test-python *args:
  uv run pytest test {{args}}

# Run Python test suite.
[windows]
test-python *args:

# Run unit test suite.
[unix]
test-shell *args:
  bats --recursive test {{args}}

# Run unit test suite.
[windows]
test-shell:
  Invoke-Pester -CI -Output Detailed -Path \
    $(Get-ChildItem -Recurse -Filter *.test.ps1 -Path test).FullName

# Wrapper to Uv.
[no-exit-message]
@uv *args:
  uv {{args}}
