FROM docker.io/homebrew/brew:4.4.15 AS build

ARG version

# Update Apt package cache.
RUN sudo apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN sudo apt-get --quiet --yes install \
    curl gettext-base libdigest-sha-perl

COPY data/ /bootware/data/
COPY script/ /bootware/script/
COPY src/ /bootware/src/

WORKDIR /bootware

RUN sudo mkdir -p -m 777 build

# Build Homebrew package.
RUN script/pkg.sh --version "${version?}" brew

FROM docker.io/scratch AS dist

COPY --from=build /bootware/build/dist/ /

FROM docker.io/homebrew/brew:4.4.15

ARG version

# Update Apt package cache.
RUN sudo apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" sudo apt-get --quiet --yes install \
    libdigest-sha-perl tzdata

# Pull Homebrew package from previous Docker stage.
COPY --from=build /bootware/build/dist/ .

# Verify checksum for Homebrew package.
RUN shasum --check --algorithm 512 bootware.rb.sha512

# Install Homebrew package.
RUN brew install --build-from-source ./bootware.rb

# Test package was installed successfully.
RUN bootware --help
