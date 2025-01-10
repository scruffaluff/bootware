# Just configuration file for running commands.
#
# For more information, visit https://just.systems.

set windows-shell := ['powershell.exe', '-NoLogo', '-Command']

# List all commands available in justfile.
list:
  just --list

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
  arch="$(uname -m | sed s/x86_64/amd64/ | sed s/x64/amd64/ | sed s/aarch64/arm64/)"
  os="$(uname -s | tr '[A-Z]' '[a-z]')"
  if [ "$(id -u)" -eq 0 ]; then
    super=''
  elif [ -x "$(command -v sudo)" ]; then
    super='sudo'
  elif [ -x "$(command -v doas)" ]; then
    super='doas'
  fi
  if [ ! -x "$(command -v node)" ]; then
    if [ -x "$(command -v apk)" ]; then
      ${super:+"${super}"} apk update
      ${super:+"${super}"} apk add nodejs npm
    elif [ -x "$(command -v apt-get)" ]; then
      ${super:+"${super}"} apt-get update
      ${super:+"${super}"} apt-get install --yes nodejs npm
    elif [ -x "$(command -v brew)" ]; then
      brew install node
    elif [ -x "$(command -v dnf)" ]; then
      ${super:+"${super}"} dnf check-update || {
        code="$?"
        [ "${code}" -ne 100 ] && exit "${code}"
      }
      ${super:+"${super}"} dnf install --assumeyes nodejs nodejs-npm
    elif [ -x "$(command -v pacman)" ]; then
      ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
      ${super:+"${super}"} pacman --noconfirm --sync nodejs npm
    elif [ -x "$(command -v pkg)" ]; then
      ${super:+"${super}"} pkg update
      ${super:+"${super}"} pkg install --yes node npm-node
    else
      echo 'Error: No supported package manager to install NodeJS.' >&2
      echo 'Please install NodeJS manually before continuing.' >&2
      exit 1
    fi
  fi
   if [ ! -x "$(command -v python)" ]; then
    if [ -x "$(command -v apk)" ]; then
      ${super:+"${super}"} apk update
      ${super:+"${super}"} apk add py3-pip python3 python3-dev
    elif [ -x "$(command -v apt-get)" ]; then
      ${super:+"${super}"} apt-get update
      ${super:+"${super}"} apt-get install --yes python3 python3-dev python3-pip python3-venv
    elif [ -x "$(command -v brew)" ]; then
      brew install python
    elif [ -x "$(command -v dnf)" ]; then
      ${super:+"${super}"} dnf check-update || {
        code="$?"
        [ "${code}" -ne 100 ] && exit "${code}"
      }
      ${super:+"${super}"} dnf install --assumeyes python3 python3-devel python3-pip
    elif [ -x "$(command -v pacman)" ]; then
      ${super:+"${super}"} pacman --noconfirm --refresh --sync --sysupgrade
      ${super:+"${super}"} pacman --noconfirm --sync python python-pip
    elif [ -x "$(command -v pkg)" ]; then
      ${super:+"${super}"} pkg update
      ${super:+"${super}"} pkg install --yes py311-pip python3
    else
      echo 'Error: No supported package manager to install Python.' >&2
      echo 'Please install Python manually before continuing.' >&2
      exit 1
    fi
  fi
  if [ ! -x "$(command -v poetry)" ]; then
    python3 -m pip install --user poetry poetry-plugin-shell
  fi
  if [ ! -x "$(command -v shfmt)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install shfmt
    elif [ -x "$(command -v pkg)" ]; then
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
  echo "shfmt version $(shfmt --version)"
  if [ ! -x "$(command -v yq)" ]; then
    if [ -x "$(command -v brew)" ]; then
      brew install yq
    elif [ -x "$(command -v pkg)" ]; then
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
_setup:
  #!powershell.exe
  $ErrorActionPreference = 'Stop'
  If (-Not (Get-Command -ErrorAction SilentlyContinue node)) {
    If (Get-Command -ErrorAction SilentlyContinue choco) {
      choco install --yes nodejs
    }
    ElseIf (Get-Command -ErrorAction SilentlyContinue scoop) {
      scoop install nodejs
    }
    ElseIf (Get-Command -ErrorAction SilentlyContinue winget) {
      winget install --disable-interactivity --exact --id openjs.nodejs
    } 
    Else {
      Write-Error 'Error: No supported package manager to install NodeJS.'
      Write-Error 'Please install NodeJS manually before continuing.'
      Exit 1
    }
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
        Write-Error 'Error: No supported package manager to install Yq.'
        Write-Error 'Please install Yq manually before continuing.'
        Exit 1
    }
  }
  Install-Module -Force -Name PSScriptAnalyzer
  Install-Module -Force -SkipPublisherCheck -Name Pester

# Run unit test suites.
[unix]
test:
  npx bats --recursive tests

# Run unit test suites.
[windows]
test:
  Invoke-Pester -CI -Output Detailed tests
