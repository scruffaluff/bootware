# VSCode

Ansible role that installs [VSCode](https://code.visualstudio.com) text editor.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
vscode_ai: false
vscode_font_size: 14
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.vscode
```
