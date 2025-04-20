FROM docker.io/debian:12.8

ARG TARGETARCH

# Install Curl and Sudo.
RUN apt-get update --ignore-missing && apt-get install --quiet --yes curl sudo

# Create non-priviledged user and grant user passwordless sudo.
RUN useradd --create-home --no-log-init debian \
    && usermod --append --groups sudo debian \
    && printf "debian ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

ENV HOME=/home/debian USER=debian
USER debian

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
    || sudo apt-get install --quiet --yes bash \
    && command -v deno > /dev/null \
    || sudo apt-get install --quiet --yes unzip \
    && curl -LSfs https://scruffaluff.github.io/scripts/install/deno.sh | sh -s -- --global

ARG test

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if string is nonempty.
RUN if [ -n "${test}" ]; then \
    bash -l -c "test/e2e/roles.test.ts --arch ${TARGETARCH} ${skip:+--skip $skip} ${tags:+--tags $tags} debian"; \
    fi
