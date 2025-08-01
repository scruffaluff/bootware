# Nushell general configuration file.
#
# For more information, visit https://www.nushell.sh/book/configuration.html.

# Private convenience functions.

# Symlink scripts to user autoload directory.
def _autoload-scripts [...scripts: path] {
    let autoload_dir = $nu.user-autoload-dirs.0
    mkdir $autoload_dir
    for script in $scripts {
        let source = $script | path expand
        let dest = $"($autoload_dir)/($script | path basename)" | path expand
        if ($source | path exists) and not ($dest | path exists) {
            if $nu.os-info.name == "windows" {
                # Soft links require admin permissions unlike hard links.
                mklink /H $dest $source | ignore
            } else {
                ln -s $source $dest
            }
        }
    }
}

# Generate Nushell color theme.
#
# Documented at
# https://www.nushell.sh/book/coloring_and_theming.html#color-configuration.
def _color-theme [] {
    # Set solarized light theme variables based on
    # https://ethanschoonover.com/solarized/#the-values.
    let base03 = "#002b36"
    let base02 = "#073642"
    let base01 = "#586e75"
    let base00 = "#657b83"
    let base0 = "#839496"
    let base1 = "#93a1a1"
    let base2 = "#eee8d5"
    let base3 = "#fdf6e3"
    let yellow = "#b58900"
    let orange = "#cb4b16"
    let red = "#dc322f"
    let magenta = "#d33682"
    let violet = "#6c71c4"
    let blue = "#268bd2"
    let cyan = "#2aa198"
    let green = "#859900"

    # Values based on solarized light theme from
    # https://github.com/nushell/nu_scripts/blob/main/themes/nu-themes/solarized-light.nu.
    {
        background: $base3
        binary: $violet
        block: $blue
        bool: {|| if $in { $cyan } else { $yellow } }
        "cell-path": $base01
        closure: $cyan
        cursor: $base01
        custom: $base03
        date: {|| (date now) - $in |
            if $in < 1hr {
                $red
            } else if $in < 6hr {
                $red
            } else if $in < 1day {
                $yellow
            } else if $in < 3day {
                $green
            } else if $in < 1wk {
                $green
            } else if $in < 6wk {
                $cyan
            } else if $in < 52wk {
                $blue
            } else {
                $base1
            }
        }
        duration: $yellow
        empty: $blue
        filesize: {|element|
            if $element == 0b {
                $base01
            } else if $element < 1mb {
                $cyan
            } else {
                $blue
            }
        }
        float: $red
        foreground: $base01
        glob: $base03
        header: $green
        hints: $base0
        int: $violet
        leading_trailing_space_bg: { attr: "n" }
        list: $cyan
        nothing: $red
        range: $yellow
        record: $cyan
        row_index: $green
        search_result: { bg: $base01 fg: $red }
        separator: $base01
        shape_and: $violet
        shape_binary: $violet
        shape_block: $blue
        shape_bool: $cyan
        shape_closure: $cyan
        shape_custom: $green
        shape_datetime: $cyan
        shape_directory: $cyan
        shape_external_resolved: $cyan
        shape_external: $cyan
        shape_externalarg: $green
        shape_filepath: $cyan
        shape_flag: $blue
        shape_float: $red
        shape_garbage: { bg: $red fg: $base3 }
        shape_glob_interpolation: $cyan
        shape_globpattern: $cyan
        shape_int: $violet
        shape_internalcall: $cyan
        shape_keyword: $violet
        shape_list: $cyan
        shape_literal: $blue
        shape_match_pattern: $green
        shape_matching_brackets: { attr: "u" }
        shape_nothing: $red
        shape_operator: $yellow
        shape_or: $violet
        shape_pipe: $violet
        shape_range: $yellow
        shape_raw_string: $base03
        shape_record: $cyan
        shape_redirection: $violet
        shape_signature: $green
        shape_string_interpolation: $cyan
        shape_string: $green
        shape_table: $blue
        shape_vardecl: { attr: "u" fg: $blue }
        shape_variable: $violet
        string: $green
    }
}

# Cut commandline one path component to the left.
#
# Based on Fish's backward-kill-path-component from 
# https://fishshell.com/docs/current/cmds/bind.html#special-input-functions.
def _cut-path-left [] {
    let chars = commandline | split chars
    let cursor = commandline get-cursor
    let first = $chars | slice ..<$cursor | str join
    let second = $chars | slice $cursor.. | str join

    let update = $first
    | str replace --regex "[^\\/={}'\":@ |;<>&,]+[\\/={}'\":@ |;<>&,]*$" ""
    commandline edit --replace $"($update)($second)"
    commandline set-cursor ($update | str length)
}

# Prompt user to remove current command from Nushell history.
def _delete-from-history [] {
    let line = commandline
    let matches = history
    | where command =~ $line
    | reverse
    | get command
    | uniq
    if ($matches | is-empty) {
        return
    }

    print "\nNushell History Entry Delete\n"
    print $matches
    print "
Enter nothing to cancel the delete, or
Enter one or more of the entry IDs or ranges like '5..12', separated by a space.
For example '7 10..15 35 788..812'.
Enter 'all' to delete all the matching entries.
"

    let text = try {
        input "Delete which entries? "
    } catch {
        print "\n\nCancelling the delete!\n"
        return 
    }

    mut selections = []
    for word in ($text | split words) {
        if $word == "all" {
            print "Deleting all matching entries!"
            $selections = $matches
            break
        }

        let parts = $word | parse "{start}..{end}"
        if ($parts | is-empty) {
            try {
                let match = $matches | get ($word | into int)
                $selections = $match | append $selections
            } catch {
                print --stderr $"Ignoring invalid history entry ID \"($word)\""
            }
        } else {
            let start = try { $parts | get start | get 0 } catch { 0 }
            let end = try { $parts | get end | get 0 } catch { -1 }
            try {
                $selections = $matches | slice $start..$end | append $selections
            } catch {
                print --stderr $"Ignoring invalid history entry ID \"($word)\""
            }
        }
    }

    let update = history | where command not-in $selections | get command
    $update | to text | save --force $nu.history-path
    commandline edit --replace ""
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

# Change the owner of each file for Windows.
def _wchown [
    --recursive (-R) # Operate on files and directories recursively
    owner: string # User account to give ownership
    ...files: path # File or directory to modify
] {
    for file in $files {
        powershell -command $"
$Account = New-Object -TypeName System.Security.Principal.NTAccount `
    -ArgumentList '($owner)'

$Paths = @\(Get-Item -Path '($file)'\)
if \('($recursive)' -eq 'true'\) {
    $Paths += Get-ChildItem -Recurse -Path ($file)
}

foreach \($Path in $Paths\) {
    $ACL = Get-Acl -Path $Path.FullName
    $ACL.SetOwner\($Account\)
    Set-Acl -AclObject $ACL -Path $Path.FullName
}
"
    }
}

# Public convenience functions.

# List Windows ACL properties for files.
def acls [
    path: path = "." # File or directory
] {
    if $nu.os-info.name == "windows" {
        powershell -command $"
Get-ChildItem ($path) | ForEach-Object {
    $ACL = Get-Acl $_.FullName
    [PSCustomObject]@{ name = $_.Name; owner = $ACL.Owner }
} | ConvertTo-Csv -NoTypeInformation
"
        | from csv
    } else {
        error make { msg: "wacls is only defined for Windows" }
    }
}

# Complete commandline argument with Carapace.
def carapace-complete [spans: list<string>] {
    let expanded_alias = scope aliases
    | where name == $spans.0
    | get --optional 0
    | get --optional expansion

    let spans = if $expanded_alias != null  {
        $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
    } else {
        $spans | skip 1 | prepend ($spans.0)
    }

    carapace $spans.0 nushell ...$spans | from json
}

# Wrapper for cat command with Windows support.
def --wrapped cat [...args: string] {
    match $nu.os-info.name {
        "windows" => { open --raw ...$args },
        _ => { ^cat ...$args },
    }
}

# Wrapper for chown command with Windows support.
def --wrapped chown [...args: string] {
    match $nu.os-info.name {
        "windows" => {
            let args_ = $args | where {|arg| not ($arg in ["-R", "--recursive"]) }
            let length = $args_ | length

            if $length < 2 {
                _wchown --help
            } else if $length < ($args | length) {
                _wchown --recursive $args_.0 ...($args_ | skip 1)
            } else {
                _wchown $args_.0 ...($args_ | skip 1)
            }
        },
        _ => { ^chown ...$args },
    }
}

# Open Nushell history file with default editor.
def edit-history [] {
    if "EDITOR" in $env {
        run-external $env.EDITOR $nu.history-path
    } else {
        vi $nu.history-path
    }
}

# Complete commandline argument with Fish.
def fish-complete [spans: list<string>] {
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | from tsv --flexible --noheaders --no-infer
    | rename value description
}

# Complete commandline argument with interactive history search.
def fzf-history-widget [] {
    let history = history | get command | reverse | uniq | to text
    let selection = (
        $history | fzf --query (commandline) --scheme history
    )

    if ($selection | is-not-empty) {
        commandline edit --replace $selection
    }
}

# Complete commandline argument with interactive path search.
def fzf-path-widget [] {
    # Set temporary Fzf environment variables in same manner as "fzf --fish".
    $env.FZF_DEFAULT_COMMAND = $"($env.FZF_CTRL_T_COMMAND?)"
    $env.FZF_DEFAULT_OPTS = $"($env.FZF_DEFAULT_OPTS?) ($env.FZF_CTRL_T_OPTS?)"

    let line = commandline
    let cursor = commandline get-cursor

    # Split command line arguments while considering quotes.
    let parts = $line
    | parse --regex '(".*?"|\'.*?\'|`.*?`|[^\s]+|\s+)' 
    | get capture0

    # Find argument under the cursor.
    mut index = 0
    mut token = ""
    mut sum = 0
    for part in $parts {
        $sum = $sum + ($part | str length)
        if $cursor <= $sum {
            if ($part | str trim | is-not-empty) {
                $token = $part
            }
            break
        }
        $index += 1
    }

    # Build Fzf search path from current token.
    let search_dir = if ($token | is-empty) { "." } else { $token }

    # Exit early if search path is invalid or change Fzf execution directory.
    if ($token | path type) != "dir" {
        return
    }
    cd $search_dir
    let path = fzf --scheme "path" --walker "file,dir,follow,hidden"

    # Exit early if no selection was made, i.e. user sigkilled Fzf.
    if ($path | is-empty) {
        return
    }

    # Add quotes if path contains a space.
    mut full_path = $token | path join $path
    if ($full_path | str contains " ") {
        $full_path = $"`($full_path)`"
    }

    # Insert selection and update cursor to end of path.
    if ($token | is-empty) {
        commandline edit --insert $path
        commandline set-cursor --end
    } else {
        let diff = ($full_path | str length) - ($token | str length)
        let edit = $parts | update $index $full_path | str join
        commandline edit --replace $edit
        commandline set-cursor ($sum + $diff)
    }
}

# Prepend existing directories that are not in the system path.
def --env prepend-paths [...paths: directory] {
    $env.PATH = $paths 
    | each {|path| $path | path expand }
    | where {|path| ($path | path type) == "dir" and not ($path in $env.PATH) }
    | reverse
    | [...$in ...$env.PATH]
}

# Check if current shell is within a remote SSH session.
def ssh-session [] {
    "SSH_CLIENT" in $env or "SSH_CONNECTION" in $env or "SSH_TTY" in $env
}

# System settings.

# Ensure standard Unix environment variables are defined.
if $nu.os-info.name == "windows" {
    $env.HOME = $env.HOME? | default $"($env.HOMEDRIVE?)($env.HOMEPATH?)"
    $env.USER = $env.USER? | default $env.USERNAME?
} else {
    $env.HOME = $env.HOME?
    $env.USER = $env.USER?
}

# Set terminal environment variable if empty.
if ($env.TERM? | is-empty) {
    $env.TERM = "xterm-256color"
}

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
(
    prepend-paths "/usr/sbin" "/usr/local/bin" "/opt/homebrew/sbin"
    "/opt/homebrew/bin" $"($env.HOME)/.local/bin"
)

# Alacritty settings.

# Autostart Zellij or connect to existing session if within Alacritty
# terminal and within an interactive shell for the login user. For more
# information, visit https://zellij.dev/documentation/integration.html.
if (
    $nu.is-interactive and $env.TERM? == "alacritty" and "TERM_PROGRAM" not-in
    $env
) {
    # Do not use logname command, since it sometimes incorrectly returns "root"
    # on MacOS. For more information, visit
    # https://github.com/vercel/hyper/issues/3762.
    if (
        "ZELLIJ" not-in $env and not (ssh-session) and
        $env.LOGNAME? == $env.USER and (which "zellij" | is-not-empty)
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

# Carapace settings.

$env.CARAPACE_BRIDGES = "fish,bash"
$env.CARAPACE_MERGEFLAGS = "1"

# Clipboard settings.

# Add unified clipboard commands.
#
# Commands are defined as functions instead of OS specific aliases since Nushell
# does not support conditional defintions.
def --wrapped cbcopy [...args: string] {
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
def --wrapped cbpaste [...args: string] {
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

# Add LazyDocker convenience alias.
alias lzd = lazydocker

# Fd settings.

# Always have Fd read available gitignore files.
alias fd = ^fd --no-require-git

# FFmpeg settings.

# Disable verbose FFmpeg banners.
alias ffmpeg = ^ffmpeg -hide_banner -stats -loglevel error
alias ffplay = ^ffplay -hide_banner -loglevel error
alias ffprobe = ^ffprobe -hide_banner

# Fzf settings.

# Disable Fzf Alt-C command.
$env.FZF_ALT_C_COMMAND = ""
# Set Fzf styles with solarized light theme based on
# https://github.com/tinted-theming/tinted-fzf/blob/main/fish/base16-solarized-light.fish.
$env.FZF_BASE_OPTS = (
    "--border --reverse --bind ctrl-d:backward-kill-word "
    + "--color bg:#fdf6e3,bg+:#eee8d5,fg:#657b83,fg+:#073642 "
    + "--color header:#268bd2,hl:#268bd2,hl+:#268bd2,info:#b58900 "
    + "--color marker:#2aa198,pointer:#2aa198,prompt:#b58900 "
    + "--color spinner:#2aa198 --height ~80%"
)
$env.FZF_DEFAULT_OPTS = $"($env.FZF_BASE_OPTS) --with-shell 'nu --commands'"

# Load Fzf if interactive and available.
if $nu.is-interactive and (which fzf | is-not-empty) {
    if (which bat | is-not-empty) and (which lsd | is-not-empty) {
        # Preview function needs to be inlined since "nu --commands" does not
        # load the configuration files.
        let path_preview = 'do {|path|
            if ($path | path type) == "dir" {
                lsd --tree --depth 1 $path
            } else {
                bat --color always --line-range :100 --style numbers $path
            }
        }'
        $env.FZF_CTRL_T_OPTS = (
            $"--preview '($path_preview) {}' --preview-window border-left"
        )
    }
    if (which fd | is-not-empty) {
        $env.FZF_CTRL_T_COMMAND = "fd --hidden --no-require-git"
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
alias jt = just --global-justfile

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

# Add Jupyter Lab alias.
def --wrapped jupylab [...args] {
    (
        uv --quiet tool run --from jupyterlab --with bokeh,numpy,polars,scipy
        jupyter-lab ...$args
    )
}
# Add Python debugger alias.
alias pdb = python3 -m pdb

# Make Poetry create virtual environments inside projects.
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

# Rclone settings.

# Make Rclone skip modifcation time updates.
$env.RCLONE_NO_UPDATE_DIR_MODTIME = "true"
$env.RCLONE_NO_UPDATE_MODTIME = "true"

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
# Make Rsync use progress bars and skip ignored files.
alias rsync = ^rsync --partial --progress --filter ":- .gitignore"

# Configure prompt if interactive.
if $nu.is-interactive {
    $env.PROMPT_COMMAND = {||
        let path = $env.PWD | path basename
        $"\n($env.USER) at (sys host | get hostname) in ($path)\n" 
    }
    $env.PROMPT_COMMAND_RIGHT = ""
    $env.PROMPT_INDICATOR = "❯ "
}

$env.config = {
    color_config: (_color-theme)
    keybindings: [
        {
            event: { edit: movewordleft }
            keycode: char_b
            mode: [emacs vi_insert vi_normal]
            modifier: alt
        }
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
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    [
                        { edit: movewordrightend }
                        { edit: moveright }
                    ]
                ]
            }
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
            event: { cmd: _delete-from-history send: executehostcommand }
            keycode: char_x
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
            event: { cmd: fzf-path-widget send: executehostcommand }
            keycode: char_f
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
            event: { cmd: "commandline | cbcopy" send: executehostcommand }
            keycode: char_x
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
            event: {
                until: [
                    { name: completion_menu send: menu }
                    { send: menunext }
                ]
            }
            keycode: char_ue004
            mode: [emacs vi_insert vi_normal]
            modifier: none
        }
        {
            event: { edit: moveleft }
            keycode: char_ue005
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
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    [
                        { edit: movebigwordrightend }
                        { edit: moveright }
                    ]
                ]
            }
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

# Enable external completions if available.
if (which "carapace" | is-not-empty) {
    $env.config.completions = {
        external: {
            completer: {|spans| carapace-complete $spans }
            enable: true
        }
    }
} else if (which "fish" | is-not-empty) {
    $env.config.completions = {
        external: {
            completer: {|spans| fish-complete $spans }
            enable: true
        }
    }
}

# Starship settings.

# Disable Starship warnings about command timeouts.
$env.STARSHIP_LOG = "error"

# TypeScript settings.

# Disable Deno update messages.
$env.DENO_NO_UPDATE_CHECK = "true"
# Add Deno binaries to system path.
prepend-paths $"($env.HOME)/.deno/bin"

# Add NPM global binaries to system path.
prepend-paths $"($env.HOME)/.npm/global/bin"

# Add PNPM binaries to system path.
$env.PNPM_HOME = match $nu.os-info.name {
    "macos" => $"($env.HOME)/Library/pnpm"
    "windows" => $"($env.HOME)/AppData/Local/pnpm"
    _ => $"($env.HOME)/.local/share/pnpm"
}
prepend-paths $env.PNPM_HOME

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path.
prepend-paths "/usr/share/code/bin" \
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# Yazi settings.

# Disable Yazi Zoxide plugin directory preview window.
$env.YAZI_ZOXIDE_OPTS = $"($env.FZF_BASE_OPTS) --preview-window hidden"

# Yazi wrapper to change directory on program exit.
def --env --wrapped yz [...args] {
  let tmp_file = mktemp --tmpdir
  yazi --cwd-file $tmp_file ...$args

  let cwd = open $tmp_file
  if ($cwd | is-not-empty) and $cwd != $env.PWD {
    cd $cwd
  }
  rm $tmp_file
}

# Zoxide settings.

# Disable Zoxide directory preview window.
$env._ZO_FZF_OPTS = $"($env.FZF_BASE_OPTS) --preview-window hidden"

# User settings.

# Move user aliases, secrets, and variables to the user autoload folder.
_autoload-scripts $"($env.HOME)/.env.nu" $"($env.HOME)/.secrets.nu"
