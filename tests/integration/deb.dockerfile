FROM debian:12.8 AS build

ARG version

RUN apt-get update --ignore-missing && apt-get install --quiet --yes \
    gettext-base libdigest-sha-perl

# Copy bootware package build files.
COPY bootware.sh /bootware/
COPY completions/ /bootware/completions/
COPY scripts/ /bootware/scripts/

WORKDIR /bootware

# Build Debian package.
RUN scripts/package.sh --version "${version?}" build deb

FROM scratch AS dist

COPY --from=build "/bootware/dist/" /

FROM debian:12.8

ARG version

# Update Apt package cache.
RUN apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" apt-get --quiet --yes install \
    libdigest-sha-perl tzdata

# Pull Debian package from previous Docker stage.
COPY --from=build "/bootware/dist/" .

# Verify checksum for Debian package.
RUN shasum --check --algorithm 512 "bootware_${version?}_all.deb.sha512"

# Install Debian package.
RUN apt-get install --quiet --yes "./bootware_${version?}_all.deb"

# Test package was installed successfully.
RUN bootware --help
