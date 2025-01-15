# Nushell settings file.
#
# For more information, visit https://www.nushell.sh/book/configuration.html.

# use std/util
# path add "~/.local/bin"

# Private convenience functions.

def append-pager [] {
    let cmd = $" &| ($env.PAGER)"
    let line = commandline

    if ($line | str ends-with $cmd) {
        commandline edit --replace ($line | str replace $cmd "")
    } else {
        commandline edit --append $cmd
    }
}

def get-os [] {
    let os = sys host | get name | str downcase
    if ($os | str contains "linux") { "linux" } else { $os }
}

# Check if current shell is within a remote SSH session.
def is-ssh-session [] {
    "SSH_CLIENT" in $env or "SSH_CONNECTION" in $env or "SSH_TTY" in $env
}

# Public convenience script functions.

# Prepend existing directories that are not in the system path.
def prepend-paths [...paths: directory] {
    for path in $paths {
        if ($path | path type) == "dir" and not ($path in $env.PATH) {
            $env.PATH = $env.PATH | prepend $path
        }
    }
}

# Private convenience variables.

let _brew_prefix = if ("/opt/homebrew" | path exists) {
    "/opt/homebrew"
} else {
    "/usr/local"
}
let _os = get-os

# Nusehll configuration.

$env.config = {
    # Based on solarized light theme from
    # https://github.com/nushell/nu_scripts/tree/main/themes.
    color_config: {
        background: "#fdf6e3"
        binary: "#6c71c4"
        block: "#268bd2"
        bool: {|| if $in { "#2aa198" } else { "#b58900" }}
        cell-path: "#586e75"
        closure: "#2aa198"
        cursor: "#586e75"
        custom: "#002b36"
        date: {|| (date now) - $in |
            if $in < 1hr {
                { attr: "b", fg: "#dc322f" }
            } else if $in < 6hr {
                "#dc322f"
            } else if $in < 1day {
                "#b58900"
            } else if $in < 3day {
                "#859900"
            } else if $in < 1wk {
                { attr: "b", fg: "#859900" }
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
        header: { attr: "b", fg: "#859900" }
        hints: "#839496"
        int: "#6c71c4"
        leading_trailing_space_bg: { attr: "n" }
        list: "#2aa198"
        nothing: "#dc322f"
        range: "#b58900"
        record: "#2aa198"
        row_index: { attr: "b", fg: "#859900" }
        search_result: { bg: "#586e75", fg: "#dc322f" }
        separator: "#586e75"
        shape_and: { attr: "b", fg: "#6c71c4" }
        shape_binary: { attr: "b", fg: "#6c71c4" }
        shape_block: { attr: "b", fg: "#268bd2" }
        shape_bool: "#2aa198"
        shape_closure: { attr: "b", fg: "#2aa198" }
        shape_custom: "#859900"
        shape_datetime: { attr: "b", fg: "#2aa198" }
        shape_directory: "#2aa198"
        shape_external_resolved: "#2aa198"
        shape_external: "#2aa198"
        shape_externalarg: { attr: "b", fg: "#859900" }
        shape_filepath: "#2aa198"
        shape_flag: { attr: "b", fg: "#268bd2" }
        shape_float: { attr: "b", fg: "#dc322f" }
        shape_garbage: { attr: "b", bg: "#FF0000", fg: "#FFFFFF" }
        shape_glob_interpolation: { attr: "b", fg: "#2aa198" }
        shape_globpattern: { attr: "b", fg: "#2aa198" }
        shape_int: { attr: "b", fg: "#6c71c4" }
        shape_internalcall: { attr: "b", fg: "#2aa198" }
        shape_keyword: { attr: "b", fg: "#6c71c4" }
        shape_list: { attr: "b", fg: "#2aa198" }
        shape_literal: "#268bd2"
        shape_match_pattern: "#859900"
        shape_matching_brackets: { attr: "u" }
        shape_nothing: "#dc322f"
        shape_operator: "#b58900"
        shape_or: { attr: "b", fg: "#6c71c4" }
        shape_pipe: { attr: "b", fg: "#6c71c4" }
        shape_range: { attr: "b", fg: "#b58900" }
        shape_raw_string: { attr: "b", fg: "#002b36" }
        shape_record: { attr: "b", fg: "#2aa198" }
        shape_redirection: { attr: "b", fg: "#6c71c4" }
        shape_signature: { attr: "b", fg: "#859900" }
        shape_string_interpolation: { attr: "b", fg: "#2aa198" }
        shape_string: "#859900"
        shape_table: { attr: "b", fg: "#268bd2" }
        shape_vardecl: { attr: "u", fg: "#268bd2" }
        shape_variable: "#6c71c4"
        string: "#859900"
    },
    keybindings: [
        {
            event: { send: openeditor }
            keycode: char_e
            mode: [emacs, vi_insert, vi_normal]
            modifier: alt
        },
        {
            event: { name: help_menu, send: menu }
            keycode: char_h
            mode: [emacs, vi_insert, vi_normal]
            modifier: alt
        },
        {
            event: { cmd: append-pager, send: executehostcommand }
            keycode: char_p
            mode: [emacs, vi_insert, vi_normal]
            modifier: alt
        },
        {
            event: { edit: cutwordleft }
            keycode: char_d
            mode: [emacs, vi_insert, vi_normal]
            modifier: control
        },
        {
            event: null
            keycode: char_w
            mode: [emacs, vi_insert, vi_normal,]
            modifier: control
        }
    ],
    ls: { clickable_links: true, use_ls_colors: true },
    # Prevents prompt duplication in SSH sessions to a remote Windows machine.
    #
    # For more information, visit
    # https://github.com/nushell/nushell/issues/5585.
    shell_integration: {
        osc133: ($_os != "windows"),
    },
    show_banner: false,
}

# Shell settings.

# Add alias for remove by force.
alias rmf = rm -fr
# Make rsync use human friendly output.
alias rsync = ^rsync --partial --progress --filter ":- .gitignore"

# Set solarized light color theme for several Unix tools.
#
# Uses output of command "vivid generate solarized-light" from
# https://github.com/sharkdp/vivid.
if ($"($env.HOME)/.ls_colors" | path exists) {
    $env.LS_COLORS = open $"($env.HOME)/.ls_colors"
}

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
(prepend-paths "/usr/sbin" "/usr/local/bin" "/opt/homebrew/sbin"
    "/opt/homebrew/bin" $"($env.HOME)/.local/bin")

# Bat settings.

# Set default pager to Bat.
if (which "bat" | is-not-empty) {
    $env.PAGER = "bat"
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

# Helix settings.

# Set default editor to Helix if available.
if (which "hx" | is-not-empty) {
    $env.EDITOR = "hx"
    $env.SUDO_EDITOR = "hx"
}

# Homebrew settings

# Avoid Homebrew hints after installing a package.
$env.HOMEBREW_NO_ENV_HINTS = "true"

# Just settings.

# Add alias for account wide Just recipes.
alias jt = just --justfile $"($env.HOME)/.justfile" --working-directory .

# Kubernetes settings.

# Add Kubectl plugins to system path.
prepend-paths $"($env.HOME)/.krew/bin"

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

# Make numerical compute libraries findable on MacOS.
if $_os == "darwin" {
    $env.OPENBLAS = $"($_brew_prefix)/opt/openblas"
    prepend-paths $env.OPENBLAS
}

# Add Pyenv binaries to system path.
$env.PYENV_ROOT = $"($env.HOME)/.pyenv"
prepend-paths $"($env.PYENV_ROOT)/bin" f"($env.PYENV_ROOT)/shims"

# Initialize Pyenv if available.
if (which pyenv | is-not-empty) {
    # while set pyenv_index (contains -i -- "/home/scruffaluff/.pyenv/shims" $PATH)
    # set -eg PATH[$pyenv_index]; end; set -e pyenv_index
    # set -gx PATH '/home/scruffaluff/.pyenv/shims' $PATH
    # set -gx PYENV_SHELL fish
    # source '/home/scruffaluff/.pyenv/completions/pyenv.fish'
    # command pyenv rehash 2>/dev/null
    # function pyenv
    #   set command $argv[1]
    #   set -e argv[1]
    
    #   switch "$command"
    #   case activate deactivate rehash shell
    #     source (pyenv "sh-$command" $argv|psub)
    #   case "*"
    #     command pyenv "$command" $argv
    #   end
    # end
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

# Starship settings.

# Disable Starship warnings about command timeouts.
$env.STARSHIP_LOG = "error"

# Initialize Starship if available.
if (which "starship" | is-not-empty) {
    let script = ($nu.data-dir | path join "vendor/autoload/starship.nu")
    if not ($script | path exists) {
        mkdir ($script | path dirname)
        starship init nu | save --force $script
    }
}

# TypeScript settings.

# Add Bun binaries to system path.
$env.BUN_INSTALL = $"($env.HOME)/.bun"
prepend-paths $"($env.BUN_INSTALL)/bin"

# Add Deno binaries to system path.
prepend-paths "${HOME}/.deno/bin"

# Add NPM global binaries to system path.
prepend-paths "${HOME}/.npm-global/bin"

# Initialize Node Version Manager if available.
$env.NVM_DIR = $"($env.HOME)/.nvm"

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path for Linux.
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

# Alacritty settings.

# Placed near end of config to ensure Zellij reads the correct window size.
if ($env.TERM == "alacritty") and not ("TERM_PROGRAM" in $env) {
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal and within an interactive shell for the login user. For more
    # information, visit https://zellij.dev/documentation/integration.html.
    #
    # Based on output of "zellij setup --generate-auto-start bash" command.
    #
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For for information, visit
    # https://github.com/vercel/hyper/issues/3762.
    if (which "zellij" | is-not-empty) and not (is-ssh-session) and ($env.LOGNAME == $env.USER) and not ("ZELLIJ" in $env) {
        with-env { SHELL: (which nu | get path | first) } { zellij attach --create }
        exit
    }

    # Switch TERM variable to avoid "alacritty: unknown terminal type" errors
    # during remote connections.
    #
    # For more information, visit
    # https://github.com/alacritty/alacritty/issues/3962.
    $env.TERM = "xterm-256color"
}
