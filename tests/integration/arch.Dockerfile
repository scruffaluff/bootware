FROM archlinux:base-20220417.0.53367

ARG TARGETARCH

# Create non-priviledged user.
#
# Flags:
#     -l: Do not add user to lastlog database.
#     -m: Create user home directory if it does not exist.
#     -s /usr/bin/fish: Set user login shell to Fish.
#     -u 1000: Give new user UID value 1000.
RUN useradd -lm -s /bin/bash -u 1000 arch

# Install Bash, Curl, and Sudo.
RUN pacman --noconfirm -Suy && pacman --noconfirm -S bash curl sudo

# Create sudo group.
RUN groupadd sudo

# Add standard user to sudoers group.
RUN usermod -a -G sudo arch

# Allow sudo commands with no password.
RUN printf "%%sudo ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# Fix current sudo bug for containers.
# https://github.com/sudo-project/sudo/issues/42
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

ENV HOME=/home/arch USER=arch
USER arch

# Install Bootware.
COPY bootware.sh /usr/local/bin/bootware

# Install dependencies for Bootware.
RUN bootware setup

# Create bootware project directory.
RUN mkdir $HOME/bootware
WORKDIR $HOME/bootware

# Copy bootware project files.
COPY --chown="${USER}" roles/ ./roles/
COPY --chown="${USER}" group_vars/ ./group_vars/
COPY --chown="${USER}" main.yaml ./

ARG skip
ARG tags
ARG test

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

# Run Bootware bootstrapping.
RUN bootware bootstrap --dev --no-passwd ${skip:+--skip $skip} ${tags:+--tags $tags}

# Copy bootware test files for testing.
COPY --chown="${USER}" tests/ ./tests/

# Set Bash as default shell.
SHELL ["/bin/bash", "-c"]

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if the string has nonzero length.
RUN if [[ -n "$test" ]]; then \
        source "${HOME}/.bashrc"; \
        if [[ ! -x "$(command -v deno)" ]]; then \
            sudo pacman -S --noconfirm unzip; \
            curl -LSfs https://deno.land/install.sh | sh; \
            export PATH="${HOME}/.deno/bin:${PATH}"; \
        fi; \
        ./tests/integration/roles_test.ts --arch "${TARGETARCH}" ${skip:+--skip $skip} ${tags:+--tags $tags} "arch"; \
    fi
