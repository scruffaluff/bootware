# Prune

Ansible role that removes bloatware packages.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
prune_copr_repositories:
  - phracek/PyCharm
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.prune
```
