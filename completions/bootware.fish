# Fish completion file for Bootware.
#
# For a tutorial on writing Fish completions, visit
# https://fishshell.com/docs/current/completions.html.

# Add Bootware options and subcommands as completions.
#
# Flags:
#   -F: Allow completion to be followed by a filename.
#   -a <options>: Add options to completions list.
#   -c <command>: Provide completions for command.
#   -d <description>: Add description to completion prompt.
#   -f: Do not allow files from current directory as a completion option.
#   -l <word>: Add word as a long switch flag
#   -n <condition>: Only use this condition if case evaluates to 0. 
#   -r: Completion must have an argument before another option.
#   -s <character>: Add character as a short switch flag.
complete -c bootware -n '__fish_use_subcommand' -s 'h' -l 'help' -d 'Print help information'
complete -c bootware -n '__fish_use_subcommand' -s 'v' -l 'version' -d 'Print version information'

complete -f -c bootware -n '__fish_use_subcommand' -a bootstrap -d 'Boostrap install computer software'
complete -f -c bootware -n '__fish_use_subcommand' -a config -d 'Generate Bootware configuration file'
complete -f -c bootware -n '__fish_use_subcommand' -a setup -d 'Install dependencies for Bootware'
complete -f -c bootware -n '__fish_use_subcommand' -a uninstall -d 'Remove Bootware files'
complete -f -c bootware -n '__fish_use_subcommand' -a update -d 'Update Bootware to latest version'

complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'check' -d 'Perform dry run and show possible changes'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'debug' -d 'Enable Ansible task debugger'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'no-passwd' -d 'Do not ask for user password'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'no-setup' -d 'Skip Bootware dependency installation'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'windows' -d 'Connect to a Windows host with SSH'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 'd' -l 'dev' -d 'Run bootstrapping in development mode'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 'h' -l 'help' -d 'Print help information'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'checkout' -d 'Git reference to run against'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'password' -d 'Remote host user password'
complete -Fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'ssh-key' -d 'Path to SSH private key'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -l 'user' -d 'Remote host user login name'
complete -Fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 'c' -l 'config' -d 'Path to bootware user configuation file'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 'i' -l 'inventory' -d 'Ansible host IP addesses'
complete -Fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 'p' -l 'playbook' -d 'Path to playbook to execute'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 's' -l 'skip' -d 'Ansible playbook tags to skip'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 't' -l 'tags' -d 'Ansible playbook tags to select'
complete -fr -c bootware -n '__fish_seen_subcommand_from bootstrap' -s 'u' -l 'url' -d 'URL of playbook repository'

complete -c bootware -n '__fish_seen_subcommand_from config' -s 'e' -l 'empty' -d 'Write empty configuration file'
complete -c bootware -n '__fish_seen_subcommand_from config' -s 'h' -l 'help' -d 'Print help information'
complete -Fr -c bootware -n '__fish_seen_subcommand_from config' -s 'd' -l 'dest' -d 'Path to alternate download destination'
complete -fr -c bootware -n '__fish_seen_subcommand_from config' -s 's' -l 'source' -d 'URL to configuration file'

complete -c bootware -n '__fish_seen_subcommand_from setup' -s 'h' -l 'help' -d 'Print help information'

complete -c bootware -n '__fish_seen_subcommand_from uninstall' -s 'h' -l 'help' -d 'Print help information'

complete -c bootware -n '__fish_seen_subcommand_from update' -s 'h' -l 'help' -d 'Print help information'
complete -fr -c bootware -n '__fish_seen_subcommand_from update' -s 'v' -l 'version' -d 'Version override for update'
