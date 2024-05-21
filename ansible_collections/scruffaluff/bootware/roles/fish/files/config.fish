# Fish settings file.
#
# To profile Fish configuration startup time, run command
# 'fish --command exit --profile-startup profile.log'. For more information
# about the Fish configuration file, visit
# https://fishshell.com/docs/current/index.html#configuration-files.

# Do not use flag '--query' instead of '-q'. Flag '--quiet' was renamed to
# '--query' in Fish version 3.2.0, but short flag '-q' is compatible across all
# versions.

# Private convenience functions.

# Prompt user to remove current command from Fish history.
#
# Flags:
#   -n: Check if string is nonempty.
function _delete_commandline_from_history
    set command (string trim (commandline))
    if test -n $command
        set results "$(history search $command)"

        if test -n $results
            printf '\nFish History Entry Delete\n\n'
            history delete $command
            history save
            commandline --function kill-whole-line
        end
    end
end

# Check if current shell is within a remote SSH session.
#
# Flags:
#   -n: Check if string is nonempty.
function _ssh_session
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
function _source_files
    for inode in $argv
        if test -f $inode
            source $inode
        end
    end
end

# Source Bash files if they exist.
#
# Flags:
#   -f: Check if file exists and is a regular file.
function _source_bash_files
    for inode in $argv
        if test -f $inode
            bass source $inode
        end
    end
end

# Public convenience interactive functions.

# Open Fish history file with default editor.
#
# Flags:
#   -q: Only check for exit status by supressing output.
function edit-history
    if type -q $EDITOR
        $EDITOR "$HOME/.local/share/fish/fish_history"
    end
end

# Public convenience script functions.

# Prepend existing directories that are not in the system path.
#
# Builtin fish_add_path function changes system path permanently. This
# implementation only changes the system path for the shell session. Do not
# quote the PATH variable. It will convert it from a list to a string.
#
# Flags:
#   -d: Check if path is a directory.
function prepend_paths
    for inode in $argv
        if test -d $inode; and not contains $inode $PATH
            set --export PATH $inode $PATH
        end
    end
end

# Private convenience variables.
#
# Do not use long form flags for uname. They are not supported on MacOS. Command
# (brew --prefix) will give the incorrect path when sourced on Apple silicon and
# running under an Rosetta 2 emulated terminal.
#
# Flags:
#   -d: Check if path is a directory.
#   -s: Show operating system kernel name.
if test -d /opt/homebrew
    set _brew_prefix /opt/homebrew
else
    set _brew_prefix /usr/local
end
set _os (uname -s)
if status is-interactive
    set _tty true
else
    set _tty ''
end

# Shell settings.

# Add alias for remove by force.
alias rmf 'rm -fr'
# Make rsync use human friendly output.
alias rsync 'rsync --partial --progress --filter ":- .gitignore"'
# Disable welcome message.
set fish_greeting

# Set solarized light color theme for several Unix tools.
#
# Uses output of command "vivid generate solarized-light" from
# https://github.com/sharkdp/vivid.
#
# Flags:
#   -f: Check if file exists and is a regular file.
#   -n: Check if string is nonempty.
if test -n $_tty; and test -f "$HOME/.ls_colors"
    set --export LS_COLORS "$(cat "$HOME/.ls_colors")"
end

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
prepend_paths /usr/sbin /usr/local/bin /opt/homebrew/sbin \
    /opt/homebrew/bin "$HOME/.local/bin"

# Add custom Fish key bindings. 
#
# To discover Fish character sequences for keybindings, use the
# 'fish_key_reader' command. For more information, visit
# https://fishshell.com/docs/current/cmds/bind.html.
function fish_user_key_bindings
    bind \cd _delete_commandline_from_history
    bind \cj backward-char
    bind \ue000 forward-char
    bind \eZ redo
    bind \ez undo
end

# Add unified clipboard aliases.
#
# Command cbcopy is defined as a function instead of an alias to add logic for
# removing the final newline from text during clipboard copies.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
#   -z: Read input until null terminated instead of newline.
if test -n $_tty
    if test $_os = Darwin
        function cbcopy
            set --local text
            while read -z line
                # Variable 'text' needs quotes to send test a one line string.
                if test -n "$text"
                    set
                else
                    set text $line
                end
            end
            echo -n "$(printf '%s' $text)" | pbcopy
        end
        alias cbpaste pbpaste
    else if type -q wl-copy
        function cbcopy
            set --local text
            while read -z line
                # Variable 'text' needs quotes to send test a one line string.
                if test -n "$text"
                    set
                else
                    set text $line
                end
            end
            echo -n "$(printf '%s' $text)" | wl-copy
        end
        alias cbpaste wl-paste
    end
end

# Bat settings.

# Set default pager to Bat.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q bat
    set --export PAGER bat
end

# Docker settings.

# Ensure newer Docker features are enabled.
set --export COMPOSE_DOCKER_CLI_BUILD true
set --export DOCKER_BUILDKIT true
set --export DOCKER_CLI_HINTS false

# Fzf settings.

# Add path preview to Fzf file finder.
#
# Flags:
#   -d: Check if path is a directory.
#   -q: Only check for exit status by supressing output.
function _fzf_path_preview
    if test -d $argv[1]
        lsd --tree --depth 1 $argv[1]
    else
        bat --color always --line-range :100 --style numbers $argv[1]
    end
end

# Set Fzf solarized light theme.
set _fzf_colors '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
set _fzf_highlights '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
set --export FZF_DEFAULT_OPTS "--reverse $_fzf_colors $_fzf_highlights"

# Load Fzf keybindings if available.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if test -n $_tty; and type -q fzf
    fzf --fish | source

    if type -q fd
        set --export FZF_CTRL_T_COMMAND 'fd --strip-cwd-prefix'
    end
    if type -q bat; and type -q lsd
        set --export FZF_CTRL_T_OPTS "--preview '_fzf_path_preview {}'"
    end

    # Change Fzf file search keybinding to Ctrl+F.
    bind --erase \ec
    bind --erase \ct
    bind \cf fzf-file-widget
end

# Go settings.

# Export Go root directory to system path if available.
#
# Flags:
#   -d: Check if path is a directory.
if test -d "$_brew_prefix/opt/go/libexec"
    set --export GOROOT "$_brew_prefix/opt/go/libexec"
    prepend_paths "$GOROOT/bin"
else if test -d /usr/local/go
    set --export GOROOT /usr/local/go
    prepend_paths "$GOROOT/bin"
end

# Set path for Go local binaries.
set --export GOPATH "$HOME/.go"
prepend_paths "$GOPATH/bin"

# Helix settings.

# Set full color support for terminal and default editor to Helix.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q hx
    set --export EDITOR hx
    set --export SUDO_EDITOR hx
end

# Homebrew settings

# Avoid Homebrew hints after installing a package.
set --export HOMEBREW_NO_ENV_HINTS true

# Just settings.

# Add alias for account wide Just recipes.
alias jt "just --justfile $HOME/.justfile --working-directory ."

# Kubernetes settings.

# Add Kubectl plugins to system path.
prepend_paths "$HOME/.krew/bin"

# Procs settings.

# Set light theme since Procs automatic theming fails on some systems.
alias procs 'procs --theme light'

# Python settings.

# Add Python debugger alias.
alias pdb 'python3 -m pdb'
alias pudb 'python3 -m pip install --quiet pudb && python3 -m pudb'
alias pyi "python3 -i $HOME/.pyrc.py"

# Make Poetry create virutal environments inside projects.
set --export POETRY_VIRTUALENVS_IN_PROJECT true
# Fix Poetry package install issue on headless systems.
set --export PYTHON_KEYRING_BACKEND 'keyring.backends.fail.Keyring'

# Make numerical compute libraries findable on MacOS.
if test $_os = Darwin
    set --export OPENBLAS "$_brew_prefix/opt/openblas"
    prepend_paths $OPENBLAS
end

# Add Pyenv binaries to system path.
set --export PYENV_ROOT "$HOME/.pyenv"
prepend_paths "$PYENV_ROOT/bin" "$PYENV_ROOT/shims"

# Initialize Pyenv if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q pyenv
    pyenv init - | source
end

# Ripgrep settings.

# Set Ripgrep settings file location.
set --export RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

# Rust settings.

# Add Rust debugger aliases.
alias rgd 'rust-gdb --quiet'
alias rld 'rust-lldb --source-quietly'

# Add Rust binaries to system path.
prepend_paths "$HOME/.cargo/bin"

# Starship settings.

# Disable Starship warnings about command timeouts.
set --export STARSHIP_LOG error

# Initialize Starship if available.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if test -n $_tty
    if type -q starship
        starship init fish | source
    else
        function fish_prompt
            printf '\n%s at %s in %s\n❯ ' $USER (prompt_hostname) (prompt_pwd)
        end
    end
end

# TypeScript settings.

# Add Bun binaries to system path.
set --export BUN_INSTALL "$HOME/.bun"
prepend_paths "$BUN_INSTALL/bin"

# Add Deno binaries to system path.
prepend_paths "$HOME/.deno/bin"

# Add NPM global binaries to system path.
prepend_paths "$HOME/.npm-global/bin"

# Initialize NVM default version of Node if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q nvm
    nvm use default
end

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path for Linux.
prepend_paths /usr/share/code/bin

# Wasmtime settings.

# Add Wasmtime binaries to system path.
set --export WASMTIME_HOME "$HOME/.wasmtime"
prepend_paths "$WASMTIME_HOME/bin"

# Yazi settings.

# Yazi wrapper to change directory on program exit.
#
# Flags:
#   -n: Check if string is nonempty.
function yz
    set tmp (mktemp)
    yazi --cwd-file $tmp $argv
    set cwd (cat $tmp)
    if test -n $cwd; and test $cwd != $PWD
        cd $cwd
    end
    rm $tmp
end

# Zoxide settings.

# Initialize Zoxide if available.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if test -n $_tty; and type -q zoxide
    zoxide init --cmd cd fish | source
end

# Alacritty settings.

# Placed near end of config to ensure Zellij reads the correct window size.
if test -n $_tty; and test $TERM = alacritty
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal and within an interactive shell for the login user. For more
    # information, visit https://zellij.dev/documentation/integration.html.
    #
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For for information, visit
    # https://github.com/vercel/hyper/issues/3762.
    #
    # Flags:
    #   -n: Check if string is nonempty.
    #   -q: Only check for exit status by supressing output.
    if type -q zellij; and not _ssh_session; and test $LOGNAME = $USER
        # Attach to a default session if it exists.
        set --export ZELLIJ_AUTO_ATTACH true
        # Exit the shell when Zellij exits.
        set --export ZELLIJ_AUTO_EXIT true
        eval (zellij setup --generate-auto-start fish | string collect)
    end

    # Switch TERM variable to avoid "alacritty: unknown terminal type" errors
    # during remote connections.
    #
    # For more information, visit
    # https://github.com/alacritty/alacritty/issues/3962.
    set --export TERM xterm-256color
end

# User settings.

# Load user aliases, secrets, and variables.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q bass
    _source_bash_files "$HOME/.env" "$HOME/.secrets"
end
_source_files "$HOME/.env.fish" "$HOME/.secrets.fish"
