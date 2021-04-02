# Changelog

This is the list of changes to Bootware between each release. For full details,
see the commit logs. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## Changed

- Generates default configuration file instead of throwing an error if missing.

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
- Upgraded Ansible version for Debian distrobutions.
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

- Several software installations for Fedora distrobutions.

### Fixed

- Alacritty installation on Fedora distrobutions.
