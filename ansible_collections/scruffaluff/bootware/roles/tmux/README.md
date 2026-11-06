# Tmux

Ansible role that installs [Tmux](https://github.com/tmux/tmux) terminal
multiplexer.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
user_shell_executable: /usr/bin/nu # Linux default
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.tmux
```
