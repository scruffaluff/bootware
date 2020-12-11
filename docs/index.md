# Bootware

![](https://img.shields.io/github/repo-size/wolfgangwazzlestrauss/canvas)
![](https://img.shields.io/github/license/wolfgangwazzlestrauss/canvas)

---

<!-- prettier-ignore -->
**Documentation**: https://wolfgangwazzlestrauss.github.io/bootware

**Source Code**: https://github.com/wolfgangwazzlestrauss/bootware

---

Bootware is a set of shell scripts and Docker images for bootstrapping software
installations on a computer.

## Install

Bootware is invoked by shell scripts on the user's computer. The following
commands will download the shell scripts and add them to the system path. Note
that on Windows, PowerShell will need to run as administrator.

<code-group>
<code-block title="Linux" active>
```bash
sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh | bash -s -- update
```
</code-block>

<code-block title="MacOS">
```bash
sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh | bash -s -- update
```
</code-block>

<code-block title="Windows">
```powershell
New-Item -Path "C:\Program Files\Bootware" -Type Directory
$Env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Bootware"
[Environment]::SetEnvironmentVariable("Path", "$Env:Path", "Machine")
Invoke-WebRequest -Uri  https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.ps1 -o "C:\Program Files\Bootware\bootware"
```
</code-block>
</code-group>

## Usage

Bootware will bootstrap the computer software by invoking `bootware install`
after customizing the configuration file. To view the CLI help message, invoke
`bootware --help`.
