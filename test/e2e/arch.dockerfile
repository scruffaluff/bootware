FROM docker.io/archlinux:base-20250713.0.382768

ARG TARGETARCH

# Install Curl and Sudo.
RUN pacman --noconfirm --refresh --sync --sysupgrade \
    && pacman --noconfirm --sync curl sudo

# Create non-priviledged user and grant user passwordless sudo.
RUN useradd --create-home --no-log-init arch \
    && groupadd sudo \
    && usermod --append --groups sudo arch \
    && printf "arch ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

ENV HOME=/home/arch USER=arch
USER arch

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

# Ensure Bash and Deno are installed.
RUN command -v bash > /dev/null \
    || sudo pacman --noconfirm --sync bash \
    && command -v deno > /dev/null \
    || sudo pacman --noconfirm --sync unzip \
    && curl -LSfs https://scruffaluff.github.io/scripts/install/deno.sh | sh -s -- --global

ARG test

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if string is nonempty.
RUN if [ -n "${test}" ]; then \
    bash -l -c "test/e2e/roles.test.ts --arch ${TARGETARCH} ${skip:+--skip $skip} ${tags:+--tags $tags} arch"; \
    fi
