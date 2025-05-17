FROM docker.io/debian:12.10 AS build

ARG version

RUN apt-get update --ignore-missing && apt-get install --quiet --yes \
    gettext-base libdigest-sha-perl

# Copy bootware package build files.
COPY data/ /bootware/data/
COPY script/ /bootware/script/
COPY src/ /bootware/src/

WORKDIR /bootware

# Build Debian package.
RUN script/pkg.sh --version "${version?}" deb

FROM scratch AS dist

COPY --from=build /bootware/build/dist/ /

FROM docker.io/debian:12.10

ARG version

# Update Apt package cache.
RUN apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" apt-get --quiet --yes install \
    libdigest-sha-perl tzdata

# Pull Debian package from previous Docker stage.
COPY --from=build /bootware/build/dist/ .

# Verify checksum for Debian package.
RUN shasum --check --algorithm 512 "bootware_${version?}_all.deb.sha512"

# Install Debian package.
RUN apt-get install --quiet --yes "./bootware_${version?}_all.deb"

# Test package was installed successfully.
RUN bootware --help
