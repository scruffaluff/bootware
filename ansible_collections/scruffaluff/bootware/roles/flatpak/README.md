# Flatpak

Ansible role that installs [Flatpak](https://flatpak.org) packages.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
flatpak_packages_gnome:
  - com.mattjakeman.ExtensionManager
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.flatpak
```
