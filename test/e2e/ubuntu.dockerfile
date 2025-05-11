FROM docker.io/ubuntu:24.04

ARG TARGETARCH
ARG version=0.8.3

# Install Ansible Curl and Sudo.
RUN apt-get update --ignore-missing \
    && apt-get install --quiet --yes ansible curl sudo

# Grant ubuntu user passwordless sudo.
RUN usermod --append --groups sudo ubuntu \
    && printf "ubuntu ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# Ubuntu container comes with a builtin Ubuntu user.
ENV HOME=/home/ubuntu USER=ubuntu
USER ubuntu
WORKDIR $HOME

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

COPY --chown="${USER}" . $HOME/repo

ARG skip
ARG tags

RUN ansible-galaxy collection build $HOME/repo/ansible_collections/scruffaluff/bootware \
    && ansible-galaxy collection install "scruffaluff-bootware-${version}.tar.gz" \
    && cp $HOME/repo/playbook.yaml . \
    && rm --force --recursive "scruffaluff-bootware-${version}.tar.gz" $HOME/repo

# Test Bootware collection with 3 retries on failure.
ENV retries=3
RUN until ansible-playbook --connection local --inventory localhost, ${skip:+--skip-tags $skip} --tags ${tags:-all,never} playbook.yaml; do \
    status=$?; \
    retries="$((retries - 1))"; \
    if [ "${retries}" -eq 0 ]; then exit "${status}"; fi; \
    printf "\nCollection run failed with exit code %s." "${status}"; \
    printf "\nRetrying playbook with %s attempts left.\n" "${retries}"; \
    sleep 4; \
    done

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
