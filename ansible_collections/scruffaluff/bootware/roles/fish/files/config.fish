# Fish settings file.
#
# To profile Fish configuration startup time, run command
# 'fish --command exit --profile-startup profile.log'. For more information
# about the Fish configuration file, visit
# https://fishshell.com/docs/current/index.html#configuration-files.

# Do not use flag '--query' instead of '-q'. Flag '--quiet' was renamed to
# '--query' in Fish version 3.2.0, but short flag '-q' is compatible across all
# versions.

# Convenience variables.
#
# Do not use long form flags for uname. They are not supported on MacOS. Command
# "(brew --prefix)" will give the incorrect path when sourced on Apple silicon
# and running under an Rosetta 2 emulated terminal.
#
# Flags:
#   -m: Show hardware architecture name.
#   -s: Show operating system kernel name.
set _arch (uname -m)
if string match --quiet 'arm' "*$_arch* "
  set _brew_prefix '/opt/homebrew'
else
  set _brew_prefix '/usr/local'
end
set _os (uname -s)
if status is-interactive
  set _tty 'true'
else
  set _tty ''
end

# Prompt user to remove current command from Fish history.
#
# Flags:
#   -n: Check if string is nonempty.
function delete_commandline_from_history
  set command (string trim (commandline))
  if test -n "$command"
    set results (history search "$command")

    if test -n "$results"
      printf '\nFish History Entry Delete\n\n'
      history delete "$command"
      history save
      commandline --function kill-whole-line
    end
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

# Function fish_add_path was not added until Fish version 3.2.0.
#
# Do not quote PATH variable. It will convert it from a list to a string.
#
# Flags:
#   -d: Check if path is a directory.
#   -q: Only check for exit status by supressing output.
if not type -q fish_add_path
  function fish_add_path
    if test -d "$argv[1]"; and not contains "$argv[1]" $PATH
      set --export PATH "$argv[1]" $PATH
    end
  end
end

function fish_add_paths
  for inode in $argv
    fish_add_path "$inode"
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

# Source shell files if they exist.
#
# Flags:
#   -f: Check if file exists and is a regular file.
function source_files
  for inode in $argv
    if test -f "$inode"
      source "$inode"
    end
  end
end

# Shell settings.

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
fish_add_paths '/usr/local/bin' '/opt/homebrew/bin' '/opt/homebrew/sbin' \
  "$HOME/.local/bin"

# Add custom Fish key bindings. 
#
# To discover Fish character sequences for keybindings, use the
# 'fish_key_reader' command. For more information, visit
# https://fishshell.com/docs/current/cmds/bind.html.
function fish_user_key_bindings
  bind \cD delete_commandline_from_history
end

# Disable welcome message.
set fish_greeting

# Add unified clipboard aliases.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if test "$_os" = 'Darwin'
  function cbcopy
    set --local text
    while read -z line
      if test -n "$text"
        set
      else
        set text "$line"
      end
    end
    echo -n "$(printf "%s" "$text")" | pbcopy
  end
  alias cbpaste pbpaste
else if type -q wl-copy
  function cbcopy
    set --local text
    while read -z line
      if test -n "$text"
        set
      else
        set text "$line"
      end
    end
    echo -n "$(printf "%s" "$text")" | wl-copy
  end
  alias cbpaste wl-paste
end

# Digital Ocean settings.

# Initialize Digital Ocean CLI if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q doctl
  source (doctl completion fish | psub)
end

# Docker settings.

# Ensure newer Docker features are enabled.
set --export COMPOSE_DOCKER_CLI_BUILD 'true'
set --export DOCKER_BUILDKIT 'true'

# Fzf settings.

# Set Fzf solarized light theme.
set _fzf_colors '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
set _fzf_highlights '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
set --export FZF_DEFAULT_OPTS "--reverse $_fzf_colors $_fzf_highlights"

# Add inode preview to Fzf file finder.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q bat; and type -q tree
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

# Load Fzf keybindings if available.
#
# Flags:
#   -f: Check if file exists and is a regular file.
#   -n: Check if string is nonempty.
if test -f "$HOME/.config/fish/functions/fzf_key_bindings.fish"; and \
  test -n "$_tty"
  fzf_key_bindings
end

# Go settings.

# Find and export Go root directory.
if test "$_os" = 'Darwin'
  set --export GOROOT "$_brew_prefix/opt/go/libexec"
else
  set --export GOROOT '/usr/local/go'
end

# Add Go local binaries to system path.
set --export GOPATH "$HOME/.go"
fish_add_paths "$GOROOT/bin" "$GOPATH/bin"

# Google Cloud Platform settings.

# Initialize GCloud if on MacOS and available.
#
# GCloud completion is provided on Linux via a Fish package. Do not use long
# form --kernel-name flag for uname. It is not supported on MacOS.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if test "$_os" = 'Darwin'
  source_files "$_brew_prefix/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc"
end

# Helix settings.

# Set full color support for terminal and default editor to Helix.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q hx
  set --export COLORTERM 'truecolor'
  set --export EDITOR 'hx'
end

# Kubernetes settings.

# Add Kubectl plugins to system path.
fish_add_paths "$HOME/.krew/bin"

# Python settings.

# Fix Poetry package install issue on headless systems.
set --export PYTHON_KEYRING_BACKEND 'keyring.backends.fail.Keyring'
# Make Poetry create virutal environments inside projects.
set --export POETRY_VIRTUALENVS_IN_PROJECT 'true'

# Make numerical compute libraries findable on MacOS.
if test "$_os" = 'Darwin'
  set --export OPENBLAS "$_brew_prefix/opt/openblas"
  fish_add_paths "$OPENBLAS"
end

# Add Pyenv binaries to system path.
set --export PYENV_ROOT "$HOME/.pyenv"
fish_add_paths "$PYENV_ROOT/bin"

# Initialize Pyenv if available.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if type -q pyenv; and test -n "$_tty"
  pyenv init - | source
end

# Rust settings.

# Add Rust binaries to system path.
fish_add_paths "$HOME/.cargo/bin"

# Starship settings.

# Initialize Starship if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q starship
  starship init fish | source
end

# TypeScript settings.

# Add Deno binaries to system path.
set --export DENO_INSTALL "$HOME/.deno"
fish_add_paths "$DENO_INSTALL/bin"

# Add NPM global binaries to system path.
fish_add_paths "$HOME/.npm-global/bin"

# Initialize NVM default version of Node if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q nvm
  nvm use default
end

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path for Linux.
fish_add_paths '/usr/share/code/bin'

# Wasmtime settings.

# Add Wasmtime binaries to system path.
set --export WASMTIME_HOME "$HOME/.wasmtime"
fish_add_paths "$WASMTIME_HOME/bin"

# Zellij settings.

# Autostart Zellij or connect to existing session if within Alacritty terminal.
#
# For more information, visit https://zellij.dev/documentation/integration.html.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if type -q zellij; and not ssh_session; and test "$TERM" = 'alacritty'
  # Attach to a default session if it exists.
  set --export ZELLIJ_AUTO_ATTACH 'true'
  # Exit the shell when Zellij exits.
  set --export ZELLIJ_AUTO_EXIT 'true'
  
  # If within an interactive shell for the login user, create or connect to
  # Zellij session.
  #
  # Do not use logname command, it sometimes incorrectly returns "root" on
  # MacOS. For for information, visit
  # https://github.com/vercel/hyper/issues/3762.
  if test -n "$_tty"; and test "$LOGNAME" = "$USER"
    eval (zellij setup --generate-auto-start fish | string collect)
  end
end

# User settings.

# Load user aliases, secrets, and variables.
#
# Flags:
#   -f: Check if file exists and is a regular file.
#   -q: Only check for exit status by supressing output.
if type -q bass
  if test -f "$HOME/.env"
    bass source "$HOME/.env"
  end
  if test -f "$HOME/.secrets"
    bass source "$HOME/.secrets"
  end
end
