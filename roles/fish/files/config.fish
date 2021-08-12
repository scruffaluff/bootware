# Fish settings file.
# shellcheck shell=fish

# System settings.

# Ensure that /usr/bin appears before /usr/sbin in PATH environment variable.
#
# Pyenv system shell won't work unless it is found in a bin directory. Archlinux
# places a symlink in an sbin directory. For more information, see
# https://github.com/pyenv/pyenv/issues/1301#issuecomment-582858696.
set -x PATH "/usr/bin" $PATH

# Add manually installed binary directory to PATH environment variable.
#
# Necessary since path is missing on some MacOS systems.
set -x PATH "/usr/local/bin" $PATH

# Docker settings.
set -x COMPOSE_DOCKER_CLI_BUILD 1
set -x DOCKER_BUILDKIT 1

# Fish settings.

# Disable welcome message.
set fish_greeting

# Go settings.

# Find and export Go root directory.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernal name.
if test (uname -s) = "Darwin"
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  set ARM_GOROOT "/opt/homebrew/opt/go/libexec"
  set INTEL_GOROOT "/usr/local/opt/go/libexec"

  if test -d "$ARM_GOROOT"
    set -x GOROOT "$ARM_GOROOT"
  else if test -d "$INTEL_GOROOT"
    set -x GOROOT "$INTEL_GOROOT"
  end
else
  set -x GOROOT "/usr/local/go"
end
set -x PATH "$GOROOT/bin" $PATH

# Add Go local binaries to system path.
set -x GOPATH "$HOME/go"
set -x PATH "$GOPATH/bin" $PATH

# Python settings.

# Make Poetry create virutal environments inside projects.
set -x POETRY_VIRTUALENVS_IN_PROJECT 1

# Add Pyenv binaries to system path.
set -x PATH "$HOME/.pyenv/bin" $PATH

# Initialize Pyenv if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q pyenv
  status is-interactive; and pyenv init --path | source
  pyenv init - | source
end

# Ruby settings.

# Initialize RVM if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q rvm
  rvm default
end

# Rust settings.
set -x PATH "$HOME/.cargo/bin" $PATH

# Shell settings

# Custom environment variable function to faciliate other shell compatibility.
#
# Taken from https://unix.stackexchange.com/a/176331.
#
# Examples:
#   setenv PATH "usr/local/bin"
function setenv
  if [ $argv[1] = PATH ]
    # Replace colons and spaces with newlines.
    set -gx PATH (echo "$argv[2]" | tr ": " \n)
  else
    set -gx $argv
  end
end

# Load aliases if file exists.
#
# Flags:
#   -f: Check if inode is a regular file.
if test -f "$HOME/.aliases"
  source "$HOME/.aliases"
end

# Load environment variables if file exists.
#
# Flags:
#   -f: Check if inode is a regular file.
#   -q: Only check for exit status by supressing output.
if test -f "$HOME/.env"; and type -q bass
  bass source "$HOME/.env"
end

# Load secrets if file exists.
#
# Flags:
#   -f: Check if inode is a regular file.
#   -q: Only check for exit status by supressing output.
if test -f "$HOME/.secrets"; and type -q bass
  bass source "$HOME/.secrets"
end

# Starship settings.

# Initialize Starship if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q starship
  starship init fish | source
end

# Tool settings.

set -x BAT_THEME "Solarized (light)"

# Disable pagination for Bat.
set -x BAT_PAGER ""

# Add Visual Studio Code binary to PATH for Linux.
set -x PATH "/usr/share/code/bin" $PATH

# Initialize Digital Ocean CLI if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q doctl
  source (doctl completion fish|psub)
end

# Initialize GCloud if on MacOS and available.
#
# GCloud completion is provided on Linux via a Fish package.
#
# Flags:
#   -f: Check if inode is a regular file.
#   -s: Print machine kernal name.
if test (uname -s) = "Darwin"
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  set ARM_GCLOUD_PATH "/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"
  set INTEL_GCLOUD_PATH "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk"

  if test -f "$ARM_GCLOUD_PATH/path.fish.inc"
    source "$ARM_GCLOUD_PATH/path.fish.inc"
  else if test -f "$INTEL_GCLOUD_PATH/path.fish.inc"
    source "$INTEL_GCLOUD_PATH/path.fish.inc"
  end
end

# Initialize Zoxide if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q zoxide
  zoxide init fish | source
end

# TypeScript settings.

# Add NPM global binaries to system path.
set -x PATH "$HOME/.npm-global/bin" $PATH

# Initialize NVM default version of Node if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q nvm
  nvm use default
end

# Deno settings.
set -x DENO_INSTALL "$HOME/.deno"
set -x PATH "$DENO_INSTALL/bin" $PATH

# User settings.

set -x EDITOR "nvim"

# Add scripts directory to system path.
set -x PATH "$HOME/.local/bin" $PATH

# Wasmtime settings.
set -x WASMTIME_HOME "$HOME/.wasmtime"
set -x PATH "$WASMTIME_HOME/bin" $PATH

# Apple Silicon support.

# Ensure Homebrew Arm64 binaries are found before x86_64 binaries.
set -x PATH "/opt/homebrew/bin" $PATH
