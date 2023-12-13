# Bash settings file for non-login shells.
# shellcheck disable=SC1090,SC1091 shell=bash
#
# For more information, visit
# https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html.

# Convenience variables.
#
# Do not use long form flags for uname. They are not supported on MacOS. Command
# "(brew --prefix)" will give the incorrect path when sourced on Apple silicon
# and running under an Rosetta 2 emulated terminal.
#
# Flags:
#   -d: Check if path is a directory.
#   -s: Show operating system kernel name.
if [[ -d '/opt/homebrew' ]]; then
  _brew_prefix='/opt/homebrew'
else
  _brew_prefix='/usr/local'
fi
_os="$(uname -s)"
_tty="$([[ "$-" =~ 'i' ]] && echo 'true' || echo '')"

# Prepend existing directories that are not in the system path.
#
# Flags:
#   -d: Check if path is a directory.
prepend_paths() {
  local inode
  for inode in "$@"; do
    # Variable in regex is quoted to perform an exact substring match.
    # shellcheck disable=SC2076
    if [[ -d "${inode}" && ! "${PATH}" =~ ":${inode}:" ]]; then
      export PATH="${inode}:${PATH}"
    fi
  done
}

# Source shell files if they exist.
#
# Flags:
#   -f: Check if file exists and is a regular file.
source_files() {
  local inode
  for inode in "$@"; do
    if [[ -f "${inode}" ]]; then
      source "${inode}"
    fi
  done
}

# Shell settings.

# Disable MacOS default shell is now Zsh message. Value must be 1.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Add directories to system path that are not always included.
#
# Homebrew ARM directories should appear in system path before AMD directories
# since some ARM systems might have slower emulated AMD copies of programs.
prepend_paths '/usr/local/bin' '/opt/homebrew/bin' '/opt/homebrew/sbin' \
  "${HOME}/.local/bin"

# Configure keybindings and completions for interactive shells.
#
# Flags:
#   -n: Check if the string has nonzero length.
if [[ -n "${_tty}" ]]; then
  # Configure up and down arrow key history search to match commands starting
  # with text before the cursor.
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
  # Configure tab key to cycle through all possible completions.
  bind 'TAB:menu-complete'

  # Load Bash completion.
  if [[ "${_os}" == 'Darwin' ]]; then
    source_files "${_brew_prefix}/etc/profile.d/bash_completion.sh"
  elif [[ "${_os}" == 'FreeBSD' ]]; then
    source_files '/usr/local/share/bash-completion/bash_completion'
  else
    source_files '/usr/share/bash-completion/bash_completion'
  fi
fi

# Add unified clipboard aliases.
#
# Command cbcopy is defined as a function instead of an alias to add logic for
# removing the final newline from text during clipboard copies.
#
# Flags:
#   -v: Only show file path of command.
#   -x: Check if file exists and execute permission is granted.
if [[ "${_os}" == 'Darwin' ]]; then
  cbcopy() {
    echo -n "$(cat)" | pbcopy
  }
  alias cbpaste='pbpaste'
elif [[ -x "$(command -v wl-copy)" ]]; then
  cbcopy() {
    echo -n "$(cat)" | wl-copy
  }
  alias cbpaste='wl-paste'
fi

# Docker settings.

# Ensure newer Docker features are enabled.
export COMPOSE_DOCKER_CLI_BUILD='true' DOCKER_BUILDKIT='true'

# Fzf settings.

# Set Fzf solarized light theme.
_fzf_colors='--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
_fzf_highlights='--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
export FZF_DEFAULT_OPTS="--reverse ${_fzf_colors} ${_fzf_highlights}"

# Load Fzf keybindings if available.
#
# Flags:
#   -n: Check if the string has nonzero length.
#   -v: Only show file path of command.
#   -x: Check if file exists and execute permission is granted.
if [[ -n "${_tty}" && -x "$(command -v fzf)" ]]; then
  source_files "${HOME}/.fzf_key_bindings.bash"
fi

# Go settings.

# Export Go root directory to system path if available.
#
# Flags:
#   -d: Check if path is a directory.
if [[ -d "${_brew_prefix}/opt/go/libexec" ]]; then
  export GOROOT="${_brew_prefix}/opt/go/libexec"
  prepend_paths "${GOROOT}/bin"
elif [[ -d '/usr/local/go' ]]; then
  export GOROOT='/usr/local/go'
  prepend_paths "${GOROOT}/bin"
fi

# Set path for Go local binaries.
export GOPATH="${HOME}/.go"
prepend_paths "${GOPATH}/bin"

# Helix settings.

# Set full color support for terminal and default editor to Helix.
#
# Flags:
#   -v: Only show file path of command.
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v hx)" ]]; then
  export COLORTERM='truecolor' EDITOR='hx'
fi

# Just settings.

# Add alias for account wide Just recipes.
# shellcheck disable=SC2139
alias jt="just --justfile ${HOME}/.justfile --working-directory ."

# Kubernetes settings.

# Add Kubectl plugins to system path.
prepend_paths "${HOME}/.krew/bin"

# Python settings.

# Fix Poetry package install issue on headless systems.
export PYTHON_KEYRING_BACKEND='keyring.backends.fail.Keyring'
# Make Poetry create virutal environments inside projects.
export POETRY_VIRTUALENVS_IN_PROJECT='true'

# Make numerical compute libraries findable for MacOS.
if [[ "${_os}" == 'Darwin' ]]; then
  export OPENBLAS="${_brew_prefix}/opt/openblas"
  prepend_paths "${OPENBLAS}"
fi

# Add Pyenv binaries to system path.
export PYENV_ROOT="${HOME}/.pyenv"
prepend_paths "${PYENV_ROOT}/bin" "${PYENV_ROOT}/shims"

# Initialize Pyenv if available.
#
# Flags:
#   -n: Check if the string has nonzero length.
#   -v: Only show file path of command.
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v pyenv)" ]]; then
  eval "$(pyenv init -)"
  if [[ -n "${_tty}" ]]; then
    source "$(pyenv root)/completions/pyenv.bash"
  fi
fi

# Rust settings.

# Add Rust binaries to system path.
prepend_paths "${HOME}/.cargo/bin"

# Starship settings.

# Disable Starship warnings about command timeouts.
export STARSHIP_LOG='error'

# Initialize Starship if available.
#
# Flags:
#   -n: Check if the string has nonzero length.
#   -v: Only show file path of command.
#   -x: Check if file exists and execute permission is granted.
if [[ -n "${_tty}" && -x "$(command -v starship)" ]]; then
  eval "$(starship init bash)"
fi

# TypeScript settings.

# Add Deno binaries to system path.
export DENO_INSTALL="${HOME}/.deno"
prepend_paths "${DENO_INSTALL}/bin"

# Add NPM global binaries to system path.
prepend_paths "${HOME}/.npm-global/bin"

# Load Node version manager and its bash completion.
#
# Flags:
#   -n: Check if the string has nonzero length.
export NVM_DIR="${HOME}/.nvm"
source_files "${NVM_DIR}/nvm.sh"
if [[ -n "${_tty}" ]]; then
  source_files "${NVM_DIR}/bash_completion"
fi

# Visual Studio Code settings.

# Add Visual Studio Code binaries to system path for Linux.
prepend_paths '/usr/share/code/bin'

# Wasmtime settings.

# Add Wasmtime binaries to system path.
export WASMTIME_HOME="${HOME}/.wasmtime"
prepend_paths "${WASMTIME_HOME}/bin"

# User settings.

# Load user aliases, secrets, and variables.
source_files "${HOME}/.env" "${HOME}/.secrets" "${HOME}/.env.bash" \
  "${HOME}/.secrets.bash"
