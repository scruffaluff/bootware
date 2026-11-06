# Node

Ansible role that installs [Node](https://nodejs.org) JavaScript runtime.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
node_applications:
  - "@playwright/cli"
  - "@slidev/cli"
  - "@vue/language-server"
  - bash-language-server
  - lean-language-server
  - live-server
  - speed-test
  - speedscope
  - taze
  - tombi
  - typescript-language-server
  - vls
  - vscode-langservers-extracted
  - wikit
  - yaml-language-server
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.node
```
