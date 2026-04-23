FROM docker.io/debian:13

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# Install Curl and Sudo.
RUN apt-get update --ignore-missing && apt-get install --quiet --yes curl \
  sudo && apt-get clean --yes

# Install Picoware Bash scripts.
RUN curl -LSfs https://scruffaluff.github.io/picoware/install/scripts.sh | sh \
  -s -- --global clear-cache trsync tscp tssh && clear-cache

# Create non-priviledged user and grant user passwordless sudo.
RUN useradd --create-home --no-log-init debian \
    && usermod --append --groups sudo debian \
    && printf "debian ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

ENV HOME=/home/debian USER=debian
USER debian
WORKDIR /home/debian

# Install Bootware.
RUN curl -LSfs https://scruffaluff.github.io/bootware/install.sh | sh -s -- \
  --global && clear-cache

# Run Bootware bootstrapping.
RUN bootware bootstrap --no-passwd --extra-vars super_passwordless=true \
  --retries 3 --tags build,node,pnpm,python,rust,sysadmin && clear-cache

# Install Picoware scripts.
RUN curl -LSfs https://scruffaluff.github.io/picoware/install/scripts.sh | sh \
  -s -- --global fdi rgi rstash && clear-cache

# Set Nushell as container entrypoint.
ENTRYPOINT ["nu"]
