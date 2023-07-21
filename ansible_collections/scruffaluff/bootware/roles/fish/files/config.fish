# Fish settings file.
#
# To profile Fish configuration startup time, run command
# 'fish --command exit --profile-startup profile.log'. For more information
# about the Fish configuration file, visit
# https://fishshell.com/docs/current/index.html#configuration-files.

# Do not use flag '--query' instead of '-q'. Flag '--quiet' was renamed to
# '--query' in Fish version 3.2.0, but short flag '-q' is compatible across all
# versions.

# Check if only minimally functional shell settings should be loaded.
#
# If file ~/.shell_minimal_config exists, then most shell completion will not be
# configured. These are useful to disable if on a slow system where shell
# startup takes too long.
if test -f "$HOME/.shell_minimal_config"
  set --export SHELL_MINIMAL_CONFIG 'true'
end

# Function fish_add_path was not added until Fish version 3.2.0.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if not type -q fish_add_path
  # Prepend directory to the system path if it exists and is not already there.
  #
  # Flags:
  #   -d: Check if inode is a directory.
  #   --export: Export variable for current and child processes.
  function fish_add_path
    # Fish version 2 throws an error if an inode in the system path does not
    # exist.
    if test -d "$argv[1]"; and not contains "$argv[1]" $PATH
      set --export PATH "$argv[1]" $PATH
    end
  end
end

# Prompt user to remove current command from Fish history.
#
# Flags:
#   -n: Check if string is nonempty.
function delete_commandline_from_history
  set command_ (commandline)

  if test -n (string trim "$command_")
    printf '\nFish History Entry Delete\n\n'
    history delete "$command_"
    history save
    commandline --function kill-whole-line
  end
end

# Open Fish history file with default editor.
#
# Flags:
#   -q: Only check for exit status by supressing output.
function edit-history
  if type -q "$EDITOR"
    $EDITOR "$HOME/.local/share/fish/fish_history"
  end
end

# Check if current shell is within a remote SSH session.
#
# Flags:
#   -n: Check if string is nonempty.
function ssh_session
  if test -n "$SSH_CLIENT$SSH_CONNECTION$SSH_TTY"
    return 0
  else
    return 1
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
set --export COMPOSE_DOCKER_CLI_BUILD 'true'
set --export DOCKER_BUILDKIT 'true'

# Fish settings.

# Disable welcome message.
set fish_greeting

# Fzf settings.

# Set Fzf solarized light theme.
set _fzf_colors '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
set _fzf_highlights '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
set --export FZF_DEFAULT_OPTS "--reverse $_fzf_colors $_fzf_highlights"

# Add inode preview to Fzf file finder.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q bat; and type -q tree
  function fzf_inode_preview
    bat --color always --style numbers $argv 2> /dev/null

    if test $status != 0
      # Flags:
      #   -C: Turn on color.
      #   -L 1: Descend only 1 directory level deep.
      tree -C -L 1 $argv 2> /dev/null
    end
  end

  set --export FZF_CTRL_T_OPTS "--preview 'fzf_inode_preview {}'"
end

if test -z "$SHELL_MINIMAL_CONFIG"; and type -q fzf
  fzf_key_bindings
end

# Go settings.

# Find and export Go root directory.
#
# Do not use long form --kernel-name flag for uname. It is not supported on
# MacOS.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernel name.
if test (uname -s) = 'Darwin'
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  set ARM_GOROOT '/opt/homebrew/opt/go/libexec'
  set INTEL_GOROOT '/usr/local/opt/go/libexec'

  if test -d "$ARM_GOROOT"
    set --export GOROOT "$ARM_GOROOT"
  else if test -d "$INTEL_GOROOT"
    set --export GOROOT "$INTEL_GOROOT"
  end
else
  set --export GOROOT '/usr/local/go'
end
fish_add_path "$GOROOT/bin"

# Add Go local binaries to system path.
set --export GOPATH "$HOME/.go"
fish_add_path "$GOPATH/bin"

# Python settings.

# Make Poetry create virutal environments inside projects.
set --export POETRY_VIRTUALENVS_IN_PROJECT 'true'

# Make numerical compute libraries findable on MacOS.
#
# Do not use long form --kernel-name flag for uname. It is not supported on
# MacOS.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernel name.
if test (uname -s) = 'Darwin'
  if test -d '/opt/homebrew/opt/openblas'
    set --export OPENBLAS '/opt/homebrew/opt/openblas'
  else if test -d '/usr/local/opt/openblas'
    set --export OPENBLAS '/usr/local/opt/openblas'
  end
end

# Add Pyenv binaries to system path.
fish_add_path "$HOME/.pyenv/bin"

# Initialize Pyenv if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q pyenv; and status is-interactive
  pyenv init - | source
end

# Rust settings.
fish_add_path "$HOME/.cargo/bin"

# Shell settings

alias cargo-expand "cargo expand --theme 'Solarized (light)'"
alias cargo-testpath "cargo test --no-run --message-format=json | jq --raw-output 'select(.profile.test == true) | .filenames[]'"
alias procs 'procs --theme light'

# Add unified clipboard aliases.
#
# Flags:
#   -s: Print machine kernel name.
#   -x: Check if file exists and execute permission is granted.
if test (uname -s) = 'Darwin'
  alias cbcopy pbcopy
  alias cbpaste pbpaste
else if type -q wl-copy
  alias cbcopy wl-copy
  alias cbpaste wl-paste
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
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q starship
  starship init fish | source
end

# Tool settings.

set --export BAT_THEME 'Solarized (light)'

# Add Visual Studio Code binary to PATH for Linux.
fish_add_path '/usr/share/code/bin'

# Initialize Digital Ocean CLI if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q doctl
  source (doctl completion fish | psub)
end

# Initialize GCloud if on MacOS and available.
#
# GCloud completion is provided on Linux via a Fish package. Do not use long
# form --kernel-name flag for uname. It is not supported on MacOS.
#
# Flags:
#   -f: Check if inode is a regular file.
#   -s: Print machine kernel name.
if test -z "$SHELL_MINIMAL_CONFIG"; and test (uname -s) = 'Darwin'
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
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q navi
  navi widget fish | source
end

# TypeScript settings.

# Add Deno binaries to system path.
set --export DENO_INSTALL "$HOME/.deno"
fish_add_path "$DENO_INSTALL/bin"

# Add NPM global binaries to system path.
fish_add_path "$HOME/.npm-global/bin"

# Source TabTab shell completion for PNPM.
#
# Flags:
#   -f: Check if inode is a regular file.
if test -z "$SHELL_MINIMAL_CONFIG"; and \
  test -f "$HOME/.config/tabtab/fish/__tabtab.fish"
  source "$HOME/.config/tabtab/fish/__tabtab.fish"
end

# Initialize NVM default version of Node if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q nvm
  nvm use default
end

# Zellij settings.

# Autostart Zellij or connect to existing session if within Alacritty terminal.
#
# For more information, visit https://zellij.dev/documentation/integration.html.
if test -z "$SHELL_MINIMAL_CONFIG"; and type -q zellij; \
  and not ssh_session; and test "$TERM" = 'alacritty'
  # Attach to a default session if it exists.
  set --export ZELLIJ_AUTO_ATTACH 'true'
  # Exit the shell when Zellij exits.
  set --export ZELLIJ_AUTO_EXIT 'true'
  
  # If within an interactive shell, create or connect to Zellij session.
  if status is-interactive
    eval (zellij setup --generate-auto-start fish | string collect)
  end
end

# User settings.

# Helix settings.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q hx
  # Assume that terminal session has full color support for convenience.
  set --export COLORTERM 'truecolor'
  # Set default editor to Helix if available.
  set --export EDITOR 'hx'
end

# Add scripts directory to system path.
fish_add_path "$HOME/.local/bin"

# Wasmtime settings.
set --export WASMTIME_HOME "$HOME/.wasmtime"
fish_add_path "$WASMTIME_HOME/bin"

# Ensure Homebrew Arm64 binaries are found before x86_64 binaries on Apple
# silicon computers.
fish_add_path '/opt/homebrew/bin'

# Fish user key bindings. 
#
# To discover Fish character sequences for keybindings, use the
# 'fish_key_reader' command. For more information, visit
# https://fishshell.com/docs/current/cmds/bind.html.
function fish_user_key_bindings
  bind \cD delete_commandline_from_history
end
