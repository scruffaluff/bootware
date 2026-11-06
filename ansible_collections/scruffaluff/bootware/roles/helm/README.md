# Helm

Ansible role that installs [Helm](https://helm.sh) Kubernetes package manager.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
helm_plugins: []
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.helm
```
