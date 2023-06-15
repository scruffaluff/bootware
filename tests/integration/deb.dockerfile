FROM node:20.1.0 AS builder

ARG version=0.5.2

# Copy bootware package build files.
COPY bootware.1 bootware.sh package-lock.json package.json /bootware/
COPY scripts/ /bootware/scripts/

WORKDIR /bootware
RUN npm ci

# Build Debian package.
RUN node scripts/build_package.js deb "${version}"

FROM debian:12.0

ARG version=0.5.2

# Update Apt package cache.
RUN apt-get update

# Avoid APT interactively requesting to configure tzdata.
RUN DEBIAN_FRONTEND="noninteractive" apt-get --yes install tzdata

# Pull Debian package from previous Docker stage.
COPY --from=builder "/bootware/dist/bootware_${version}_all.deb" /tmp/

# Install Debian package.
RUN apt-get install --yes "/tmp/bootware_${version}_all.deb"

# Test package was installed successfully.
RUN bootware --help
