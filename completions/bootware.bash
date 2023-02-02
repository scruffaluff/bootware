# Bash completion file for Bootware.
#
# For a tutorial on writing Fish completions, visit
# https://fishshell.com/docs/current/completions.html.

# Add Bootware options and subcommands as completions.
#
# Flags:
#   -W <words>: Add words as completion subcommands.
complete -W 'bootstrap config roles setup uninstall update' bootware
