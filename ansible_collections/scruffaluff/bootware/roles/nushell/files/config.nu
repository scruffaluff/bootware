# Nushell settings file.
#
# For more information, visit https://www.nushell.sh/book/configuration.html.

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
    not ($"($env.$SSH_CLIENT)($env.SSH_CONNECTION)$env.SSH_TTY)" | is-empty)
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

# Shell settings.

# Add alias for remove by force.
alias rmf = rm -fr
# Make rsync use human friendly output.
alias rsync = ^rsync --partial --progress --filter ":- .gitignore"

$env.config = {
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

  let cwd = cat $tmp_file
  if ($cwd | is-not-empty) and ($cwd != $env.PWD) {
    cd $cwd
  }
  rm $tmp_file
}

# Alacritty settings.

# Placed near end of config to ensure Zellij reads the correct window size.
if ($env.TERM == "alacritty") and ($env.TERM_PROGRAM | is-empty) {
    # Autostart Zellij or connect to existing session if within Alacritty
    # terminal and within an interactive shell for the login user. For more
    # information, visit https://zellij.dev/documentation/integration.html.
    #
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For for information, visit
    # https://github.com/vercel/hyper/issues/3762.
    if (which "zellij" | is-not-empty) and (not is-ssh-session) and ($env.LOGNAME == $env.USER) {
        zellij attach -c
    }

    # Switch TERM variable to avoid "alacritty: unknown terminal type" errors
    # during remote connections.
    #
    # For more information, visit
    # https://github.com/alacritty/alacritty/issues/3962.
    $env.TERM = "xterm-256color"
}
