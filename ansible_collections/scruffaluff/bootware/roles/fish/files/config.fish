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
    set command (commandline | string collect | string trim)
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

# Paste pipe to system pager command into the commandline.
#
# Flags:
#   -n: Check if string is nonempty.
function _paginate_command
    # Variable 'PAGER' needs quotes in case it is not defined.
    if test -n "$PAGER"
        set pager_ $PAGER
    else
        set pager_ less
    end

    set line (commandline | string collect)
    set command " &| $pager_"
    set query (string escape --style regex $command)

    set newline (string replace --regex "$query\$" '' $line)
    if test $line = $newline
        commandline --append $command
    else
        commandline --replace $newline
    end
end

# Paste current working directory into the commandline.
function _paste_working_directory
    set line (commandline | string collect)
    set working_directory "$(string replace "$HOME" '~' $(pwd))/"

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
function _select_command
    set line (commandline | string collect)
    set command " &| fzf"
    set query (string escape --style regex $command)

    set newline (string replace --regex "$query\$" '' $line)
    if test $line = $newline
        commandline --append $command
    else
        commandline --replace $newline
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

# Override system implementation of command not found.
#
# Some system implementations will perform a long lookup to see if a package
# provides the command.
function fish_command_not_found
    echo "Error: command '$argv[1]' not found" >&2
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

# Source Bash files if they exist.
#
# Flags:
#   -f: Check if file exists and is a regular file.
function source_bash_files
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
function source_files
    for inode in $argv
        if test -f $inode
            source $inode
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
    bind \cw true
    bind \cd backward-kill-path-component
    bind \cj backward-char
    bind \ec _paste_working_directory
    bind \ed kill-bigword
    bind \ef _select_command
    bind \ep _paginate_command
    bind \ex _delete_commandline_from_history
    bind \eZ redo
    bind \ez undo
    bind \ue000 forward-char
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

# Android settings.

# Export first available version of Android native development kit.
#
# Flags:
#   -d: Check if path is a directory.
function _export_ndk_home
    for folder in $argv[1]/*
        if test -d $folder
            set --export --global NDK_HOME $folder
            break
        end
    end
end

# Add Android CLI tools to system path.
if test $_os = Darwin
    set --export ANDROID_HOME "$HOME/Library/Android/sdk"
else
    set --export ANDROID_HOME "$HOME/.local/android/sdk"
end
_export_ndk_home "$ANDROID_HOME/ndk"
prepend_paths "$ANDROID_HOME/cmdline-tools/latest/bin" \
    "$ANDROID_HOME/emulator" "$ANDROID_HOME/platform-tools"

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

# FFmpeg settings.

# Disable verbose FFmpeg banners.
alias ffmpeg 'ffmpeg -hide_banner'
alias ffplay 'ffplay -hide_banner'
alias ffprobe 'ffprobe -hide_banner'

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

# Disable Fzf Alt-C command.
set --export FZF_ALT_C_COMMAND ''
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
    if type -q bat; and type -q lsd
        set --export FZF_CTRL_T_OPTS "--preview '_fzf_path_preview {}'"
    end
    if type -q fd
        set --export FZF_DEFAULT_COMMAND 'fd --hidden'
        if test $_os = Darwin
            set --export FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND --search-path \$dir"
        end
    end

    # Change Fzf file search keybinding to Ctrl+F.
    bind --erase \ec
    bind --erase \ct
    bind \cf fzf-file-widget
end

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

# Lsd settings.

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

# Initialize Node Version Manager if available.
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

    # Quotes are necessary for the if statement to ensure that the test function
    # always receives the correct number of arguments.
    if test -n "$cwd"; and test "$cwd" != "$PWD"
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
#
# Flags:
#   -n: Check if string is nonempty.
#   -q: Only check for exit status by supressing output.
#   -z: Check if the string is empty.
if test -n $_tty; and test $TERM = alacritty; and test -z $TERM_PROGRAM
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal and within an interactive shell for the login user. For more
    # information, visit https://zellij.dev/documentation/integration.html.
    #
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For for information, visit
    # https://github.com/vercel/hyper/issues/3762.
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
    source_bash_files "$HOME/.env" "$HOME/.secrets"
end
source_files "$HOME/.env.fish" "$HOME/.secrets.fish"
