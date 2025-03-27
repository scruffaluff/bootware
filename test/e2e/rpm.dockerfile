FROM docker.io/fedora:41 AS build

ARG version

# Install Node and RPM Build.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }
RUN dnf install --assumeyes gettext perl-Digest-SHA rpm-build

# # Copy bootware package build files.
COPY data/ /bootware/data/
COPY script/ /bootware/script/
COPY src/ /bootware/src/

WORKDIR /bootware

# Build Fedora package.
RUN script/pkg.sh --version "${version?}" rpm

FROM docker.io/scratch AS dist

COPY --from=build /bootware/build/dist/ /

FROM docker.io/fedora:41

ARG version

# Update DNF package lists.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }
RUN dnf install --assumeyes perl-Digest-SHA

# Pull Fedora package from previous Docker stage.
COPY --from=build /bootware/build/dist/ .

# Verify checksum for Fedora package.
RUN shasum --check --algorithm 512 "bootware-${version?}-0.fc33.noarch.rpm.sha512"

# Install Fedora package.
RUN dnf install --assumeyes "./bootware-${version?}-0.fc33.noarch.rpm"

# Test package was installed successfully.
RUN bootware --help
