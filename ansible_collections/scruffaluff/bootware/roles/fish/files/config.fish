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
    set --local command (commandline | string collect | string trim)
    if test -n $command
        set --local results "$(history search $command)"

        if test -n $results
            printf '\nFish History Entry Delete\n\n'
            history delete $command
            history save
            commandline --function kill-whole-line
        end
    end
end

# Path preview for Fzf file finder.
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

# Paste current working directory into the commandline.
function _paste_cwd
    set --local line (commandline | string collect)
    set --local working_directory "$(string replace "$HOME" '~' $(pwd))/"

    if string match --entire --quiet $working_directory $line
        commandline --replace (string replace $working_directory '' $line)
    else
        commandline --insert $working_directory
    end
end

# Paste pipe to fuzzy finder into the commandline.
#
# Flags:
#   -n: Check if string is nonempty.
function _paste_fzf
    set --local line (commandline | string collect)
    set --local command " &| fzf"
    set --local query (string escape --style regex $command)

    set --local newline (string replace --regex "$query\$" '' $line)
    if test $line = $newline
        commandline --append $command
    else
        commandline --replace $newline
    end
end

# Paste pipe to system pager command into the commandline.
#
# Flags:
#   -n: Check if string is nonempty.
function _paste_pager
    # Variable 'PAGER' needs quotes in case it is not defined.
    set --local program
    if test -n "$PAGER"
        set program $PAGER
    else
        set program less
    end

    set --local line (commandline | string collect)
    set --local command " &| $program"
    set --local query (string escape --style regex $command)

    set --local newline (string replace --regex "$query\$" '' $line)
    if test $line = $newline
        commandline --append $command
    else
        commandline --replace $newline
    end
end

# Public convenience functions.

# Open Fish history file with default editor.
#
# Flags:
#   -n: Check if string is nonempty.
function edit-history
    # Variable 'EDITOR' needs quotes in case it is not defined.
    if test -n "$EDITOR"
        $EDITOR "$HOME/.local/share/fish/fish_history"
    else
        vim "$HOME/.local/share/fish/fish_history"
    end
end

# Override system implementation of command not found.
#
# Some system implementations will perform a long lookup to see if a package
# provides the command.
function fish_command_not_found
    echo "Error: command '$argv[1]' not found" >&2
end

# Prepend existing directories that are not in the system path.
#
# Builtin fish_add_path function changes system path permanently. This
# implementation only changes the system path for the shell session. Do not
# quote the PATH variable. It will convert it from a list to a string.
#
# Flags:
#   -d: Check if path is a directory.
function prepend-paths
    for inode in $argv
        if test -d $inode; and not contains $inode $PATH
            set --export PATH $inode $PATH
        end
    end
end

# Source Bash files if they exist.
#
# Flags:
#   -f: Check if file exists and is a regular file.
function source-bash-files
    for inode in $argv
        if test -f $inode
            bass source $inode
        end
    end
end

# Source shell files if they exist.
#
# Flags:
#   -f: Check if file exists and is a regular file.
function source-files
    for inode in $argv
        if test -f $inode
            source $inode
        end
    end
end

# Check if current shell is within a remote SSH session.
#
# Since function returns an exit code, zero is true and nonzero is false.
#
# Flags:
#   -n: Check if string is nonempty.
function ssh-session
    if test -n "$SSH_CLIENT$SSH_CONNECTION$SSH_TTY"
        return 0
    else
        return 1
    end
end

# Private convenience variables.
#
# Do not use long form flags for uname. They are not supported on MacOS.
#
# Flags:
#   -s: Show operating system kernel name.
set os (uname -s)
if status is-interactive
    set tty true
else
    set tty ''
end

# System settings.

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
prepend-paths /usr/sbin /usr/local/bin /opt/homebrew/sbin \
    /opt/homebrew/bin "$HOME/.local/bin"

# Alacritty settings.

# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
#   -z: Check if the string is empty.
if test -n $tty; and test $TERM = alacritty; and test -z $TERM_PROGRAM
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal and within an interactive shell for the login user. For more
    # information, visit https://zellij.dev/documentation/integration.html.
    #
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For for information, visit
    # https://github.com/vercel/hyper/issues/3762.
    if type -q zellij; and not ssh-session; and test $LOGNAME = $USER
        # Attach to a default session if it exists.
        set --export ZELLIJ_AUTO_ATTACH true
        # Exit the shell when Zellij exits.
        set --export ZELLIJ_AUTO_EXIT true
        SHELL=(status fish-path) eval (zellij setup --generate-auto-start fish | string collect)
    end

    # Switch TERM variable to avoid "alacritty: unknown terminal type" errors
    # during remote connections.
    #
    # For more information, visit
    # https://github.com/alacritty/alacritty/issues/3962.
    set --export TERM xterm-256color
end

# Bat settings.

# Set default pager to Bat.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q bat
    set --export PAGER bat
end

# Clipboard settings.

# Add unified clipboard aliases.
#
# Command cbcopy is defined as a function instead of an alias to add logic for
# removing the final newline from text during clipboard copies.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
#   -z: Read input until null terminated instead of newline.
if test $os = Darwin
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

# Docker settings.

# Ensure newer Docker features are enabled.
set --export COMPOSE_DOCKER_CLI_BUILD true
set --export DOCKER_BUILDKIT true
set --export DOCKER_CLI_HINTS false

# FFmpeg settings.

# Disable verbose FFmpeg banners.
alias ffmpeg 'ffmpeg -hide_banner'
alias ffplay 'ffplay -hide_banner'
alias ffprobe 'ffprobe -hide_banner'

# Fzf settings.

# Load Fzf settings if interactive and available.
#
# Flags:
#   -c: Run commands in Fish shell.
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if test -n $tty; and type -q fzf
    # Disable Fzf Alt-C command.
    set --export FZF_ALT_C_COMMAND ''
    # Set Fzf solarized light theme and shell command for child processes.
    set _fzf_colors '--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
    set _fzf_highlights '--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
    set --export FZF_DEFAULT_OPTS "--reverse $_fzf_colors $_fzf_highlights --with-shell 'fish -c'"
    set --erase _fzf_colors
    set --erase _fzf_highlights

    fzf --fish | source
    if type -q bat; and type -q lsd
        set --export FZF_CTRL_T_OPTS "--preview '_fzf_path_preview {}'"
    end
    if type -q fd
        set --export FZF_DEFAULT_COMMAND 'fd --hidden'
        if test $os = Darwin
            set --export FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND --search-path \$dir"
        end
    end

    # Change Fzf file search keybinding to Ctrl+F.
    bind --erase \ec
    bind --erase \ct
    bind \cf fzf-file-widget
end

# Helix settings.

# Set default editor to Helix if available.
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
prepend-paths "$HOME/.krew/bin"

# Lsd settings.

# Set solarized light color theme for several Unix tools.
#
# Uses output of command "vivid generate solarized-light" from
# https://github.com/sharkdp/vivid.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if test -f "$HOME/.ls_colors"
    set --export LS_COLORS "$(cat "$HOME/.ls_colors")"
end

# Replace Ls with Lsd if avialable.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q lsd
    alias ls lsd
end

# Procs settings.

# Set light theme since Procs automatic theming fails on some systems.
alias procs 'procs --theme light'

# Python settings.

# Add Python debugger alias.
alias pdb 'python3 -m pdb'

# Make Poetry create virutal environments inside projects.
set --export POETRY_VIRTUALENVS_IN_PROJECT true
# Fix Poetry package install issue on headless systems.
set --export PYTHON_KEYRING_BACKEND 'keyring.backends.fail.Keyring'

# Make numerical compute libraries findable on MacOS.
if test $os = Darwin
    if test -d /opt/homebrew
        set --export OPENBLAS /opt/homebrew/opt/openblas
    else
        set --export OPENBLAS /usr/local/opt/openblas
    end
    prepend-paths $OPENBLAS
end

# Add Pyenv binaries to system path.
set --export PYENV_ROOT "$HOME/.pyenv"
prepend-paths "$PYENV_ROOT/bin" "$PYENV_ROOT/shims"

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
prepend-paths "$HOME/.cargo/bin"

# Shell settings.

# Add alias for remove by force.
alias rmf 'rm -fr'
# Make rsync use human friendly output.
alias rsync 'rsync --partial --progress --filter ":- .gitignore"'
# Disable welcome message.
set fish_greeting ''

# Add keybindings if interactive.
#
# To discover Fish character sequences for keybindings, use the
# 'fish_key_reader' command. For more information, visit
# https://fishshell.com/docs/current/cmds/bind.html.
#
# Flags:
#   -n: Check if string is nonempty.
if test -n $tty
    function fish_user_key_bindings
        bind \cw true
        bind \cd backward-kill-path-component
        bind \cj backward-char
        bind \ec _paste_cwd
        bind \ed kill-bigword
        bind \ef _paste_fzf
        bind \ep _paste_pager
        bind \ex _delete_commandline_from_history
        bind \eZ redo
        bind \ez undo
        bind \ue000 forward-char
    end
end

# Starship settings.

# Disable Starship warnings about command timeouts.
set --export STARSHIP_LOG error

# Initialize Starship if interactive and available.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if test -n $tty
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
prepend-paths "$BUN_INSTALL/bin"

# Add Deno binaries to system path.
prepend-paths "$HOME/.deno/bin"

# Add NPM global binaries to system path.
prepend-paths "$HOME/.npm-global/bin"

# Initialize Node Version Manager if available.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q nvm
    nvm use default
end

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path for Linux.
prepend-paths /usr/share/code/bin

# Wasmtime settings.

# Add Wasmtime binaries to system path.
set --export WASMTIME_HOME "$HOME/.wasmtime"
prepend-paths "$WASMTIME_HOME/bin"

# Yazi settings.

# Yazi wrapper to change directory on program exit.
#
# Flags:
#   -n: Check if string is nonempty.
function yz
    set --local tmp (mktemp)
    yazi --cwd-file $tmp $argv
    set --local cwd (cat $tmp)

    # Quotes are necessary for the if statement to ensure that the test function
    # always receives the correct number of arguments.
    if test -n "$cwd"; and test "$cwd" != "$PWD"
        cd $cwd
    end
    rm $tmp
end

# Zoxide settings.

# Initialize Zoxide if interactive and available.
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
if test -n $tty; and type -q zoxide
    zoxide init --cmd cd fish | source
end

# Remove private convenience variables.

set --erase os
set --erase tty

# User settings.

# Load user aliases, secrets, and variables.
#
# Flags:
#   -q: Only check for exit status by supressing output.
if type -q bass
    source-bash-files "$HOME/.env" "$HOME/.secrets"
end
source-files "$HOME/.env.fish" "$HOME/.secrets.fish"
