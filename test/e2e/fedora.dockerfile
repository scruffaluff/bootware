FROM docker.io/fedora:42

ARG TARGETARCH

# Install Curl and Sudo.  
RUN dnf makecache && dnf install --assumeyes curl sudo

# Install SQLite to avoid Node symbol lookup errors when building image inside
# some virtual machines.
RUN dnf install --assumeyes sqlite

# Create non-priviledged user and grant user passwordless sudo.
#
# Changing permissions on "/etc/shadow" avoids PAM authentication errors when
# building image inside some virtual machines.
RUN useradd --create-home --no-log-init fedora \
    && groupadd sudo \
    && usermod --append --groups sudo fedora \
    && printf "fedora ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers \
    && chmod 640 /etc/shadow

ENV HOME=/home/fedora USER=fedora
USER fedora

# Install Bootware.
COPY src/bootware.sh /usr/local/bin/bootware

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
    --retries 3 ${skip:+--skip $skip} --tags ${tags:-all,never}

# Copy bootware test files for testing.
COPY --chown="${USER}" data/ ./data/
COPY --chown="${USER}" test/ ./test/

# Ensure Bash and Node are installed.
RUN command -v bash > /dev/null \
    || sudo dnf install --assumeyes bash \
    && command -v deno > /dev/null \
    || sudo dnf install --assumeyes unzip \
    && curl -LSfs https://scruffaluff.github.io/scripts/install/deno.sh | sh -s -- --global

ARG test

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if string is nonempty.
RUN if [ -n "${test}" ]; then \
    bash -l -c "test/e2e/roles.test.ts --arch ${TARGETARCH} ${skip:+--skip $skip} ${tags:+--tags $tags} fedora"; \
    fi
