# Alacritty

Ansible role that installs [Alacritty](https://alacritty.org/) terminal.

## Requirements

None.

## Role Variables

Role uses the following variables with default values.

```yaml
font_size: 14
user_shell: "{{ standard_powershell_or_fish_shell_path }}"
```

The role will automatically select the standard path for the Fish shell for host
operating system or the standard path for the latest PowerShell version on
Windows by default for `user_shell`.

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.alacritty
```
