FROM node:20.1.0 AS builder

ARG version=1.0.0

# Copy bootware package build files.
COPY scripts/ /bootware/scripts/
COPY bootware.1 /bootware/
COPY bootware.sh /bootware/
COPY package.json /bootware/

WORKDIR /bootware
RUN npm install

# Build Debian package.
RUN node scripts/build_package.js deb "${version}"

FROM ubuntu:23.04

ARG version=1.0.0

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
