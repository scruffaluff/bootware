# Configuration

## Configuration File

Bootware uses the [YAML](https://yaml.org/) language for its configuration file.
Bootware uses the first available path option as its configuration file.

- `<path>` (argument to -c/--config command line flag)
- `bootware.yaml` (in the current directory)
- `BOOTWARE_CONFIG` (environment variable)
- `~/.bootware/config.yaml` (in the home directory)

Bootware can generate a default configuration file in the user's home directory,
by executing `bootware config`.

## Environment Variables

Several Bootware options can also be specified with environment variables.

- `BOOTWARE_CONFIG`: Set the configuration file path
- `BOOTWARE_NOPASSWD`: Assume passwordless doas or sudo
- `BOOTWARE_NOSETUP`: Skip Ansible install and system setup
- `BOOTWARE_PLAYBOOK`: Set Ansible playbook name
- `BOOTWARE_SKIP`: Set skip tags for Ansible roles
- `BOOTWARE_TAGS`: Set tags for Ansible roles
- `BOOTWARE_URL`: Set location of Ansible repository

## Command Line

Many Bootware features can controlled directly fron the command line. For a list
of options, execute `bootware --help` or `bootware <subcommand> --help` for a
subcommand's specific options.
