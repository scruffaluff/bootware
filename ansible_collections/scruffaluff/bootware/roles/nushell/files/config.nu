# Nushell general configuration file.
#
# For more information, visit https://www.nushell.sh/book/configuration.html.

# Private convenience functions.

# Cut commandline one path component to the left.
#
# Based on Fish's backward-kill-path-component from 
# https://fishshell.com/docs/current/cmds/bind.html#special-input-functions.
def _cut-path-left [] {
    let chars = commandline | split chars
    let cursor = commandline get-cursor
    let first = $chars | range ..$cursor | str join
    let second = $chars | range $cursor.. | str join

    let update = $first
    | str replace --regex "[^/={}'\":@ |;<>&,]+[/={}'\":@ |;<>&,]*$" ""
    commandline edit --replace $"($update)($second)"
    commandline set-cursor ($update | str length)
}

# Path preview for Fzf file finder.
def _fzf-path-preview [path: string] {
    if ($path | path type) == "dir" {
        lsd --tree --depth 1 $path
    } else {
        bat --color always --line-range :100 --style numbers $path
    }
}

# Paste current working directory into the commandline.
def _paste-cwd [] {
    let cwd = $"($env.PWD)/" | str replace $env.HOME "~"
    let line = commandline | str replace $cwd ""

    if $line == (commandline) {
        commandline edit --insert $cwd
    } else {
        commandline edit --replace $line
    }
}

# Paste pipe to fuzzy finder into the commandline.
def _paste-fzf [] {
    let line = commandline | str replace --regex $" \\| fzf\$" ""

    if $line == (commandline) {
        commandline edit --replace $"($line) | fzf"
    } else {
        commandline edit --replace $line
    }
}

# Paste pipe to system pager command into the commandline.
def _paste-pager [] {
    let pager = $env.PAGER? | default "less"
    let line = commandline | str replace --regex $" \\| ($pager)\$" ""

    if $line == (commandline) {
        commandline edit --replace $"($line) | ($pager)"
    } else {
        commandline edit --replace $line
    }
}

# Prepend super user command into the commandline.
def _paste-super [] {
    let super = if (which doas | is-not-empty) { "doas" } else { "sudo" }
    let line = commandline | str replace --regex $"^($super) " ""

    if $line == (commandline) {
        commandline edit --replace $"($super) ($line)"
    } else {
        commandline edit --replace $line
    }
}

# Public convenience functions.

# Open Nushell history file with default editor.
def edit-history [] {
    if ("EDITOR" in $env) {
        run-external $env.EDITOR $nu.history-path
    } else {
        vi $nu.history-path
    }
}

# Search and paste files under cursor path into the commandline.
def fzf-file-widget [] {
    let line = commandline
    let cursor = commandline get-cursor
    # Split command line arguments while considering quotes.
    let parts = $line
    | parse --regex '(".*?"|\'.*?\'|[^\s]+|\s+)' 
    | get capture0

    # Find argument under the cursor.
    mut arg = ""
    mut sum = 0
    for part in $parts {
        $sum = $sum + ($part | str length)
        if $cursor <= $sum {
            if ($part | str trim | is-not-empty) {
                $arg = $part
            }
            break
        }
    }

    let path = if ($arg | path type) == "dir" {
        cd $arg
        fzf --multi --query ""
    } else {
        fzf --multi --query $arg
    }

    if ($path | is-not-empty) {
        if ($arg | is-empty) {
            commandline edit --insert $path
            commandline set-cursor --end
        } else {
            let fullpath = $arg | path join $path
            let diff = ($fullpath | str length) - ($arg | str length $arg)
            commandline edit --replace ($line | str replace $arg $fullpath)
            commandline set-cursor ($sum + $diff)
        }
    }
}

# Search and paste command from history into the commandline.
def fzf-history-widget [] {
    let history = history | get command | reverse | uniq | to text
    let selection = $history | fzf --tac --query (commandline) --scheme history

    if ($selection | is-not-empty) {
        commandline edit --replace $selection
    }
}

# Prepend existing directories that are not in the system path.
def --env prepend-paths [...paths: directory] {
    $env.PATH = $paths 
    | filter {|path| ($path | path type) == "dir" and not ($path in $env.PATH) }
    | reverse
    | [...$in ...$env.PATH]
}

# Check if current shell is within a remote SSH session.
def ssh-session [] {
    "SSH_CLIENT" in $env or "SSH_CONNECTION" in $env or "SSH_TTY" in $env
}

# System settings.

# Add standard Unix environment variables for Windows.
if $nu.os-info.name == "windows" {
    $env.HOME = $"($env.HOMEDRIVE)($env.HOMEPATH)"
    $env.USER = $env.USERNAME
}

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
(
    prepend-paths
    "/usr/sbin"
    "/usr/local/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/bin"
    $"($env.HOME)/.local/bin"
)

# Alacritty settings.

if (
    $nu.is-interactive
    and ($env.TERM? == "alacritty")
    and not ("TERM_PROGRAM" in $env)
) {
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal and within an interactive shell for the login user. For more
    # information, visit https://zellij.dev/documentation/integration.html.
    #
    # Based on output of "zellij setup --generate-auto-start bash" command.
    #
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For for information, visit
    # https://github.com/vercel/hyper/issues/3762.
    if (
        (which "zellij" | is-not-empty)
        and not ("ZELLIJ" in $env)
        and not (ssh-session)
        and ($env.LOGNAME? == $env.USER)
    ) {
        with-env { SHELL: $nu.current-exe } { zellij attach --create }
        # Close parent shell after Zellij exits.
        exit
    }

    # Switch TERM variable to avoid "alacritty: unknown terminal type" errors
    # during remote connections.
    #
    # For more information, visit
    # https://github.com/alacritty/alacritty/issues/3962.
    $env.TERM = "xterm-256color"
}

# Bat settings.

# Set default pager to Bat.
if (which "bat" | is-not-empty) {
    $env.PAGER = "bat"
}

# Clipboard settings.

# Add unified clipboard commands.
#
# Commands are defined as functions instead of OS specific aliases since Nushell
# does not support conditional defintions.
def --wrapped cbcopy [...args] {
    match $nu.os-info.name {
        "macos" => { pbcopy ...$args },
        "windows" => {
            let text = if ($in | is-empty) {
                echo ...$args | str join " "
            } else {
                $in
            }
            powershell -command $"Set-Clipboard '($text)'"
        },
        _ => { wl-copy ...$args },
    }
}
def --wrapped cbpaste [...args] {
    match $nu.os-info.name {
        "macos" => { pbpaste ...$args },
        "windows" => { powershell -command Get-Clipboard },
        _ => { wl-paste ...$args },
    }
}

# Docker settings.

# Ensure newer Docker features are enabled.
$env.COMPOSE_DOCKER_CLI_BUILD = "true"
$env.DOCKER_BUILDKIT = "true"
$env.DOCKER_CLI_HINTS = "false"

# FFmpeg settings.

# Disable verbose FFmpeg banners.
alias ffmpeg = ^ffmpeg -hide_banner
alias ffplay = ^ffplay -hide_banner
alias ffprobe = ^ffprobe -hide_banner

# Fzf settings.

# Load Fzf settings if interactive and available.
if $nu.is-interactive and (which fzf | is-not-empty) {
    # Disable Fzf Alt-C command.
    $env.FZF_ALT_C_COMMAND = ""
    # Set Fzf solarized light theme and shell command for child processes.
    $env.FZF_DEFAULT_OPTS = (
        "--reverse --color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33 "
        + "--color info:136,prompt:136,pointer:230,marker:230,spinner:136 "
        + "--with-shell 'nu --commands'"
    )

    if (which bat | is-not-empty) and (which lsd | is-not-empty) {
        $env.FZF_CTRL_T_OPTS = "--preview '_fzf-path-preview {}'"
    }
    if (which fd | is-not-empty) {
        $env.FZF_DEFAULT_COMMAND = "fd --hidden"
    }
}

# Helix settings.

# Set default editor to Helix if available.
if (which "hx" | is-not-empty) {
    $env.EDITOR = "hx"
    $env.SUDO_EDITOR = "hx"
}

# Homebrew settings

# Avoid Homebrew hints after installing a package for Unix.
if $nu.os-info.name != "windows" {
    $env.HOMEBREW_NO_ENV_HINTS = "true"
}

# Just settings.

# Add alias for account wide Just recipes.
alias jt = just --justfile $"($env.HOME)/.justfile" --working-directory .

# Kubernetes settings.

# Add Kubectl plugins to system path.
prepend-paths $"($env.HOME)/.krew/bin"

# Lsd settings.

# Set solarized light color theme for several Unix tools.
#
# Uses output of command "vivid generate solarized-light" from
# https://github.com/sharkdp/vivid.
if ($"($env.HOME)/.ls_colors" | path exists) {
    $env.LS_COLORS = open $"($env.HOME)/.ls_colors"
}

# Procs settings.

# Set light theme since Procs automatic theming fails on some systems.
alias procs = ^procs --theme light

# Python settings.

# Add Python debugger alias.
alias pdb = python3 -m pdb

# Make Poetry create virutal environments inside projects.
$env.POETRY_VIRTUALENVS_IN_PROJECT = "true"
# Fix Poetry package install issue on headless systems.
$env.PYTHON_KEYRING_BACKEND = "keyring.backends.fail.Keyring"

# Make numerical compute libraries findable for MacOS.
if $nu.os-info.name == "macos" {
    let brew_prefix = if ("/opt/homebrew" | path exists) {
        $env.OPENBLAS = "/opt/homebrew/opt/openblas"
    } else { 
        $env.OPENBLAS = "/usr/local/opt/openblas"
    }
    prepend-paths $env.OPENBLAS
}

# Add Pyenv binaries to system path for Unix.
if $nu.os-info.name != "windows" {
    $env.PYENV_ROOT = $"($env.HOME)/.pyenv"
    prepend-paths $"($env.PYENV_ROOT)/bin" $"($env.PYENV_ROOT)/shims"
}

# Ripgrep settings.

# Set Ripgrep settings file location.
$env.RIPGREP_CONFIG_PATH = $"($env.HOME)/.ripgreprc"

# Rust settings.

# Add Rust debugger aliases.
alias rgd = rust-gdb --quiet
alias rld = rust-lldb --source-quietly

# Add Rust binaries to system path.
prepend-paths $"($env.HOME)/.cargo/bin"

# Shell settings.

# Add alias for remove by force.
alias rmf = rm --force --recursive
# Make rsync use human friendly output.
alias rsync = ^rsync --partial --progress --filter ":- .gitignore"

# Configure prompt if interactive.
if $nu.is-interactive {
    $env.PROMPT_COMMAND = {||
        let path = $env.PWD | path basename
        $"\n($env.USER) at (sys host | get hostname) in ($path)\n\n" 
    }
    $env.PROMPT_COMMAND_RIGHT = ""
    $env.PROMPT_INDICATOR = "❯ "
}

$env.config = {
    # Based on solarized light theme from
    # https://github.com/nushell/nu_scripts/tree/main/themes.
    color_config: {
        background: "#fdf6e3"
        binary: "#6c71c4"
        block: "#268bd2"
        bool: {|| if $in { "#2aa198" } else { "#b58900" } }
        cell-path: "#586e75"
        closure: "#2aa198"
        cursor: "#586e75"
        custom: "#002b36"
        date: {|| (date now) - $in |
            if $in < 1hr {
                { attr: "b" fg: "#dc322f" }
            } else if $in < 6hr {
                "#dc322f"
            } else if $in < 1day {
                "#b58900"
            } else if $in < 3day {
                "#859900"
            } else if $in < 1wk {
                { attr: "b" fg: "#859900" }
            } else if $in < 6wk {
                "#2aa198"
            } else if $in < 52wk {
                "#268bd2"
            } else {
                "dark_gray"
            }
        }
        duration: "#b58900"
        empty: "#268bd2"
        filesize: {|element|
            if $element == 0b {
                "#586e75"
            } else if $element < 1mb {
                "#2aa198"
            } else {
                { fg: "#268bd2" }
            }
        }
        float: "#dc322f"
        foreground: "#586e75"
        glob: "#002b36"
        header: { attr: "b" fg: "#859900" }
        hints: "#839496"
        int: "#6c71c4"
        leading_trailing_space_bg: { attr: "n" }
        list: "#2aa198"
        nothing: "#dc322f"
        range: "#b58900"
        record: "#2aa198"
        row_index: { attr: "b" fg: "#859900" }
        search_result: { bg: "#586e75" fg: "#dc322f" }
        separator: "#586e75"
        shape_and: { attr: "b" fg: "#6c71c4" }
        shape_binary: { attr: "b" fg: "#6c71c4" }
        shape_block: { attr: "b" fg: "#268bd2" }
        shape_bool: "#2aa198"
        shape_closure: { attr: "b" fg: "#2aa198" }
        shape_custom: "#859900"
        shape_datetime: { attr: "b" fg: "#2aa198" }
        shape_directory: "#2aa198"
        shape_external_resolved: "#2aa198"
        shape_external: "#2aa198"
        shape_externalarg: { attr: "b" fg: "#859900" }
        shape_filepath: "#2aa198"
        shape_flag: { attr: "b" fg: "#268bd2" }
        shape_float: { attr: "b" fg: "#dc322f" }
        shape_garbage: { attr: "b" bg: "#FF0000" fg: "#FFFFFF" }
        shape_glob_interpolation: { attr: "b" fg: "#2aa198" }
        shape_globpattern: { attr: "b" fg: "#2aa198" }
        shape_int: { attr: "b" fg: "#6c71c4" }
        shape_internalcall: { attr: "b" fg: "#2aa198" }
        shape_keyword: { attr: "b" fg: "#6c71c4" }
        shape_list: { attr: "b" fg: "#2aa198" }
        shape_literal: "#268bd2"
        shape_match_pattern: "#859900"
        shape_matching_brackets: { attr: "u" }
        shape_nothing: "#dc322f"
        shape_operator: "#b58900"
        shape_or: { attr: "b" fg: "#6c71c4" }
        shape_pipe: { attr: "b" fg: "#6c71c4" }
        shape_range: { attr: "b" fg: "#b58900" }
        shape_raw_string: { attr: "b" fg: "#002b36" }
        shape_record: { attr: "b" fg: "#2aa198" }
        shape_redirection: { attr: "b" fg: "#6c71c4" }
        shape_signature: { attr: "b" fg: "#859900" }
        shape_string_interpolation: { attr: "b" fg: "#2aa198" }
        shape_string: "#859900"
        shape_table: { attr: "b" fg: "#268bd2" }
        shape_vardecl: { attr: "u" fg: "#268bd2" }
        shape_variable: "#6c71c4"
        string: "#859900"
    }
    keybindings: [
        {
            event: { cmd: _paste-cwd send: executehostcommand }
            keycode: char_c
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { send: openeditor }
            keycode: char_e
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { cmd: _paste-fzf send: executehostcommand }
            keycode: char_f
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { name: help_menu send: menu }
            keycode: char_h
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { cmd: _paste-pager send: executehostcommand }
            keycode: char_p
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { cmd: _paste-super send: executehostcommand }
            keycode: char_s
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { edit: undo }
            keycode: char_z
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
        {
            event: { cmd: _cut-path-left send: executehostcommand }
            keycode: char_d
            mode: [emacs vi_insert vi_normal]
            modifier: control
        }
        {
            event: { cmd: fzf-file-widget send: executehostcommand }
            keycode: char_f
            mode: [emacs vi_insert vi_normal]
            modifier: control
        }
        {
            event: { edit: moveleft }
            keycode: char_j
            mode: [emacs vi_insert vi_normal]
            modifier: control
        }
        {
            event: null
            keycode: char_o
            mode: [emacs vi_insert vi_normal]
            modifier: control
        }
        {
            event: { cmd: fzf-history-widget send: executehostcommand }
            keycode: char_r
            mode: [emacs vi_insert vi_normal]
            modifier: control
        }
        {
            event: null
            keycode: char_w
            mode: [emacs vi_insert vi_normal]
            modifier: control
        }
        {
            event: { edit: moveright }
            keycode: char_ue000
            mode: [emacs vi_insert vi_normal]
            modifier: none
        }
        {
            event: { edit: movebigwordleft }
            keycode: left
            mode: [emacs vi_insert vi_normal]
            modifier: shift
        }
        {
            event: [
                { edit: movebigwordrightend }
                { edit: moveright }
            ]
            keycode: right
            mode: [emacs vi_insert vi_normal]
            modifier: shift
        }
        {
            event: { edit: redo }
            keycode: char_z
            mode: [emacs vi_insert vi_normal]
            modifier: shift_alt
        }
    ]
    ls: { clickable_links: true use_ls_colors: true }
    menus: [
        {
            marker: ""
            name: completion_menu
            only_buffer_difference: false
            style: {
                description_text: yellow
                selected_text: green_reverse
                text: green
            }
            type: {
                col_padding: 2
                col_width: 20
                columns: 4
                layout: columnar
            }
        }
        {
            marker: ""
            name: help_menu
            only_buffer_difference: true
            style: {
                description_text: yellow
                selected_text: green_reverse
                text: green
            }
            type: {
                col_padding: 2
                col_width: 20
                columns: 4
                description_rows: 10
                layout: description
                selection_rows: 4
            }
        }
        {
            marker: ""
            name: history_menu
            only_buffer_difference: true
            style: {
                description_text: yellow
                selected_text: green_reverse
                text: green
            }
            type: {
                layout: list
                page_size: 10
            }
        }
    ]
    # Prevents prompt duplication in SSH sessions to a remote Windows machine.
    #
    # For more information, visit
    # https://github.com/nushell/nushell/issues/5585.
    shell_integration: { osc133: ($nu.os-info.name != "windows") }
    show_banner: false
}

# Starship settings.

# Disable Starship warnings about command timeouts.
$env.STARSHIP_LOG = "error"

# TypeScript settings.

# Add Deno binaries to system path.
prepend-paths $"($env.HOME)/.deno/bin"

# Add NPM global binaries to system path.
prepend-paths $"($env.HOME)/.npm-global/bin"

# Initialize Node Version Manager if available for Unix.
if $nu.os-info.name != "windows" {
    $env.NVM_DIR = $"($env.HOME)/.nvm"
}

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path.
prepend-paths "/usr/share/code/bin"

# Wasmtime settings.

# Add Wasmtime binaries to system path.
$env.WASMTIME_HOME = $"($env.HOME)/.wasmtime"
prepend-paths $"($env.WASMTIME_HOME)/bin"

# Yazi settings.

# Yazi wrapper to change directory on program exit.
def --env --wrapped yz [...args] {
  let tmp_file = mktemp --tmpdir
  yazi --cwd-file $tmp_file ...$args

  let cwd = open $tmp_file
  if ($cwd | is-not-empty) and ($cwd != $env.PWD) {
    cd $cwd
  }
  rm $tmp_file
}
