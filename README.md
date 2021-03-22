# Bootware

![](https://img.shields.io/github/repo-size/wolfgangwazzlestrauss/canvas)
![](https://img.shields.io/github/license/wolfgangwazzlestrauss/canvas)

---

<!-- prettier-ignore -->
**Documentation**: https://wolfgangwazzlestrauss.github.io/bootware

**Source Code**: https://github.com/wolfgangwazzlestrauss/bootware

---

Bootware is a set of shell scripts and Docker images for bootstrapping software
installations with Ansible.

## Install

Bootware is invoked by shell scripts on the user's computer. The following
commands will download the shell scripts and add them to the system path.

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

On Windows, PowerShell will need to run as administrator and the security policy
must allow for running remote PowerShell scripts. The following command will
update the security policy, if needed.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

## Usage

Bootware will bootstrap the computer software by invoking `bootware bootstrap`
after customizing the configuration file. To view the bootstrapping options,
execute `bootware bootstrap --help`.

## Contributing

For guidance on setting up a development environment and how to make a
contribution, see the
[Contributing](https://wolfgangwazzlestrauss.github.io/bootware/contrib) section
of the documentation.

## License

Bootware is distributed under the MIT license.
