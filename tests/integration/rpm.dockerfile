FROM fedora:39 AS builder

ARG version=0.7.3

# Install Node and RPM Build.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }
RUN dnf install --assumeyes gettext rpm-build

# # Copy bootware package build files.
COPY bootware.sh /bootware/
COPY completions/ /bootware/completions/
COPY scripts/ /bootware/scripts/

WORKDIR /bootware

# Build Fedora package.
RUN ./scripts/build_package.sh rpm "${version}"

FROM fedora:39

ARG version=0.7.3

# Update DNF package lists.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }

# Pull Fedora package from previous Docker stage.
COPY --from=builder "/bootware/dist/bootware-${version}-1.fc33.noarch.rpm" /tmp/

# Install Fedora package.
RUN dnf install --assumeyes "/tmp/bootware-${version}-1.fc33.noarch.rpm"

# Test package was installed successfully.
RUN bootware --help
