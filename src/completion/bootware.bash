# Bash completion file for Bootware.
#
# For a tutorial on writing Bash completions, visit
# https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html.

# Add Bootware options and subcommands as completions.
#
# Flags:
#   -W <WORDS>: Add words as completion subcommands.
complete -W 'bootstrap config roles setup uninstall update' bootware
