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

## Configuration File

Bootware uses a configuration file for customizing the software bootstrapping.
Bootware uses the first available following option for a configuration file
path.

- \<path> (argument to -c/--config command line flag)
- bootware.yaml (in the current directory)
- EUCLID_CONFIG (environment variable)
- ~/bootware.yaml (in the home directory)

The following commands will download the example configuration file to the user
home directory. The file should be manually edited for the user's computer.

Linux / MacOS:

```bash
curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml -o $HOME/bootware.yaml
```

Windows:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/host_vars/bootware.yaml -OutFile $HOME/bootware.yaml
```

## Optional Steps

It is recommended but optional to install the `caffeinate` command to help
prevent the computer from going to sleep during bootstrapping. The following
commands install `caffeinate`.

Linux:

```bash
sudo apt-get update && sudo apt-get install -y caffeine
```

MacOS: Pre-installed.

Windows: To be determined.

## Scripts

Bootware is invoked by shell scripts on the user's computer. The following
commands will download the shell scripts and add them to the system path.

Linux:

```bash
sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh -o /usr/local/bin/bootware
sudo chmod 755 /usr/local/bin/bootware
```

MacOS:

```bash
sudo mkdir -p /usr/local/bin/
sudo curl -LSfs https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.sh -o /usr/local/bin/bootware
sudo chmod 755 /usr/local/bin/bootware
echo 'export PATH="$PATH:/usr/local/bin"' >> "$HOME/.profile"
export PATH="$PATH:/usr/local/bin"
```

One needs to additionally enable remote login in `System Preferences > Sharing`.

Windows: (Run as Administrator)

```bash
New-Item -Path "C:\Program Files\Bootware" -Type Directory
$Env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Bootware"
[Environment]::SetEnvironmentVariable("Path", "$Env:Path", "Machine")
Invoke-WebRequest -Uri  https://raw.githubusercontent.com/wolfgangwazzlestrauss/bootware/master/bootware.ps1 -o "C:\Program Files\Bootware\bootware"
```

## Usage

Bootware will bootstrap the computer software by invoking `bootware` after
customizing the configuration file. To view the CLI help message, invoke
`bootware --help`.
