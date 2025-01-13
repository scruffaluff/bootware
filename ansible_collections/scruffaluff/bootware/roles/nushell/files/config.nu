# Nushell settings file.
#
# For more information, visit https://www.nushell.sh/book/configuration.html.

# Private convenience functions.

def _append_pager [] {
    let cmd = $" &| ($env.PAGER)"
    let line = commandline

    if ($line | str ends-with $cmd) {
        commandline edit --replace ($line | str replace $cmd "")
    } else {
        commandline edit --append $cmd
    }
}

def _get_os [] {
    let os = sys host | get name | str downcase
    if ($os | str contains "linux") { "linux" } else { $os }
}

let fish_completer = {|spans|
    fish --command $'complete "--do-complete=($spans | str join " ")"'
    | $"value(char tab)description(char newline)" + $in
    | from tsv --flexible --no-infer
}

# Private convenience variables.
let _os = _get_os

# Shell settings.

# Add alias for remove by force.
alias rmf = rm -fr
# Make rsync use human friendly output.
alias rsync = rsync --partial --progress --filter ":- .gitignore"

$env.config = {
    completions: {
        external: {
            enable: true,
            completer: $fish_completer,
        },
    },
    keybindings: [
        {
            event: { send: openeditor }
            keycode: char_e
            mode: [emacs, vi_insert, vi_normal]
            modifier: alt
        },
        {
            event: { cmd: _append_pager, send: executehostcommand }
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
if (which "bat" | length) != 0 {
    $env.PAGER = "bat"
}

# Starship settings.

# Disable Starship warnings about command timeouts.
$env.STARSHIP_LOG = "error"

# Initialize Starship if available.
if (which "starship" | length) != 0 {
    let starship_script = ($nu.data-dir | path join "vendor/autoload/starship.nu")
    if not ($starship_script | path exists) {
        mkdir ($starship_script | path dirname)
        starship init nu | save --force $starship_script
    }
}
