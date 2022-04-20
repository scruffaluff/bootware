# Changelog

This is the list of changes to Bootware between each release. For full details,
see the commit logs. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- All Ansible arguments to bootstrap subcommand.
- Croc, Datree, Duf, Helm, Helmfile, Htmlq, Kubectl, K9s, Lazydocker, Lazygit,
  Xh, and Yq roles.
- WSL tag for selecting roles.

### Changed

- Git pager to Delta.
- GitHub installation links.
- Split Bash subtasks into separate roles.

### Fixed

- Avoid unnecessary tasks for meta dependencies.
- Outdated Scoop package names.
- Update Starship installation command to match upstream change.
- VSCode settings file location for Scoop updates.
- Windows build tools versions.
- Windows Terminal settings file location for Microsoft Store installation.

### Removed

- Hyper terminal plugins that are broken on Windows.
- Libvirt support for Windows.
- OTS role.

## 0.3.5 - 2021-12-19

### Added

- Alpine support.
- Cuda and Nvidia Docker installations.
- Deno autocompletion support for Windows.
- Environment variable documenation.
- Flag --debug to set Ansible task debugger.
- Java, Julia, Parquet, Vagrant, Virtualbox, and Xsv roles.

### Changed

- Virtualization roles are no longer part of the server tag.

### Fixed

- Byte order marker for configuration files generated on Windows.
- USQL libicu depenency for Fedora.

## 0.3.4 - 2021-10-20

### Added

- Ability to choose Bootware branch for automatic WSL installation.
- Deno support for Apple ARM64.
- Beekeeper, Dust, Emacs, Etcher, FFSend, FzF, Hyperfine, Lua, Navi, OTS, Procs,
  RClone, Ruby and Scc, Zellij roles.
- GitHub CLI installation.
- History and menu autocompletion to PowerShell.
- Neosolarized and Packer installations for Neovim.
- Several PowerShell autocompletion modules.
- Software installation roles table in the documentation website.
- Support for more operating systems on Mongo Shell.
- Uninstall command.

### Changed

- Merged Bash, Bats, and Shfmt roles.
- Passwordless sudo setting for only current user.
- VSCode keybindings for switching between terminal tabs.
- Windows connections from WinRM to SSH.

### Fixed

- Commmand assertions to occur after argument parsing.

### Removed

- Desktop background picture automation.
- Xonsh role.

## 0.3.3 - 2021-08-06

### Added

- Avro, DBeaver, GitHub, GitLab, Glow, Hadolint, HDF5, Helm, Kubectl, SD, and
  Usql roles.
- Support for installing user defined Go applications.

### Changed

- Disabled pagination for Bat.
- Set EDITOR environment variable to Neovim.
- Switched to binary installer for FD.

### Fixed

- Removed unnecessary HTTP requests to formulae.brew.sh for MacOS.
- Reduced repeated roles with conditional depedencies.

### Removed

- Legacy Node and Python default versions.
- Postgres SQL clients.

## 0.3.2 - 2021-07-11

### Added

- Ansible check command line flag.
- Arm Linux support.
- Bass package manager for Fish.
- Digitial Ocean Bash and Fish completion.
- Fish completion script.
- Linux Snap and AppImage support.
- VSCode keybindings to change terminal tabs.
- VSCode YAML extension.

### Changed

- Default background image.
- Digital Ocean role name.
- Permissions to be more restrictive for user files.

### Fixed

- FD installation for Pop OS.
- GCloud Bash and Fish completion.
- Go root directory for MacOS.

### Removed

- Associated Docker images.
- VSCode bookmarks extension.

## 0.3.1 - 2021-04-26

### Added

- Cursor settings for MacOS.
- Direct WSL bootstrapping from PowerShell.
- Early XFCE desktop support.
- Error messaging for incorrect subcommands.
- Fuzz testing for Ansible roles.
- GCloud installation for Arch and Fedora distributions.
- Windows terminal settings.
- Yay AUR helper for Arch distributions.

### Changed

- Generates default configuration file instead of throwing an error if missing.

### Fixed

- Python and VSCode installations for Arch distributions.
- System path for Apple Silicon binaries.

## 0.3.0 - 2021-04-02

### Added

- Caffeine installation role.
- Chocolatey package support for Windows.
- Experimental bootstrapping via WinRM for remote Windows hosts.
- Experimental WSL boostrapping for Windows.
- GNOME desktop UI customizations.
- Pop Shell extension for all GNOME desktops.
- Separate Debian and Ubuntu testing.

### Changed

- Made setup depenency checking more flexible.
- Upgraded Ansible version for Debian distributions.
- Upgraded Docker installation version.

### Fixed

- Changelog notes for GitHub releases.
- Command line help for Windows.
- Debian base support for several packages.
- Generate of empty configuration files for Windows.
- Missing Pip system installation for Fedora.
- Passwordless sudo configuration for MacOS.
- Pipx package upgrades for updated Python interperter.
- Scoop bucket additions for Windows.

## 0.2.3 - 2021-03-15

### Added

- Changelog updates for GitHub releases.
- Commands in man page.

## 0.2.2 - 2021-03-12

### Fixed

- Debian packaging in GitHub releases.

## 0.2.1 - 2021-03-12

### Added

- Support for Apple M1 computers.

## 0.2.0 - 2021-02-10

### Added

- Several software installations for Fedora ibutions.

### Fixed

- Alacritty installation on Fedora distributions.
