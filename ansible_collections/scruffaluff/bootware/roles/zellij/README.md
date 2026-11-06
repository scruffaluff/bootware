# Zellij

Ansible role that installs [Zellij](https://zellij.dev) terminal multiplexer.

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
    - scruffaluff.bootware.zellij
```
