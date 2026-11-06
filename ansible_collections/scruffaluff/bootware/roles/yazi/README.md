# Yazi

Ansible role that installs [Yazi](https://yazi-rs.github.io) file manager.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
yazi_plugins:
  - Rolv-Apneseth/starship
  - lpnh/fr
  - yazi-rs/plugins:chmod
  - yazi-rs/plugins:full-border
  - yazi-rs/plugins:git
  - yazi-rs/plugins:mime-ext
  - yazi-rs/plugins:piper
  - yazi-rs/plugins:smart-filter
  - yazi-rs/plugins:toggle-pane
  - yazi-rs/plugins:zoom
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.yazi
```
