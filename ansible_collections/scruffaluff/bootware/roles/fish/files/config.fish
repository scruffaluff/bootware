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
    set --function command (commandline | string collect | string trim)
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
    set --function line (commandline | string collect)
    set --function working_directory "$(string replace "$HOME" '~' $(pwd))/"

    if string match --entire --quiet $working_directory $line
        commandline --replace (string replace $working_directory '' $line)
    else
        commandline --insert $working_directory
    end
end

# Paste pipe to system pager command into the commandline.
#
# Flags:
#   -n: Check if string is nonempty.
function _paste_pager
    # Variable 'PAGER' needs quotes in case it is not defined.
    set --function program
    if test -n "$PAGER"
        set program $PAGER
    else
        set program less
    end

    set --function line (commandline | string collect)
    set --function command " &| $program"
    set --function query (string escape --style regex $command)

    set --function newline (string replace --regex "$query\$" '' $line)
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
        vi "$HOME/.local/share/fish/fish_history"
    end
end

# Override system implementation of command not found.
#
# Some system implementations will perform a long lookup to see if a package
# provides the command.
function fish_command_not_found
    echo "Error: command '$argv[1]' not found" >&2
end

# Complete commandline argument with interactive path search.
#
# Flags:
#   -d: Check if path is a directory.
function fzf-path-widget
    # Set temporary Fzf environment variables in same manner as "fzf --fish".
    set --export --function FZF_DEFAULT_COMMAND "$FZF_CTRL_T_COMMAND"
    set --export --function FZF_DEFAULT_OPTS \
        "$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS"

    set --function line (commandline)
    set --function path
    set --function cwd $PWD
    set --function token (commandline --current-token)

    # Build Fzf search path from current token.
    set --function search_dir
    if test -n $token
        set search_dir \
            (string replace '~' $HOME (string trim --chars '"\'' $token))
    else
        set search_dir .
    end

    # Exit early if search path is invalid or change Fzf execution directory.
    if not test -d $search_dir
        return
    end
    cd $search_dir
    set path (fzf --scheme path --walker file,dir,follow,hidden)
    cd $cwd

    # Exit early if no selection was made, i.e. user sigkilled Fzf.
    if test -z $path
        commandline --function repaint
        return
    end

    # Add quotes or escape spaces if path contains a space.
    if string match --regex '[^\\\] ' $path
        if string match --regex '^\'' $token
            set path "$path'"
        else if string match --regex '^\"' $token
            set path "$path\""
        else
            set path (string replace --all ' ' '\\ ' $path)
        end
    end
    # Prepend path with "/" if necessary and not current directory.
    if string match --regex '[^\/.]$' $token
        set path "/$path"
    end

    # Insert selection and update cursor to end of path.
    commandline --insert $path
    commandline --cursor --current-token \
        (math (string length $token) + (string length $path))
    commandline --function repaint
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
    if type -q zellij; and test -z $ZELLIJ; and not ssh-session;
        and test $LOGNAME = $USER
        # Attach to a default session if it exists.
        set --export ZELLIJ_AUTO_ATTACH true
        # Exit the shell when Zellij exits.
        set --export ZELLIJ_AUTO_EXIT true
        SHELL=(status fish-path) eval (zellij setup --generate-auto-start fish |
            string collect)
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
        set --function text
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
        set --function text
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

# Fd settings.

# Always have Fd read available gitignore files.
alias fd 'fd --no-require-git'

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
    # Set Fzf styles with solarized light theme based on
    # https://github.com/tinted-theming/tinted-fzf/blob/main/fish/base16-solarized-light.fish.
    set --export FZF_DEFAULT_OPTS '--border --reverse ' \
        '--bind ctrl-d:backward-kill-word --color bg:#fdf6e3,bg+:#eee8d5 ' \
        '--color fg:#657b83,fg+:#073642,header:#268bd2,hl:#268bd2 ' \
        '--color hl+:#268bd2,info:#b58900,marker:#2aa198,pointer:#2aa198 ' \
        '--color prompt:#b58900,spinner:#2aa198 --height ~80% ' \
        "--with-shell 'fish --command'"

    fzf --fish | source
    if type -q bat; and type -q lsd
        set --export FZF_CTRL_T_OPTS "--preview '_fzf_path_preview {}'" \
            "--preview-window border-left"
    end
    if type -q fd
        set --export FZF_CTRL_T_COMMAND 'fd --hidden --no-require-git'
    end

    # Change Fzf file search keybinding to Ctrl+F.
    bind --erase \ec
    bind --erase \ct
    bind \cf fzf-path-widget
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

# Replace Ls with Lsd if available.
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

# Make Poetry create virtual environments inside projects.
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

# Add keybindings and color theme if interactive.
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
        bind \eb backward-word
        bind \ec _paste_cwd
        bind \ed kill-bigword
        bind \ef forward-word
        bind \ep _paste_pager
        bind \ex _delete_commandline_from_history
        bind \eZ redo
        bind \ez undo
        bind \ue000 forward-char
        bind \ue001 'prevd; commandline --function repaint'
        bind \ue002 'nextd; commandline --function repaint'
        bind \ue003 complete-and-search
    end

    # Set solarized light theme variables based on
    # https://ethanschoonover.com/solarized/#the-values.
    set --local base03 '#002b36'
    set --local base02 '#073642'
    set --local base01 '#586e75'
    set --local base00 '#657b83'
    set --local base0 '#839496'
    set --local base1 '#93a1a1'
    set --local base2 '#eee8d5'
    set --local base3 '#fdf6e3'
    set --local yellow '#b58900'
    set --local orange '#cb4b16'
    set --local red '#dc322f'
    set --local magenta '#d33682'
    set --local violet '#6c71c4'
    set --local blue '#268bd2'
    set --local cyan '#2aa198'
    set --local green '#859900'

    # Set Fish color theme as documented at
    # https://fishshell.com/docs/current/interactive.html#syntax-highlighting-variables.
    set --global fish_color_autosuggestion $base1
    set --global fish_color_cancel --reverse
    set --global fish_color_command $cyan
    set --global fish_color_comment $base1
    set --global fish_color_cwd $green
    set --global fish_color_cwd_root $red
    set --global fish_color_end $blue
    set --global fish_color_error $red
    set --global fish_color_escape $cyan
    set --global fish_color_history_current --bold
    set --global fish_color_host $base0
    set --global fish_color_host_remote $yellow
    set --global fish_color_keyword $base01
    set --global fish_color_match --background $base0
    set --global fish_color_normal $base0
    set --global fish_color_operator $cyan
    set --global fish_color_option $base00
    set --global fish_color_param $base00
    set --global fish_color_quote $base0
    set --global fish_color_redirection $violet
    set --global fish_color_search_match --background $base2 $base00
    set --global fish_color_selection --bold --background $base03 $base2
    set --global fish_color_status $red
    set --global fish_color_user $base01
    set --global fish_color_valid_path --underline

    set --global fish_pager_color_background
    set --global fish_pager_color_completion $green
    set --global fish_pager_color_description $yellow
    set --global fish_pager_color_prefix cyan --underline
    set --global fish_pager_color_progress --background $cyan $base3
    set --global fish_pager_color_secondary_background
    set --global fish_pager_color_secondary_completion
    set --global fish_pager_color_secondary_description
    set --global fish_pager_color_secondary_prefix
    set --global fish_pager_color_selected_background --background $base2
    set --global fish_pager_color_selected_completion
    set --global fish_pager_color_selected_description
    set --global fish_pager_color_selected_prefix
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

# Add Deno binaries to system path.
prepend-paths "$HOME/.deno/bin"

# Add NPM global binaries to system path.
prepend-paths "$HOME/.npm/global/bin"

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
    set --function tmp (mktemp)
    yazi --cwd-file $tmp $argv
    set --function cwd (cat $tmp)

    # Quotes are necessary for the if statement to ensure that the test function
    # always receives the correct number of arguments.
    if test -n "$cwd"; and test "$cwd" != "$PWD"
        cd $cwd
    end
    rm $tmp
end

# Zoxide settings.

# Disable fickle Zoxide directory preview.
set --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS"

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
