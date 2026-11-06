# Wezterm

Ansible role that installs [Wezterm](https://wezterm.org) terminal emulator.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
user_shell_executable: /usr/bin/nu # Linux default
wezterm_font_size: 14
wezterm_wayland: true
wezterm_window_decorations: false
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.wezterm
```
