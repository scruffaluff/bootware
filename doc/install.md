# Installation

## Shell Scripts

Bootware is invoked by shell scripts on the user's computer. The following
command will download the shell scripts and add them to the system path.

::: code-group

```sh [Unix]
curl -LSfs https://scruffaluff.github.io/bootware/install.sh | sh
```

```powershell [Windows PowerShell]
& ([ScriptBlock]::Create((irm https://scruffaluff.github.io/bootware/install.ps1)))
```

```nushell [Nushell]
http get https://scruffaluff.github.io/bootware/install.nu | nu -c $"($in | decode); main"
```

:::

The following command will show the script help message. Arguments can be passed
to the script by replacing the `--help` argument.

::: code-group

```sh [Unix]
curl -LSfs https://scruffaluff.github.io/bootware/install.sh | sh -s -- --help
```

```powershell [Windows PowerShell]
& ([ScriptBlock]::Create((irm https://scruffaluff.github.io/bootware/install.ps1))) --help
```

```nushell [Nushell]
http get https://scruffaluff.github.io/bootware/install.nu | nu -c $"($in | decode); main --help"
```

:::

::: warning

The Windows example must be executed from within a PowerShell session. See
[https://stackoverflow.com/a/54410144/7147804](https://stackoverflow.com/a/54410144/7147804)
for an explanation of this requirement.

On MacOS, some programs may need to be manually opened after installation, since
third party applications require user review. Visit
[https://support.apple.com/en-us/HT202491](https://support.apple.com/en-us/HT202491),
for more information.

On Windows, PowerShell will need to run as administrator and the security policy
must allow for running remote PowerShell scripts. If needed, the following
command will update the security policy for the current user.

:::

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Ansible Collection

Bootware is also available as an Ansible collection at
[Ansible Galaxy](https://galaxy.ansible.com/ui/repo/published/scruffaluff/bootware/)
, which can be installed with command
`ansible-galaxy collection install scruffaluff.bootware`.

The following playbook example runs a few of the Bootware roles and can be
executed with command
`ansible-playbook --connection local --inventory 127.0.0.1, playbook.yaml`.

```yaml
- hosts: all
  roles:
    - scruffaluff.bootware.age
    - scruffaluff.bootware.bat
    - scruffaluff.bootware.sops
    - scruffaluff.bootware.xh
```
