# Rust

Ansible role that installs [Rust](https://rust-lang.org) language.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
rust_components:
  - clippy
  - llvm-tools-preview
  - rust-analyzer
  - rust-src
  - rustfmt
rust_targets: []
rust_toolchain: stable
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.rust
```
