FROM homebrew/brew:4.4.15 AS build

ARG version

# Update Apt package cache.
RUN sudo apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN sudo apt-get --quiet --yes install \
    curl gettext-base libdigest-sha-perl

COPY scripts/ /bootware/scripts/

WORKDIR /bootware

RUN sudo mkdir -p -m 777 dist

# Build Debian package.
RUN scripts/package.sh --version "${version?}" build brew

FROM scratch AS dist

COPY --from=build "/bootware/dist/" /

FROM homebrew/brew:4.4.15

ARG version

# Update Apt package cache.
RUN sudo apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" sudo apt-get --quiet --yes install \
    libdigest-sha-perl tzdata

# Pull Homebrew package from previous Docker stage.
COPY --from=build "/bootware/dist/" .

# Verify checksum for Homebrew package.
RUN shasum --check --algorithm 512 bootware.rb.sha512

# Install Homebrew package.
RUN brew install --build-from-source ./bootware.rb

# Test package was installed successfully.
RUN bootware --help
