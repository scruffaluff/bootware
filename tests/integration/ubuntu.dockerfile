FROM ubuntu:23.10

ARG TARGETARCH

# Install Curl and Sudo.
RUN apt-get update --ignore-missing && apt-get install --quiet --yes curl sudo

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" apt-get --quiet --yes install tzdata

# Grant ubuntu user passwordless sudo.
RUN usermod --append --groups sudo ubuntu \
    && printf "ubuntu ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# Ubuntu container comes with a builtin Ubuntu user.
ENV HOME=/home/ubuntu USER=ubuntu
USER ubuntu

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

# Ensure Bash and Node are installed.
RUN command -v bash > /dev/null \
    || sudo apt-get install --quiet --yes bash \
    && command -v node > /dev/null \
    || sudo apt-get install --quiet --yes nodejs

# Set Bash as default shell.
SHELL ["/bin/bash", "-c"]

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if the string has nonzero length.
RUN if [[ -n "${test}" ]]; then \
    source "${HOME}/.bashrc"; \
    node tests/integration/roles.spec.js --arch "${TARGETARCH}" ${skip:+--skip $skip} ${tags:+--tags $tags} "ubuntu"; \
    fi
