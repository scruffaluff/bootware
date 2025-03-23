# Fish completion file for Bootware.
#
# For a tutorial on writing Fish completions, visit
# https://fishshell.com/docs/current/completions.html.

complete --erase --command bootware
complete --no-files --command bootware

# Add Bootware options and subcommands as completions.
#
# Flags:
#   -F: Allow completion to be followed by a filename.
#   -a <OPTIONS>: Add arguments to completions list.
#   -c <COMMAND>: Provide completions for command.
#   -d <DESCRIPTION>: Add description to completion prompt.
#   -f: Prevent completion from being followed by a filename.
#   -l <WORD>: Add word as a long switch flag.
#   -n <CONDITION>: Only use this configuration if condition is true.
#   -r: Completion must have an argument before another option.
#   -s <CHARACTER>: Add character as a short switch flag.
#   -x: Apply both -f and -r flags.
complete -c bootware -n __fish_use_subcommand -l debug -d 'Enable shell debug traces'
complete -c bootware -n __fish_use_subcommand -s h -l help -d 'Print help information'
complete -c bootware -n __fish_use_subcommand -s v -l version -d 'Print version information'

complete -c bootware -n __fish_use_subcommand -a bootstrap -d 'Boostrap install computer software'
complete -c bootware -n __fish_use_subcommand -a config -d 'Generate Bootware configuration file'
complete -c bootware -n __fish_use_subcommand -a roles -d 'List all Bootware roles'
complete -c bootware -n __fish_use_subcommand -a setup -d 'Install dependencies for Bootware'
complete -c bootware -n __fish_use_subcommand -a uninstall -d 'Remove Bootware files'
complete -c bootware -n __fish_use_subcommand -a update -d 'Update Bootware to latest version'

complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l check -d 'Perform dry run and show possible changes'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l checkout -d 'Git reference to run against'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -Fr -s c -l config -d 'Path to bootware user configuration file'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l debug -d 'Enable Ansible task debugger'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -s d -l dev -d 'Run bootstrapping in development mode'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -s h -l help -d 'Print help information'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l install-group -d 'Remote group to install software for'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l install-user -d 'Remote user to install software for'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -s i -l inventory -d 'Ansible remote hosts IP addesses'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l no-passwd -d 'Do not ask for user password'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l no-setup -d 'Skip Bootware dependency installation'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l password -d 'Remote user login password'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -Fr -s p -l playbook -d 'Path to playbook to execute'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -Fr -l private-key -d 'Path to SSH private key'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l port -d 'Port for SSH connection'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l retries -d 'Playbook retry limit during failure'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -s s -l skip -d 'Ansible playbook tags to skip'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l start-at-role -d 'Begin execution with role'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -s t -l tags -d 'Ansible playbook tags to select'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -Fr -l temp-key -d 'Path to SSH private key for one time connection'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -s u -l url -d 'URL of playbook repository'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -x -l user -d 'Remote user login name'
complete -c bootware -n '__fish_seen_subcommand_from bootstrap' -l windows -d 'Connect to a Windows host with SSH'

complete -c bootware -n '__fish_seen_subcommand_from config' -Fr -s d -l dest -d 'Path to alternate download destination'
complete -c bootware -n '__fish_seen_subcommand_from config' -s e -l empty -d 'Write empty configuration file'
complete -c bootware -n '__fish_seen_subcommand_from config' -s h -l help -d 'Print help information'
complete -c bootware -n '__fish_seen_subcommand_from config' -x -s s -l source -d 'URL to configuration file'

complete -c bootware -n '__fish_seen_subcommand_from roles' -s h -l help -d 'Print help information'
complete -c bootware -n '__fish_seen_subcommand_from roles' -x -s t -l tags -d 'Ansible playbook tags to select'
complete -c bootware -n '__fish_seen_subcommand_from roles' -x -s u -l url -d 'URL of playbook repository'

complete -c bootware -n '__fish_seen_subcommand_from setup' -s h -l help -d 'Print help information'

complete -c bootware -n '__fish_seen_subcommand_from uninstall' -s h -l help -d 'Print help information'

complete -c bootware -n '__fish_seen_subcommand_from update' -s h -l help -d 'Print help information'
complete -c bootware -n '__fish_seen_subcommand_from update' -x -s v -l version -d 'Version override for update'
