# Just configuration file for running commands.
#
# For more information, visit https://just.systems.

set unstable := true
set windows-shell := ['powershell.exe', '-NoLogo', '-Command']
export PATH := if os() == "windows" {
  join(justfile_dir(), ".vendor\\bin;") + env("Path")
} else {
  justfile_dir() / ".vendor/bin:" + justfile_dir() / 
  ".vendor/lib/bats-core/bin:" + env("PATH")
}
export PSModulePath := if os() == "windows" {
  join(justfile_dir(), ".vendor\\lib\\powershell\\modules;") + 
  env("PSModulePath", "")
} else { "" }

# List all commands available in justfile.
list:
  @just --list

# Execute CI workflow commands.
ci: setup lint doc test-unit

# Build distribution packages.
[script("nu")]
dist version="0.9.0":
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

# Fix code formatting.
[windows]
format:
  #!powershell.exe
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  $PSNativeCommandUseErrorActionPreference = $True
  npx prettier --write .
  Invoke-ScriptAnalyzer -Fix -Recurse -Path ansible_collections -Setting `
    CodeFormatting
  Invoke-ScriptAnalyzer -Fix -Recurse -Path src -Setting CodeFormatting
  Invoke-ScriptAnalyzer -Fix -Recurse -Path test -Setting CodeFormatting
  $Scripts = Get-ChildItem -Recurse -Filter *.ps1 -Path `
    ansible_collections, src, test
  foreach ($Script in $Scripts) {
    $Text = Get-Content -Raw $Script.FullName
    [System.IO.File]::WriteAllText($Script.FullName, $Text)
  }

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
  poetry run ansible-lint ansible_collections playbook.yaml

# Run code analyses.
[windows]
lint:
  npx prettier --check .
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path ansible_collections \
    -Setting CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path src -Setting CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path test -Setting CodeFormatting
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path ansible_collections \
    -Settings data/config/script_analyzer.psd1
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path src -Settings \
    data/config/script_analyzer.psd1
  Invoke-ScriptAnalyzer -EnableExit -Recurse -Path test -Settings \
    data/config/script_analyzer.psd1

# Install development dependencies.
setup: _setup
  node --version
  npm --version
  npm ci

[unix]
_setup:
  #!/usr/bin/env sh
  set -eu
  arch='{{replace(replace(arch(), "x86_64", "amd64"), "aarch64", "arm64")}}'
  os='{{replace(os(), "macos", "darwin")}}'
  mkdir -p .vendor/bin .vendor/lib
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
  if [ ! -x "$(command -v nu)" ]; then
    curl --fail --location --show-error \
      https://scruffaluff.github.io/scripts/install/nushell.sh | sh -s -- \
      --preserve-env --dest .vendor/bin
  fi
  echo "Nushell $(nu --version)"
  if [ ! -x "$(command -v poetry)" ]; then
    curl -LSfs https://install.python-poetry.org | python3 -
  fi
  for spec in 'assert:v2.1.0' 'core:v1.11.1' 'file:v0.4.0' 'support:v0.3.0'; do
    pkg="${spec%:*}"
    tag="${spec#*:}"
    if [ ! -d ".vendor/lib/bats-${pkg}" ]; then
      git clone -c advice.detachedHead=false --branch "${tag}" --depth 1 \
        "https://github.com/bats-core/bats-${pkg}.git" ".vendor/lib/bats-${pkg}"
    fi
  done
  bats --version
  if [ ! -x "$(command -v shellcheck)" ]; then
    shellcheck_arch="$(uname -m | sed 's/amd64/x86_64/;s/x64/x86_64/;s/arm64/aarch64/')"
    shellcheck_version="$(curl  --fail --location --show-error \
      https://formulae.brew.sh/api/formula/shellcheck.json |
      jq --exit-status --raw-output .versions.stable)"
    curl --fail --location --show-error --output /tmp/shellcheck.tar.xz \
    https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.${os}.${shellcheck_arch}.tar.xz
    tar fx /tmp/shellcheck.tar.xz -C /tmp
    install "/tmp/shellcheck-v${shellcheck_version}/shellcheck" .vendor/bin/
  fi
  shellcheck --version
  if [ ! -x "$(command -v shfmt)" ]; then
    shfmt_arch="$(uname -m | sed 's/x86_64/amd64/;s/x64/amd64/;s/aarch64/arm64/')"
    shfmt_version="$(curl  --fail --location --show-error \
      https://formulae.brew.sh/api/formula/shfmt.json |
      jq --exit-status --raw-output .versions.stable)"
    curl --fail --location --show-error --output .vendor/bin/shfmt \
      "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_${os}_${shfmt_arch}"
    chmod 755 .vendor/bin/shfmt
  fi
  echo "Shfmt version $(shfmt --version)"
  if [ ! -x "$(command -v yq)" ]; then
    curl --fail --location --show-error --output .vendor/bin/yq \
      "https://github.com/mikefarah/yq/releases/latest/download/yq_${os}_${arch}"
    chmod 755 .vendor/bin/yq
  fi
  yq --version
  python3 --version
  python3 -m venv .venv
  poetry --version
  poetry check --lock
  poetry install

[windows]
_setup:
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
      https://scruffaluff.github.io/scripts/install/nushell.ps1
    Invoke-Expression "& { $NushellScript } --preserve-env --dest .vendor/bin"
  }
  Write-Output "Nushell $(nu --version)"
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

# Run test suites.
test: test-unit test-pkg test-e2e

# Run end to end test suite.
test-e2e *args:
  nu script/test_e2e.nu {{args}}

test-pkg *args:
  nu script/pkg.nu test {{args}}

# Run unit test suite.
[unix]
test-unit *args:
  bats --recursive test {{args}}

# Run unit test suite.
[windows]
test-unit:
  Invoke-Pester -CI -Output Detailed -Path \
    $(Get-ChildItem -Recurse -Filter *.test.ps1 -Path test).FullName

