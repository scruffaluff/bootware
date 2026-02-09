FROM docker.io/fedora:43 AS build

ARG version

# Install Node and RPM Build.
RUN dnf makecache && dnf install --assumeyes gettext perl-Digest-SHA rpm-build

# # Copy bootware package build files.
COPY data/ /bootware/data/
COPY script/ /bootware/script/
COPY src/ /bootware/src/

WORKDIR /bootware

# Build Fedora package.
RUN script/pkg.sh --version "${version?}" rpm

FROM scratch AS dist

COPY --from=build /bootware/build/dist/ /

FROM docker.io/fedora:43

ARG version

# Install SHA checksum package.
RUN dnf makecache && dnf install --assumeyes perl-Digest-SHA

# Pull Fedora package from previous Docker stage.
COPY --from=build /bootware/build/dist/ .

# Verify checksum for Fedora package.
RUN shasum --check --algorithm 256 "bootware-${version?}-0.fc33.noarch.rpm.sha256"

# Install Fedora package.
RUN dnf install --assumeyes "./bootware-${version?}-0.fc33.noarch.rpm"

# Test package was installed successfully.
RUN bootware --help
