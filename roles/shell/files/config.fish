# Fish settings file.


# Aliases.

# Load aliases if file exists.
#
# Flags:
#     -f: Check if inode is a regular file.
if test -f "$HOME/.aliases"
    source "$HOME/.aliases"
end


# User settings.

# Add scripts directory to system path.
set -x PATH "$HOME/.local/bin:$PATH"


# Fish settings.

# Disable welcome message.
set fish_greeting


# Go settings.
# set -x GOPATH "/usr/local/go"
# set -x PATH "$GOPATH/bin:$PATH"


# Python settings.

# Make Poetry create virutal environments inside projects.
set -x POETRY_VIRTUALENVS_IN_PROJECT 1

# Add Pyenv binaries to system path.
set -x PATH "$HOME/.pyenv/bin:$PATH"

# Initialize Pyenv if available.
#
# Flags:
#     -q: Only check for exit status by supressing output.
if type -q pyenv
    pyenv init - | source
    pyenv virtualenv-init - | source
end


# Rust settings.
set -x PATH "$HOME/.cargo/bin:$PATH"


# Starship settings.

# Initialize Starship if available.
#
# Flags:
#     -q: Only check for exit status by supressing output.
if type -q starship
    starship init fish | source
end


# Tool settings.
set -x BAT_THEME "Solarized (light)"

# Initialize Zoxide if available.
#
# Flags:
#     -q: Only check for exit status by supressing output.
if type -q zoxide
    zoxide init fish | source
end


# TypeScript settings.

# Add NPM global binaries to system path.
set -x PATH "$HOME/.npm-global/bin:$PATH"

# Initialize NVM default version of Node if available.
#
# Flags:
#     -q: Only check for exit status by supressing output.
if type -q nvm
    nvm use default
end

# Deno settings.
# set -x DENO_INSTALL "/usr/local/deno"
# set -x PATH "$DENO_INSTALL/bin:$PATH"


# Wasmtime settings.
# set -x WASMTIME_HOME "/usr/local/wasmtime"
# set -x PATH "$WASMTIME_HOME/bin:$PATH"
