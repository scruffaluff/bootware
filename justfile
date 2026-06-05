# Just configuration file for running commands.
#
# For more information, visit https://just.systems.

set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
export PATH := if os() == "windows" {
  join(justfile_directory(), ".vendor\\bin;") + join(justfile_directory(),
  ".vendor\\lib\\node\\bin;") + env("PATH")
} else {
  justfile_directory() / ".vendor/bin:" + justfile_directory() /
  ".vendor/lib/bats-core/bin:" + justfile_directory() /
  ".vendor/lib/node/bin:" + env("PATH")
}
export PSModulePath := if os() == "windows" {
  join(justfile_directory(), ".vendor\\lib\\powershell\\modules;") +
  env("PSModulePath", "")
} else { "" }

# Execute CI workflow commands.
ci: setup lint test-sh test-nu test-py doc

# Build distribution packages.
dist version="0.10.4":
  nu script/pkg.nu ansible --version {{version}}
  nu script/pkg.nu dist --version {{version}} alpm apk deb rpm

# Build documentation.
doc:
  npx tsx script/doc.ts

# Fix code formatting.
[unix]
format +paths=".":
  npx prettier --write {{paths}}
  npx @johnnymorganz/stylua-bin {{paths}}
  shfmt --write ansible_collections script src test
  uv run ruff format {{paths}}

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
  npx @johnnymorganz/stylua-bin --check .
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
@list:
  just --list

# Wrapper to Nushell.
[no-exit-message]
@nu *args:
  nu --commands "{{args}}"

# Install development dependencies.
[script("nu")]
setup: _setup
  let arch = match $nu.os-info.arch { aarch64 => "arm64", $x => $x }
  let archive = if $nu.os-info.name == "windows" { ".zip" } else { ".tar.gz" }
  let ext = if $nu.os-info.name == "windows" { ".exe" } else { "" }
  let os = match $nu.os-info.name { macos => "darwin", $x => $x }
  if (which node | is-empty) or (which npm | is-empty) {
    let arch = match $arch { x86_64 => "x64", $x => $x }
    let os = match $os { windows => "win", $x => $x }
    let version = http get https://nodejs.org/download/release/index.json
    | where lts != false | get 0.version
    let target = $"node-($version)-($os)-($arch)"
    print "Installing Node."
    let temp = mktemp --directory --tmpdir
    http get $"https://nodejs.org/dist/($version)/($target)($archive)"
    | save --force $"($temp)/node($archive)"
    if $os == "windows" {
      unzip -d $temp $"($temp)/node($archive)"
    } else {
      tar fx $"($temp)/node($archive)" -C $temp
    }
    mv $"($temp)/($target)" .vendor/lib/node
  }
  if not (".vendor/lib/nutest" | path exists) {
    print "Installing Nutest."
    (
      git clone -c advice.detachedHead=false --branch main
      --depth 1 https://github.com/vyadh/nutest.git .vendor/lib/nutest
    )
  }
  print $"Using Nutest (git -C .vendor/lib/nutest rev-parse HEAD)."
  if (which uv | is-empty) {
    print "Installing Uv."
    http get https://scruffaluff.github.io/picoware/install/uv.nu
    | nu -c $"($in | decode); main --preserve-env --dest .vendor/bin"
  }
  print $"Using (uv --version)."
  if (which yq | is-empty) {
    let arch = match $arch { x86_64 => "amd64", $x => $x }
    print "Installing Yq."
    http get $"https://github.com/mikefarah/yq/releases/latest/download/yq_($os)_($arch)($ext)"
    | save --force $".vendor/bin/yq($ext)"
    if $os != "windows" {
      chmod 755 .vendor/bin/yq
    }
  }
  print $"Using (yq --version)."
  print "Installing packages with NPM and Uv."
  if ($env.INIT? | into bool --relaxed) {
    npm install
    if $os == "windows" { uv sync }
    just format
  } else {
    npm ci
    if $os == "windows" { uv sync --locked }
  }

[unix]
_setup:
  #!/usr/bin/env sh
  set -eu
  arch='{{replace(replace(arch(), "x86_64", "amd64"), "aarch64", "arm64")}}'
  os='{{replace(os(), "macos", "darwin")}}'
  mkdir -p .vendor/bin .vendor/lib
  for spec in 'assert:v2.1.0' 'core:v1.11.1' 'file:v0.4.0' 'support:v0.3.0'; do
    bats_check=''
    pkg="${spec%:*}"
    tag="${spec#*:}"
    if [ ! -d ".vendor/lib/bats-${pkg}" ]; then
      if [ -z "${bats_check}" ]; then
        echo 'Installing Bats.'
        bats_check='1'
      fi
      git clone -c advice.detachedHead=false --branch "${tag}" --depth 1 \
        "https://github.com/bats-core/bats-${pkg}.git" ".vendor/lib/bats-${pkg}"
    fi
  done
  echo "Using $(bats --version)."
  if ! command -v nu > /dev/null 2>&1; then
    echo 'Installing Nushell.'
    curl --fail --location --show-error \
      https://scruffaluff.github.io/picoware/install/nushell.sh | sh -s -- \
      --preserve-env --dest .vendor/bin
  fi
  echo "Using Nushell $(nu --version)."
  if ! command -v shellcheck > /dev/null 2>&1; then
    echo 'Installing ShellCheck.'
    shellcheck_arch='{{arch()}}'
    shellcheck_version="$(curl --fail --location --show-error \
      https://formulae.brew.sh/api/formula/shellcheck.json |
      jq --exit-status --raw-output .versions.stable)"
    curl --fail --location --show-error --output /tmp/shellcheck.tar.xz \
      "https://github.com/koalaman/shellcheck/releases/download/v${shellcheck_version}/shellcheck-v${shellcheck_version}.${os}.${shellcheck_arch}.tar.xz"
    tar fx /tmp/shellcheck.tar.xz -C /tmp
    install "/tmp/shellcheck-v${shellcheck_version}/shellcheck" .vendor/bin/
  fi
  echo "Using $(shellcheck --version)."
  if ! command -v shfmt > /dev/null 2>&1; then
    echo 'Installing Shfmt.'
    shfmt_version="$(curl --fail --location --show-error \
      https://formulae.brew.sh/api/formula/shfmt.json |
      jq --exit-status --raw-output .versions.stable)"
    curl --fail --location --show-error --output .vendor/bin/shfmt \
      "https://github.com/mvdan/sh/releases/download/v${shfmt_version}/shfmt_v${shfmt_version}_${os}_${arch}"
    chmod 755 .vendor/bin/shfmt
  fi
  echo "Using Shfmt $(shfmt --version)."

[windows]
_setup:
  #!powershell.exe
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  $PSNativeCommandUseErrorActionPreference = $True
  $Arch = '{{replace(replace(arch(), "x86_64", "amd64"), "aarch64", "arm64")}}'
  $ModulePath = '.vendor\lib\powershell\modules'
  New-Item -Force -ItemType Directory -Path $ModulePath | Out-Null
  if (-not (Get-Command -ErrorAction SilentlyContinue nu)) {
    Write-Output 'Installing Nushell.'
    $NushellScript = Invoke-WebRequest -UseBasicParsing -Uri `
      https://scruffaluff.github.io/picoware/install/nushell.ps1
    Invoke-Expression "& { $NushellScript } --preserve-env --dest .vendor/bin"
  }
  Write-Output "Using Nushell $(nu --version)"
  # If executing task from PowerShell Core, error such as "'Install-Module'
  # command was found in the module 'PowerShellGet', but the module could not be
  # loaded" unless earlier versions of PackageManagement and PowerShellGet are
  # imported.
  Import-Module -MaximumVersion 1.1.0 -MinimumVersion 1.0.0 PackageManagement
  Import-Module -MaximumVersion 1.9.9 -MinimumVersion 1.0.0 PowerShellGet
  Get-PackageProvider -Force Nuget | Out-Null
  if (
    -not (Get-Module -ListAvailable -FullyQualifiedName `
    @{ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.0.0' })
  ) {
    Write-Output 'Installing PSScriptAnalyzer.'
    Find-Module -MinimumVersion 1.0.0 -Name PSScriptAnalyzer | Save-Module `
      -Force -Path $ModulePath
  }
  Write-Output "Using PSScriptAnalyzer $((Get-Module -ListAvailable `
    PSScriptAnalyzer | Select-Object -First 1).Version)."
  if (
    -not (Get-Module -ListAvailable -FullyQualifiedName `
    @{ModuleName = 'Pester'; ModuleVersion = '5.0.0' })
  ) {
    Write-Output 'Installing Pester.'
    Find-Module -MinimumVersion 5.0.0 -Name Pester | Save-Module -Force -Path `
      $ModulePath
  }
  Write-Output "Using Pester $((Get-Module -ListAvailable Pester | `
    Select-Object -First 1).Version)."

# Run test suites.
test: test-sh test-nu test-py test-pkg test-e2e

# Run end to end test suite.
test-e2e *args:
  nu script/test_e2e.nu {{args}}

# Run Nushell test suite.
[script("nu")]
test-nu *args:
  use "{{replace(justfile_directory(), '\', '/') / '.vendor/lib/nutest/nutest'}}" run-tests
  run-tests --fail --path test {{args}}

# Run packaging test suite.
test-pkg *args:
  nu script/pkg.nu test {{args}}

# Run Python test suite.
[unix]
test-py *args:
  uv run pytest test {{args}}

# Run Python test suite.
[windows]
test-py *args:

# Run unit test suite.
[unix]
test-sh *args:
  bats --recursive test {{args}}

# Run unit test suite.
[windows]
test-sh:
  Invoke-Pester -CI -Output Detailed -Path \
    $(Get-ChildItem -Recurse -Filter *.test.ps1 -Path test).FullName

# Wrapper to Uv.
[no-exit-message]
@uv *args:
  uv {{args}}
