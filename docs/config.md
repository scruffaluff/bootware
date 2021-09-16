# Configuration

Bootware uses the [YAML](https://yaml.org/) language for its configuration file.
Bootware uses the first available path option as its configuration file.

- `<path>` (argument to -c/--config command line flag)
- `bootware.yaml` (in the current directory)
- `BOOTWARE_CONFIG` (environment variable)
- `~/.bootware/config.yaml` (in the home directory)

Bootware can generate a default configuration file in the user's home directory,
by executing `bootware config`.
