# Obsidian

Ansible role that installs [Obsidian](https://obsidian.md) note taker.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
obsidian_font_code: FiraCode Nerd Font
obsidian_font_sans: Fira Sans
obsidian_font_serif: PT Serif
obsidian_vault: null
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.obsidian
```
