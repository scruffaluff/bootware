# Fish

Ansible role that installs [Fish](https://fishshell.com) shell.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
fish_plugins:
  - edc/bass
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.fish
```
