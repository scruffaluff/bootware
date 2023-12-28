FROM debian:12.4

ARG TARGETARCH
ARG version=0.7.3

# Install Ansible Curl and Sudo.
RUN apt-get update --ignore-missing \
    && apt-get install --quiet --yes ansible curl sudo

# Create non-priviledged user and grant user passwordless sudo.
RUN useradd --create-home --no-log-init collection \
    && usermod --append --groups sudo collection \
    && printf "collection ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

ENV HOME=/home/collection USER=collection
USER collection
WORKDIR $HOME

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

COPY --chown="${USER}" . $HOME/repo

RUN ansible-galaxy collection build $HOME/repo/ansible_collections/scruffaluff/bootware \
    && ansible-galaxy collection install "scruffaluff-bootware-${version}.tar.gz" \
    && cp $HOME/repo/playbook.yaml . \
    && rm --force --recursive "scruffaluff-bootware-${version}.tar.gz" $HOME/repo

# Set Bash as default shell.
SHELL ["/bin/bash", "-c"]

# Test Bootware collection with 3 retries on failure.
ENV retries=3
RUN until ansible-playbook --connection local --inventory localhost, playbook.yaml; do \
    status=$?; \
    ((retries--)) && ((retries == 0)) && exit "${status}"; \
    printf "\nCollection run failed with exit code %s." "${status}"; \
    printf "\nRetrying playbook with %s attempts left.\n" "${retries}"; \
    sleep 4; \
    done
