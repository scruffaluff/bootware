FROM alpine:3.21.2

ARG TARGETARCH

# Install Bash, Curl, and Doas.
RUN apk update && apk add bash curl doas

# Create non-priviledged user and grant user passwordless doas.
#
# Alpine does contain the useradd command.
RUN adduser --disabled-password alpine \
    && addgroup alpine wheel \
    && printf 'permit nopass alpine\n' >> /etc/doas.d/doas.conf

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
    || doas apk add bash \
    && command -v node > /dev/null \
    || doas apk add nodejs

# Set Bash as default shell.
SHELL ["/bin/bash", "-c"]

ARG test

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if string is nonempty.
RUN if [[ -n "${test}" ]]; then \
    source "${HOME}/.bashrc"; \
    node tests/integration/roles.test.cjs --arch "${TARGETARCH}" ${skip:+--skip $skip} ${tags:+--tags $tags} "alpine"; \
    fi
