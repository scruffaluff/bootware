# Bootware

![](https://img.shields.io/github/repo-size/scruffaluff/bootware)
![](https://img.shields.io/github/license/scruffaluff/bootware)

---

**Documentation**: https://scruffaluff.github.io/bootware

**Source Code**: https://github.com/scruffaluff/bootware

---

Bootware is a set of shell scripts for bootstrapping software installations with
Ansible. Bootware makes it easy to install software, settings, and configuration
files for a new computer by providing uniform commands to install Ansible and
execute playbooks for the local computer. Bootware requires no dependencies and
works on FreeBSD, Linux, MacOS, and Windows operating systems.

Bootware is designed for my personal usage, but can be configured for anyone to
use. All the Bootware default settings point to this repository, but most
settings can be changed with environment variables, a configuration file, or
command line flags. If you want your own version of Bootware with different
defaults, just fork this repository and edit away.

## Install

For instructions on installing Bootware for your operating system, see the
[Installation](https://scruffaluff.github.io/bootware/install) section of the
documentation.

## Usage

Bootware will bootstrap the computer software by invoking `bootware bootstrap`
after customizing the optional configuration file. To view the bootstrapping
options, execute `bootware bootstrap --help`.

To only install Ansible on the system, execute `bootware setup`.

Since Ansible cannot be installed on Windows, Bootware will install OpenSSH
server and the Windows Subsystem for Linux. Bootware will automatically execute
all software bootstrapping from the Linux subsystem and provision the Windows
configurations via an SSH connection.

## Software

Bootware uses a collection of Ansible roles to install and manage a wide variety
of software. For a complete list of the available roles see the
[Software](https://scruffaluff.github.io/bootware/software) section of the
documentation.

## Contribute

For guidance on setting up a development environment and how to make a
contribution, see the
[Contributing Guide](https://github.com/scruffaluff/bootware/blob/main/CONTRIBUTING.md).

## License

Bootware is distributed under a
[MIT license](https://github.com/scruffaluff/bootware/blob/main/LICENSE.md).
