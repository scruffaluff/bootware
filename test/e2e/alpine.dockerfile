FROM docker.io/alpine:3

ARG TARGETARCH

# Install Bash, Curl, and Doas.
RUN apk update && apk add curl doas

# Create non-priviledged user and grant user passwordless doas.
#
# Alpine does contain the useradd command.
RUN adduser --disabled-password alpine \
    && addgroup alpine wheel \
    && printf 'permit nopass alpine\n' >> /etc/doas.d/doas.conf

ENV HOME=/home/alpine USER=alpine
USER alpine

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

ARG extra
ARG skip
ARG tags

# Run Bootware bootstrapping.
RUN bootware bootstrap --dev --no-passwd \
    --retries 3 ${extra:+--extra-vars $extra} ${skip:+--skip $skip} \
    --tags ${tags:-all,never}

# Copy bootware test files for testing.
COPY --chown="${USER}" data/ ./data/
COPY --chown="${USER}" test/ ./test/

# Ensure Bash and Node are installed.
RUN command -v bash > /dev/null \
    || doas apk add bash \
    && command -v deno > /dev/null \
    || doas apk add deno

ARG test

# Test installed binaries for roles.
#
# Flags:
#   -n: Check if string is nonempty.
RUN if [ -n "${test}" ]; then \
    bash -l -c "deno run --allow-read --allow-run test/e2e/roles.test.ts --arch ${TARGETARCH} ${skip:+--skip $skip} ${tags:+--tags $tags} alpine"; \
    fi
