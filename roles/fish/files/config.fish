# Fish settings file.
#
# For more information, visit
# https://fishshell.com/docs/current/index.html#configuration-files.

# Function fish_add_path was not added until Fish version 3.2.0.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if not type -q fish_add_path
  # Prepend directory to the system path if it exists and is not already there.
  #
  # Flags:
  #   -d: Check if inode is a directory.
  #   -x: Export variable for current and child processes.
  function fish_add_path
    # Fish version 2 throws an error if an inode in the system path does not
    # exist.
    if test -d "$argv[1]"; and not contains "$argv[1]" $PATH
      set -x PATH "$argv[1]" $PATH
    end
  end
end

# System settings.

# Ensure that /usr/bin appears before /usr/sbin in PATH environment variable.
#
# Pyenv system shell won't work unless it is found in a bin directory. Archlinux
# places a symlink in an sbin directory. For more information, see
# https://github.com/pyenv/pyenv/issues/1301#issuecomment-582858696.
fish_add_path '/usr/bin'

# Add manually installed binary directory to PATH environment variable.
#
# Necessary since path is missing on some MacOS systems.
fish_add_path '/usr/local/bin'

# Docker settings.
set -x COMPOSE_DOCKER_CLI_BUILD 1
set -x DOCKER_BUILDKIT 1

# Fish settings.

# Disable welcome message.
set fish_greeting

# Fzf settings.

# Set Fzf solarized light theme.
set _fzf_colors '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
set _fzf_highlights '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
set -x FZF_DEFAULT_OPTS "--reverse $_fzf_colors $_fzf_highlights"

# Add inode preview to Fzf file finder.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q bat and type -q tree
  function fzf_inode_preview
    bat --color always --style numbers $argv 2> /dev/null
    if test $status != 0
      tree -C -L 1 $argv 2> /dev/null
    end
  end

  set -x FZF_CTRL_T_OPTS "--preview 'fzf_inode_preview {}'"
end

if type -q fzf
  fzf_key_bindings
end

# Go settings.

# Find and export Go root directory.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernal name.
if test (uname -s) = 'Darwin'
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  set ARM_GOROOT '/opt/homebrew/opt/go/libexec'
  set INTEL_GOROOT '/usr/local/opt/go/libexec'

  if test -d "$ARM_GOROOT"
    set -x GOROOT "$ARM_GOROOT"
  else if test -d "$INTEL_GOROOT"
    set -x GOROOT "$INTEL_GOROOT"
  end
else
  set -x GOROOT '/usr/local/go'
end
fish_add_path "$GOROOT/bin"

# Add Go local binaries to system path.
set -x GOPATH "$HOME/.go"
fish_add_path "$GOPATH/bin"

# Java settings.

# Find and add Java OpenJDK directory to path.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernal name.
if test (uname -s) = 'Darwin'
  if test -d '/opt/homebrew/opt/openjdk/bin'
    fish_add_path '/opt/homebrew/opt/openjdk/bin'
  else if test -d '/usr/local/opt/openjdk/bin'
    fish_add_path '/usr/local/opt/openjdk/bin'
  end
end

# Julia settings.

fish_add_path '/usr/local/julia/bin'

# Python settings.

# Make Poetry create virutal environments inside projects.
set -x POETRY_VIRTUALENVS_IN_PROJECT 1

# Make numerical compute libraries findable on MacOS.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernal name.
if test (uname -s) = 'Darwin'
  if test -d '/opt/homebrew/opt/openblas'
    set -x OPENBLAS '/opt/homebrew/opt/openblas'
  else if test -d '/usr/local/opt/openblas'
    set -c OPENBLAS '/usr/local/opt/openblas'
  end
end

# Add Pyenv binaries to system path.
fish_add_path "$HOME/.pyenv/bin"

# Initialize Pyenv if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q pyenv
  status is-interactive; and pyenv init --path | source
  pyenv init - | source
end

# Ruby settings.
fish_add_path "$HOME/bin"

# Add gems binaries to path if Ruby is available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q ruby
  fish_add_path (ruby -r rubygems -e 'puts Gem.user_dir')'/bin'
end

# Rust settings.
fish_add_path "$HOME/.cargo/bin"

# Shell settings

# Custom environment variable function to faciliate other shell compatibility.
#
# Taken from https://unix.stackexchange.com/a/176331.
#
# Examples:
#   setenv PATH 'usr/local/bin'
function setenv
  if [ $argv[1] = PATH ]
    # Replace colons and spaces with newlines.
    set -x PATH (echo "$argv[2]" | tr ': ' \n)
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

set -x BAT_THEME 'Solarized (light)'

# Add Visual Studio Code binary to PATH for Linux.
fish_add_path '/usr/share/code/bin'

# Initialize Digital Ocean CLI if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q doctl
  source (doctl completion fish|psub)
end

# Initialize Direnv if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q direnv
  direnv hook fish | source
end

# Initialize GCloud if on MacOS and available.
#
# GCloud completion is provided on Linux via a Fish package.
#
# Flags:
#   -f: Check if inode is a regular file.
#   -s: Print machine kernal name.
if test (uname -s) = 'Darwin'
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  set ARM_GCLOUD_PATH '/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk'
  set INTEL_GCLOUD_PATH '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk'

  if test -f "$ARM_GCLOUD_PATH/path.fish.inc"
    source "$ARM_GCLOUD_PATH/path.fish.inc"
  else if test -f "$INTEL_GCLOUD_PATH/path.fish.inc"
    source "$INTEL_GCLOUD_PATH/path.fish.inc"
  end
end

# Add Kubectl plugins to PATH.
fish_add_path "$HOME/.krew/bin"

# Add Navi widget if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q navi
  navi widget fish | source
end

# Initialize Zoxide if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q zoxide
  zoxide init fish --cmd cd | source
end

# TypeScript settings.

# Add Deno binaries to system path.
set -x DENO_INSTALL "$HOME/.deno"
fish_add_path "$DENO_INSTALL/bin"

# Add NPM global binaries to system path.
fish_add_path "$HOME/.npm-global/bin"

# Initialize NVM default version of Node if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q nvm
  nvm use default
end

# User settings.

# Set default editor to Helix if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q hx
  set -x EDITOR 'hx'
end

# Add scripts directory to system path.
fish_add_path "$HOME/.local/bin"

# Wasmtime settings.
set -x WASMTIME_HOME "$HOME/.wasmtime"
fish_add_path "$WASMTIME_HOME/bin"

# Apple Silicon support.

# Ensure Homebrew Arm64 binaries are found before x86_64 binaries.
fish_add_path '/opt/homebrew/bin'
