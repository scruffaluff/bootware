# Changelog

This is the list of changes to Bootware between each release. For full details,
see the commit logs. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Chafa, Image Magick, Presenterm, and Samply roles.

### Changed

- Integrated terminal openers for Yazi.
- Moved FFmpeg to its own role.

### Removed

- Balena Etcher and Wasm roles.

## 0.9.1 = 2025-05-28

## Added

- Prettier role.

## 0.9.0 - 2025-05-17

### Added

- Automatic Windows connections without additional flags.
- Tags completion, config, install to tasks.
- Carapace, Fastfetch, Htop, Libre Office, Nushell, Obsidian, PNPM, Podman,
  Prune, SSH, and Uv roles.
- Support for Yazi 0.4.
- Variable to configure default user shell.

### Changed

- Naming conventions for public functions from script profiles.
- Node version manager back to NVM.
- Roles to prefer system packages over Flatpaks.
- VSCode role to VSCodium.
- Yazi theme.

### Fixed

- Fzf preview for Bash.
- GitLab runner installation.
- Helix move to end of word keybindings.
- PDB error handling.
- PowerShell profile aliases.
- Shell commands for Fzf.

### Removed

- Bats, Bun, Datree, Package, Update, and Utility roles.

## 0.8.3 - 2024-12-05

### Added

- Android Studio and Ignore role.
- More custom VSCode keybindings.
- Support for Dnf5.
- Yazi plugins.

### Changed

- Node role to depend on FNM instead of NVM.

### Fixed

- Browser Lite extension settings for VSCode.
- Custom commands for PDB.
- Fzf preview for MacOS.
- Helix runtime files on Linux.
- Installation of Fd shell completions.

### Removed

- Gcloud, Go, Packer, and Vault roles.
- PUDB configuration file.
- Shell keybindings for Ctrl+W.

## 0.8.2 - 2024-09-30

### Added

- Custom styling for VSCode.
- MuseScore role.
- Shell keybindings to insert current working directory.
- Shell keybindings to pipe to Fzf.

### Changed

- Glow to always use a pager.
- Scoop to prefer global installations.

### Fixed

- Helix end of line keybindings.

## 0.8.1 - 2024-06-21

### Added

- Android, Bitwig, Bun, GDB, LLDB, OBS, and Readline roles.
- Injection support for Pipx application installations.
- Tmux keybindings.
- Yazi change directory shell integration.

### Changed

- Improved Fzf search with Fd integration.

### Fixed

- Fish keybindings for PowerShell.
- GlazeWM workspaces for Windows.
- Several roles to be OpenWrt compatible.

### Removed

- Quickemu installation.
- Terragrunt role.

## 0.8.0 - 2024-03-11

### Added

- Arch and Alpine Linux packages.
- Audacity, Dive, Just, Kdenlive, Sonic Pi, Topgrade, VLC, Watchexec, and Zoxide
  roles.
- Balena Etcher support for all Linux distributions.
- Fira and PT fonts.
- Less keybindings customization.
- QEMU user emulation support for Linux.
- SSH port flag for scripts.
- Wget support in install scripts.
- VSCode panel keybindings.

### Changed

- Move shell completions to system folders.
- Simplified FFmpeg installation for Fedora.
- Simplified shell profiles.

### Fixed

- Extra newlines in unified clipboard aliases.
- Fira Code font integration in Lsd and Yazi.
- Login shell registration for Bash and Fish.

### Removed

- Appimage and Docker Compose roles.

## 0.7.3 - 2023-12-02

### Added

- Doas super command support.
- Tags flag for roles subcommand.

### Changed

- Renamed Sudo role to Super.
- Most unix shell scripts to be POSIX compatible.

## 0.7.2 - 2023-11-23

### Added

- Arm64 and FreeBSD support for several roles.
- Group install flag.
- Tools for Libvirt role.
- Yazi role.

### Fixed

- Group permissions for installed files.

### Removed

- Bashdb and Pocketbase roles.

## 0.7.1 - 2023-11-13

### Added

- Alacritty installation for Debian.

### Fixed

- Fish FZF integration for non-interactive shells.
- Roles subcommand.
- SD download URL for newer versions.

## 0.7.0 - 2023-10-22

### Added

- Flyctl, K3sup, Wezterm, and Velero roles.
- GlazeWM tiling window manager for Windows.
- Unified keybinding for tiling window managers.
- Utility role for miscellaneous system tools.

### Changed

- Exa role for Lsd role.
- Pop tiling window manager for Forge tiling window manager.
- Role names aws, deskenv, gcp, github, gitlab, mongo, and winman to awscli,
  desktop_environment, gcloud, github_runner, gitlab_runner, mongosh, and
  window_manager.
- Variable names cargo_applications, kubectl_plugins, pipx_applications, and
  passwordless_sudo to rust_applications, krew_plugins, python_applications, and
  sudo_passwordless respectively.

### Fixed

- Make Caffeine role version independent.
- Sops installation for new versions.
- Zellij autostart within a second user session.

### Removed

- Defterm, Hyper, and Navi roles.

## 0.6.2 - 2023-08-20

### Added

- Mdbook and Shellcheck support for Alpine.
- Miniserve and Pocketbase roles.
- User selection flags for installations.

### Changed

- User file permissions to be more restrictive.
- VSCode Python settings to match upstream updates.

### Removed

- Fish shell as a role dependency.

## 0.6.1 - 2023-07-28

### Changed

- Disabled Pocket in Firefox.

### Removed

- Avro, Direnv, Java, Neovim, and Parquet roles.

## 0.6.0 - 2023-07-17

### Added

- Firefox profile settings.

### Changed

- Extended integration for GitHub and GitLab runner roles.
- Repository layout to use a local Ansible collection.

## 0.5.3 - 2023-06-29

### Added

- Remote bootstrapping for Windows.
- Temporary SSH connection argument.

### Changed

- GitHub role to install GitHub runner.

### Removed

- Cuda, DVC, Obsidian, and Vagrant roles.

## 0.5.2 - 2023-06-16

### Fixed

- Collection level variables.

## 0.5.1 - 2023-06-09

### Added

- Fzf keybindings for Bash.
- Glibc patch for Helix on older systems.
- Improvements to shell completions.
- Minimal shell configuration option.
- Roles subcommand to view all available roles.
- Security role for basic security settings.
- Tag `sysadmin` for operations systems.

### Changed

- Default WSL distribution to Debian.
- Moved Neovim role to `extras` tag.
- Switched to GSudo on Windows.

### Fixed

- Exit code for bootstrap command in Windows.
- Installation of Procs shell completion.
- Integration of Google Cloud SDK GPG key.
- SSH key generation on newer PowerShell versions.
- Update logic for shell completions.

### Removed

- Some Windows File Explorer context menus.
- Virt Viewer from Libvirt role.

## 0.5.0 - 2023-01-30

### Added

- Debug flags for shell scripts.
- Flag to start execution at a role.
- GDU role.
- History deletion key bindings.
- Suse support for several roles.

### Changed

- Refactor architecture variables.
- Split system role into essential and update roles.
- TLDR role to use Tealdeer.

### Fixed

- Delta installation on Alpine.

### Removed

- Julia, Ruby, Snap, Virtualbox, Zola, and Zoxide roles.

## 0.4.1 - 2023-01-08

### Added

- GDB enhanced features installation.
- Kubeshark, Restic, Termshark, and Wireshark roles.
- PNPM shell integration.

### Changed

- Beekeeper from AppImage to Flatpak installation.
- Moved Libvirt, Vagrant and Vault roles to extras tag.
- Switched Lazygit role to GitUI.

### Fixed

- Go paths for CLI tools.
- Minimized GitHub API usage to avoid rate limits.
- PowerShell version 7 directory colors.
- Zellij integration for Alacritty during SSH sessions.

## 0.4.0 - 2022-07-13

### Added

- Kind, Helix, and Obsidian roles.
- SSH auto completion for Windows.
- Windows Defender Firewall rules.

## Changed

- Changed Beekeeper install from Snap to AppImage package.
- Default Unix editor to Helix.
- Improved Fzf shell integration.
- Moved Avro, Java, Julia, Parquet, Ruby and Virtualbox roles from default to
  extras list.

### Fixed

- Ansible collection installations are now shown to user.
- Automation for WSL installation.
- Node installation for FreeBSD.
- Mkcert dependencies for Linux.
- Sudoers roles for FreeBSD.
- Windows system path management for installations.

### Removed

- Desktop tag from Snap role.
- GistPad, LiveShare, and TabNine from default VSCode extensions.

## 0.3.6 - 2022-04-26

### Added

- All Ansible arguments to bootstrap subcommand.
- Age, Croc, Datree, Direnv, Duf, Helm, Helmfile, Htmlq, Kubectl, K9s,
  Lazydocker, Lazygit, Sops, Xh, Yq, and Zoxide roles.
- WSL tag for selecting roles.

### Changed

- Git pager to Delta.
- GitHub installation links.
- Ruby role to use standard installer instead of RVM.
- Split Bash subtasks into separate roles.
- Split Docker Compose installation separate role.

### Fixed

- Avoid unnecessary tasks for meta dependencies.
- Outdated Scoop package names.
- Update Starship installation command to match upstream change.
- VSCode settings file location for Scoop updates.
- Windows build tools versions.
- Windows Terminal settings file location for Microsoft Store installation.

### Removed

- Emacs and OTS role.
- Hyper terminal plugins that are broken on Windows.
- Libvirt support for Windows.
- Support for multiple Ruby versions.

## 0.3.5 - 2021-12-19

### Added

- Alpine support.
- Cuda and Nvidia Docker installations.
- Deno autocompletion support for Windows.
- Environment variable documentation.
- Flag --debug to set Ansible task debugger.
- Java, Julia, Parquet, Vagrant, Virtualbox, and Xsv roles.

### Changed

- Virtualization roles are no longer part of the server tag.

### Fixed

- Byte order marker for configuration files generated on Windows.
- USQL libicu dependency for Fedora.

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

- Command assertions to occur after argument parsing.

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
- Switched to binary installer for Fd.

### Fixed

- Removed unnecessary HTTP requests to formulae.brew.sh for MacOS.
- Reduced repeated roles with conditional dependencies.

### Removed

- Legacy Node and Python default versions.
- Postgres SQL clients.

## 0.3.2 - 2021-07-11

### Added

- Ansible check command line flag.
- Arm Linux support.
- Bass package manager for Fish.
- Digital Ocean Bash and Fish completion.
- Fish completion script.
- Linux Snap and AppImage support.
- VSCode keybindings to change terminal tabs.
- VSCode YAML extension.

### Changed

- Default background image.
- Digital Ocean role name.
- Permissions to be more restrictive for user files.

### Fixed

- Fd installation for Pop OS.
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
- GCloud installation for Arch and Fedora.
- Windows terminal settings.
- Yay AUR helper for Arch.

### Changed

- Generates default configuration file instead of throwing an error if missing.

### Fixed

- Python and VSCode installations for Arch.
- System path for Apple Silicon binaries.

## 0.3.0 - 2021-04-02

### Added

- Caffeine installation role.
- Chocolatey package support for Windows.
- Experimental bootstrapping via WinRM for remote Windows hosts.
- Experimental WSL bootstrapping for Windows.
- GNOME desktop UI customizations.
- Pop Shell extension for all GNOME desktops.
- Separate Debian and Ubuntu testing.

### Changed

- Made setup dependency checking more flexible.
- Upgraded Ansible version for Debian.
- Upgraded Docker installation version.

### Fixed

- Changelog notes for GitHub releases.
- Command line help for Windows.
- Debian base support for several packages.
- Generate of empty configuration files for Windows.
- Missing Pip system installation for Fedora.
- Passwordless sudo configuration for MacOS.
- Pipx package upgrades for updated Python interpreter.
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

- Several software installations for Fedora distributions.

### Fixed

- Alacritty installation on Fedora.
