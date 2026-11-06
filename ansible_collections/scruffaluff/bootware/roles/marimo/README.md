# Marimo

Ansible role that installs [Marimo](https://marimo.io/) interactive notebook
environment.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
marimo_ai: false
```

## Dependencies

Requires Python tomlkit package.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.marimo
```
