# Installation

Bootware is invoked by shell scripts on the user's computer. The following
commands will download the shell scripts and add them to the system path.

<code-group>
<code-block title="FreeBSD">
```bash
curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/install.sh | bash
```
</code-block>

<code-block title="Linux" active>
```bash
curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/install.sh | bash
```
</code-block>

<code-block title="MacOS">
```bash
curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/install.sh | bash
```
</code-block>

<code-block title="Windows">
```powershell
Invoke-WebRequest -UseBasicParsing -Uri  https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/install.ps1 | Invoke-Expression
```
</code-block>
</code-group>

On MacOS, some programs may need to be manually opened after installation, since
third party applications require user review. Visit
https://support.apple.com/en-us/HT202491, for more information.

On an Apple Silicon system, ensure that the current terminal is not running
under Rosetta 2, by confirming that the output of command `uname -p` is `arm`.

On Windows, PowerShell will need to run as administrator and the security policy
must allow for running remote PowerShell scripts. The following command will
update the security policy, if needed.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```
