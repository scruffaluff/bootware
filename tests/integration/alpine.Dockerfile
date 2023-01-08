FROM alpine:3.16

ARG TARGETARCH

# Create non-priviledged user.
#
# Alpine does contain the useradd command.
#
# Flags:
#     -D: Do not assign the user a password.
#     -s /usr/bin/sh: Set user login shell to Sh.
#     -u 1000: Give new user UID value 1000.
RUN adduser --disabled-password -s /bin/sh -u 1000 alpine

# Install Bash, Curl, and Sudo.
RUN apk update && apk add bash curl sudo

# Add standard user to sudoers group.
RUN addgroup alpine wheel

# Allow sudo commands with no password.
RUN printf "%%wheel ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# Fix current sudo bug for containers.
# https://github.com/sudo-project/sudo/issues/42
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

ENV HOME=/home/alpine USER=alpine
USER alpine

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
COPY --chown="${USER}" playbook.yaml ./

ARG skip
ARG tags
ARG test

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

# Run Bootware bootstrapping.
RUN bootware bootstrap --dev --no-passwd ${skip:+--skip $skip} --tags ${tags:-desktop,extras}

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
        if [[ ! -x "$(command -v node)" ]]; then \
            sudo apk add nodejs; \
        fi; \
        node tests/integration/roles.spec.js --arch "${TARGETARCH}" ${skip:+--skip $skip} ${tags:+--tags $tags} "alpine"; \
    fi
