FROM debian:12.2 AS builder

ARG version=0.7.2

RUN apt-get update --ignore-missing && apt-get install --quiet --yes nodejs npm

# Copy bootware package build files.
COPY bootware.sh package-lock.json package.json /bootware/
COPY completions/ /bootware/completions/
COPY scripts/ /bootware/scripts/

WORKDIR /bootware
RUN npm ci

# Build Debian package.
RUN node scripts/build_package.js deb "${version}"

FROM debian:12.2

ARG version=0.7.2

# Update Apt package cache.
RUN apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" apt-get --quiet --yes install tzdata

# Pull Debian package from previous Docker stage.
COPY --from=builder "/bootware/dist/bootware_${version}_all.deb" /tmp/

# Install Debian package.
RUN apt-get install --quiet --yes "/tmp/bootware_${version}_all.deb"

# Test package was installed successfully.
RUN bootware --help
