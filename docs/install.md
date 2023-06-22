# Installation

Bootware is invoked by shell scripts on the user's computer. The following
command will download the shell scripts and add them to the system path.

::: code-group

```bash [FreeBSD]
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh | bash
```

```bash [Linux]
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh | bash
```

```bash [MacOS]
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh | bash
```

```powershell [Windows]
iwr -useb https://raw.githubusercontent.com/scruffaluff/bootware/main/install.ps1 | iex
```

:::

The following command will show the script help message. Arguments can be passed
to the script by replacing the `--help` argument.

::: code-group

```bash [FreeBSD]
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh | bash -s -- --help
```

```bash [Linux]
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh | bash -s -- --help
```

```bash [MacOS]
curl -LSfs https://raw.githubusercontent.com/scruffaluff/bootware/main/install.sh | bash -s -- --help
```

```powershell [Windows]
powershell { & ([ScriptBlock]::Create((iwr -useb https://raw.githubusercontent.com/scruffaluff/bootware/main/install.ps1))) "--help" }
```

:::

::: warning

The Windows example must be executed from within a PowerShell session. See
[https://stackoverflow.com/a/54410144/7147804](https://stackoverflow.com/a/54410144/7147804)
for an explanation of the strange requirement.

On MacOS, some programs may need to be manually opened after installation, since
third party applications require user review. Visit
[https://support.apple.com/en-us/HT202491](https://support.apple.com/en-us/HT202491),
for more information.

On an Apple Silicon system, ensure that the current terminal is not running
under Rosetta 2, by confirming that the output of command `uname -p` is `arm`.

On Windows, PowerShell will need to run as administrator and the security policy
must allow for running remote PowerShell scripts. If needed, the following
command will update the security policy for the current user.

:::

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
