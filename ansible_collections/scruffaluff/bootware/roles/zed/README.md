# Zed

Ansible role that installs [Zed](https://zed.dev) text editor.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
zed_ai: false
zed_extensions:
  colored-zed-icons-theme: true
  deno: true
  dockerfile: true
  emmet: true
  fish: true
  harper: true
  html: true
  jinja2: true
  just: true
  kdl: true
  latex: true
  lua: true
  log: true
  make: true
  neocmake: true
  nu: true
  powershell: true
  rainbow-csv: true
  solarized: true
  toml: true
  typst: true
  vue: true
zed_font_code: FiraCode Nerd Font
zed_font_sans: Fira Sans
zed_font_size: 14
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.zed
```
