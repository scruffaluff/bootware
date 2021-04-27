# Fish completion file for Bootware.
#
# For a tutorial on writing Fish completions, visit
# https://fishshell.com/docs/current/completions.html.

# Set list of Bootware subcommands
#
# Flags:
#   -l: Make variable scope local to current block.
set -l bootware_subcommands bootstrap config setup update

# Add Bootware subcommands as current completions if not already typed.
#
# Flags:
#   -a <options>: Add options to completions list.
#   -c <command>: Provide completions for command.
#   -n <condition>: Only use this condition if case evaluates to 0. 
#   -f: Do not allow files from current directory as a completion option.
complete -f -c bootware -n "not __fish_seen_subcommand_from $bootware_subcommands" -a "$bootware_subcommands"

# Add descriptions to subcommand completion options.
#
# Flags:
#   -d <description>: Add description to completion prompt.
complete -f -c bootware -n "not __fish_seen_subcommand_from $bootware_subcommands" -a bootstrap -d "Boostrap install computer software"
complete -f -c bootware -n "not __fish_seen_subcommand_from $bootware_subcommands" -a config -d "Generate Bootware configuration file"
complete -f -c bootware -n "not __fish_seen_subcommand_from $bootware_subcommands" -a setup -d "Install dependencies for Bootware"
complete -f -c bootware -n "not __fish_seen_subcommand_from $bootware_subcommands" -a update -d "Update Bootware to latest version"
