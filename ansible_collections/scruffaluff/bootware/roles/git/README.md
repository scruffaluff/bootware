# Git

Ansible role that installs [Git](https://git-scm.com) version control.

## Requirements

None.

## Role Variables

Role variables are listed below with defaults.

```yaml
git_editor: hx
git_user_email: user.name@mail.com
git_user_name: User Name
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.git
```
