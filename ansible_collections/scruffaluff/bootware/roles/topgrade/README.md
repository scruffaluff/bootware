# Topgrade

Ansible role that installs [Topgrade](https://github.com/topgrade-rs/topgrade)
package updater.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
topgrade_disables: []
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.topgrade
```
