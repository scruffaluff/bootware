FROM debian:12.0

ARG TARGETARCH

# Create non-priviledged user.
RUN useradd --create-home --no-log-init --shell /bin/bash collection

# Install Bash, Curl and Sudo.
RUN apt-get update --ignore-missing && apt-get install --quiet --yes ansible bash curl sudo

# Add standard user to sudoers group.
RUN usermod --append --groups sudo collection

# Allow sudo commands with no password.
RUN printf "%%sudo ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

# Fix current sudo bug for containers.
# https://github.com/sudo-project/sudo/issues/42
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

ENV HOME=/home/collection USER=collection
USER collection
WORKDIR $HOME

# VSCode, when run inside of a container, will falsely warn the user about the
# issues of running inside of the WSL and force a yes or no prompt.
ENV DONT_PROMPT_WSL_INSTALL='true'

COPY --chown="${USER}" . $HOME/repo

RUN ansible-galaxy collection install $HOME/repo && rm -fr $HOME/repo

# Copy Bootware test playbook.
COPY --chown="${USER}" tests/data/playbook.yaml /home/collection/

# Set Bash as default shell.
SHELL ["/bin/bash", "-c"]

# Test Bootware collection.
RUN ansible-playbook --inventory localhost, playbook.yaml

RUN until ansible-playbook --inventory localhost, playbook.yaml; do \
        status=$? \
        ((retries--)) && ((retries == 0)) && exit "${status}" \
        printf "\nCollection run failed with exit code %s." "${status}" \
        printf "\nRetrying playbook with %s attempts left.\n" "${retries}" \
        sleep 4 \
    done
