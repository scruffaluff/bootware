# Desktop Environment

Ansible role that configures desktop environments.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
gnome_extensions:
  - light-style@gnome-shell-extensions.gcampax.github.com
  - rounded-window-corners@fxgn
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.desktop_environment
```
