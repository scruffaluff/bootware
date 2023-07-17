FROM archlinux:base-20230611.0.157136

ARG TARGETARCH

# Create non-priviledged user.
RUN useradd --create-home --no-log-init --shell /bin/bash arch

# Install Bash, Curl, and Sudo.
RUN pacman --noconfirm --refresh --sync --sysupgrade && \
    pacman --noconfirm --sync bash curl sudo

# Create sudo group.
RUN groupadd sudo

# Add standard user to sudoers group.
RUN usermod --append --groups sudo arch

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
COPY --chown="${USER}" ansible_collections/ ./ansible_collections/
COPY --chown="${USER}" ansible.cfg playbook.yaml ./

ARG skip
ARG tags
ARG test

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

# Run Bootware bootstrapping.
RUN bootware bootstrap --dev --no-passwd \
    --retries 3 ${skip:+--skip $skip} --tags ${tags:-desktop,extras}

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
            sudo pacman --noconfirm --sync unzip; \
            curl -LSfs https://deno.land/install.sh | sh; \
            export PATH="${HOME}/.deno/bin:${PATH}"; \
        fi; \
        ./tests/integration/roles_test.ts --arch "${TARGETARCH}" ${skip:+--skip $skip} ${tags:+--tags $tags} "arch"; \
    fi
