FROM fedora:41

ARG TARGETARCH

# Install Curl and Sudo.  
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }
RUN dnf install --assumeyes curl sudo

# Create non-priviledged user and grant user passwordless sudo.
#
# Disabling TTY requirement is necessary for CI workflows.
RUN useradd --create-home --no-log-init fedora \
    && groupadd sudo \
    && usermod --append --groups sudo fedora \
    && printf "fedora ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers \
    && printf "Defaults !requiretty\n" >> /etc/sudoers

ENV HOME=/home/fedora USER=fedora
USER fedora

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

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

ARG skip
ARG tags

# Run Bootware bootstrapping.
RUN bootware bootstrap --dev --no-passwd \
    --retries 3 ${skip:+--skip $skip} --tags ${tags:-desktop,extras}

# Copy bootware test files for testing.
COPY --chown="${USER}" tests/ ./tests/

# Ensure Bash and Node are installed.
RUN command -v bash > /dev/null \
    || sudo dnf install --assumeyes bash \
    && command -v node > /dev/null \
    || sudo dnf install --assumeyes nodejs

# Set Bash as default shell.
SHELL ["/bin/bash", "-c"]

ARG test

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if string is nonempty.
RUN if [[ -n "${test}" ]]; then \
    source "${HOME}/.bashrc"; \
    node tests/integration/roles.test.cjs --arch "${TARGETARCH}" ${skip:+--skip $skip} ${tags:+--tags $tags} "fedora"; \
    fi
