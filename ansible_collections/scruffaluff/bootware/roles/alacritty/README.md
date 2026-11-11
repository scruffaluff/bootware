# Alacritty

Ansible role that installs [Alacritty](https://alacritty.org) terminal emulator.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
alacritty_font_code: FiraCode Nerd Font
alacritty_font_size: 14
user_shell_executable: /usr/bin/nu # Linux default
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.alacritty
```
