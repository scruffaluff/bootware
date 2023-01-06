# Bash settings file for non-login shells.
# shellcheck disable=SC1090,SC1091 shell=bash
#
# For more information, visit
# https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html.

# Prepend directory to the system path if it exists and is not already there.
#
# Flags:
#   -d: Check if inode is a directory.
prepend_path() {
  if [[ -d "$1" && ":${PATH}:" != *":$1:"* ]]; then
    export PATH="$1:${PATH}"
  fi
}

# System settings.

# Ensure that /usr/bin appears before /usr/sbin in PATH environment variable.
#
# Pyenv system shell won't work unless it is found in a bin directory. Archlinux
# places a symlink in an sbin directory. For more information, see
# https://github.com/pyenv/pyenv/issues/1301#issuecomment-582858696.
prepend_path '/usr/bin'

# Add manually installed binary directory to PATH environment variable.
#
# Necessary since path is missing on some MacOS systems.
prepend_path '/usr/local/bin'

# Bash settings

# Load Bash completion if it exists.
#
# Bash completion file is not executable but can be sourced.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if [[ -f '/etc/bash_completion' ]]; then
  source '/etc/bash_completion'
elif [[ -f '/opt/homebrew/etc/bash_completion' ]]; then
  source '/opt/homebrew/etc/bash_completion'
fi

# Docker settings.
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

# Fzf settings.

# Set Fzf solarized light theme.
_fzf_colors='--color fg:-1,bg:-1,hl:33,fg+:235,bg+:254,hl+:33'
_fzf_highlights='--color info:136,prompt:136,pointer:230,marker:230,spinner:136'
export FZF_DEFAULT_OPTS="--reverse ${_fzf_colors} ${_fzf_highlights}"

# Go settings.

# Find and export Go root directory.
#
# On Alpine Linux, there does not appear to exist a GOROOT directory.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernel name.
if [[ "$(uname -s)" == 'Darwin' ]]; then
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  ARM_GOROOT='/opt/homebrew/opt/go/libexec'
  INTEL_GOROOT='/usr/local/opt/go/libexec'

  if [[ -d "${ARM_GOROOT}" ]]; then
    export GOROOT="${ARM_GOROOT}"
    prepend_path "${GOROOT}/bin"
  elif [[ -d "${INTEL_GOROOT}" ]]; then
    export GOROOT="${INTEL_GOROOT}"
    prepend_path "${GOROOT}/bin"
  fi
else
  if [[ -d '/usr/local/go' ]]; then
    export GOROOT='/usr/local/go'
    prepend_path "${GOROOT}/bin"
  fi
fi

# Add Go local binaries to system path.
export GOPATH="${HOME}/.go"
prepend_path "${GOPATH}/bin"

# Java settings.

# Find and add Java OpenJDK directory to path.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernel name.
if [[ "$(uname -s)" == 'Darwin' ]]; then
  if [[ -d '/opt/homebrew/opt/openjdk/bin' ]]; then
    prepend_path '/opt/homebrew/opt/openjdk/bin'
  elif [[ -d '/usr/local/opt/openjdk/bin' ]]; then
    prepend_path '/usr/local/opt/openjdk/bin'
  fi
fi

# Julia settings.

prepend_path '/usr/local/julia/bin'

# Python settings.

# Make Poetry create virutal environments inside projects.
export POETRY_VIRTUALENVS_IN_PROJECT='true'

# Make numerical compute libraries findable on MacOS.
#
# Flags:
#   -d: Check if inode is a directory.
#   -s: Print machine kernel name.
if [[ "$(uname -s)" == 'Darwin' ]]; then
  if [[ -d '/opt/homebrew/opt/openblas' ]]; then
    export OPENBLAS='/opt/homebrew/opt/openblas'
  elif [[ -d '/usr/local/opt/openblas' ]]; then
    export OPENBLAS='/usr/local/opt/openblas'
  fi
fi

# Add Pyenv binaries to system path.
prepend_path "${HOME}/.pyenv/bin"

# Initialize Pyenv if available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v pyenv)" ]]; then
  export PYENV_ROOT="${HOME}/.pyenv"
  prepend_path "${PYENV_ROOT}/bin"
  eval "$(pyenv init --path)"

  # Load Pyenv completions.
  source "$(pyenv root)/completions/pyenv.bash"
fi

# Ruby settings.
prepend_path "${HOME}/bin"

# Add gems binaries to path if Ruby is available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v ruby)" ]]; then
  prepend_path "$(ruby -r rubygems -e 'puts Gem.user_dir')/bin"
fi

# Rust settings.
prepend_path "${HOME}/.cargo/bin"

# Shell settings.

# Custom environment variable function to faciliate Fish shell compatibility.
#
# Taken from https://unix.stackexchange.com/a/176331.
#
# Examples:
#   setenv PATH "usr/local/bin"
function setenv() {
  export "$1=$2"
}

# Load aliases if file exists.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if [[ -f "${HOME}/.aliases" ]]; then
  source "${HOME}/.aliases"
fi

# Load environment variables if file exists.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if [[ -f "${HOME}/.env" ]]; then
  source "${HOME}/.env"
fi

# Load secrets if file exists.
#
# Flags:
#   -f: Check if file exists and is a regular file.
if [[ -f "${HOME}/.secrets" ]]; then
  source "${HOME}/.secrets"
fi

# Starship settings.

# Initialize Starship if available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v starship)" ]]; then
  eval "$(starship init bash)"
fi

# Tool settings.

export BAT_THEME='Solarized (light)'
complete -C '/usr/local/bin/terraform' terraform


# Add Visual Studio Code binary to PATH for Linux.
prepend_path '/usr/share/code/bin'

# Initialize Digital Ocean CLI if available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v doctl)" ]]; then
  source <(doctl completion bash)
fi

# Initialize Direnv if available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v direnv)" ]]; then
  eval "$(direnv hook bash)"
fi

# Initialize GCloud if on MacOS and available.
#
# Flags:
#   -f: Check if file exists and is a regular file.
#   -s: Print machine kernel name.
if [[ "$(uname -s)" == 'Darwin' ]]; then
  # (brew --prefix) gives the incorrect path when sourced on Apple silicon.
  ARM_GCLOUD_PATH='/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk'
  INTEL_GCLOUD_PATH='/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk'

  if [[ -f "${ARM_GCLOUD_PATH}/path.bash.inc" ]]; then
    source "${ARM_GCLOUD_PATH}/path.bash.inc"
    source "${ARM_GCLOUD_PATH}/completion.bash.inc"
  elif [[ -f "${INTEL_GCLOUD_PATH}/path.bash.inc" ]]; then
    source "${INTEL_GCLOUD_PATH}/path.bash.inc"
    source "${INTEL_GCLOUD_PATH}/completion.bash.inc"
  fi
elif [[ "$(uname -s)" == 'Linux' ]]; then
  GCLOUD_BASH_COMPLETION='/usr/lib/google-cloud-sdk/completion.bash.inc'

  if [[ -f "${GCLOUD_BASH_COMPLETION}" ]]; then
    source "${GCLOUD_BASH_COMPLETION}"
  fi
fi

# Add Kubectl plugins to PATH.
prepend_path "${HOME}/.krew/bin"

# Initialize Kubernetes CLI if available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v kubectl)" ]]; then
  source <(kubectl completion bash)
fi

# Add Navi widget if available and line editing is enabled.
#
# The Navi widget requires line editing and will otherwise cause the warning:
#     bind: warning: line editing not enabled. 
# One can start a no line editing shell with the command: bash --noediting.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v navi)" && "${SHELLOPTS}" =~ (vi|emacs) ]]; then
  eval "$(navi widget bash)"
fi

# Initialize Zoxide if available.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v zoxide)" ]]; then
  eval "$(zoxide init bash)"
fi

# TypeScript settings.

# Add Deno binaries to system path.
export DENO_INSTALL="${HOME}/.deno"
prepend_path "${DENO_INSTALL}/bin"

# Add NPM global binaries to system path.
prepend_path "${HOME}/.npm-global/bin"

# Source TabTab shell completion for PNPM.
if [[ -f "${HOME}/.config/tabtab/bash/__tabtab.bash" ]]; then
  source "${HOME}/.config/tabtab/bash/__tabtab.bash"
fi

# Load Node version manager and its bash completion.
#
# Flags:
#   -f: Check if file exists and is a regular file.
export NVM_DIR="${HOME}/.nvm"
if [[ -f "${NVM_DIR}/nvm.sh" ]]; then
  source "${NVM_DIR}/nvm.sh"
fi
if [[ -f "${NVM_DIR}/bash_completion" ]]; then
  source "${NVM_DIR}/bash_completion"
fi

# User settings.

# Disable MacOS default shell is now Zsh message.
export BASH_SILENCE_DEPRECATION_WARNING=1

# Helix settings.
#
# Flags:
#   -x: Check if file exists and execute permission is granted.
if [[ -x "$(command -v hx)" ]]; then
  # Assume that terminal session has full color support for convenience.
  export COLORTERM='truecolor'
  # Set default editor to Helix if available.
  export EDITOR='hx'
fi

# Add scripts directory to PATH environment variable.
prepend_path "${HOME}/.local/bin"

# Wasmtime settings.
export WASMTIME_HOME="${HOME}/.wasmtime"

prepend_path "${WASMTIME_HOME}/bin"

# Apple Silicon support.

# Ensure Homebrew Arm64 binaries are found before x86_64 binaries.
prepend_path '/opt/homebrew/bin'
