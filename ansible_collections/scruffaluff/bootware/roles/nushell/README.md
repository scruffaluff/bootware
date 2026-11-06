# Nushell

Ansible role that installs [Nushell](https://nushell.sh) shell.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
nushell_plugins:
  - nu_plugin_formats
  - nu_plugin_gstat
  - nu_plugin_inc
  - nu_plugin_polars
  - nu_plugin_query
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.nushell
```
