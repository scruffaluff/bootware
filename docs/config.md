# Configuration

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
