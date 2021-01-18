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

## Usage

Bootware will bootstrap the computer software by invoking `bootware install`
after customizing the configuration file. To view the CLI help message, invoke
`bootware --help`.
