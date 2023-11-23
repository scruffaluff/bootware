FROM fedora:39 AS builder

ARG version=0.7.2

# Update DNF package lists.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }

RUN dnf install --assumeyes nodejs rpm-build

# # Copy bootware package build files.
COPY bootware.1 bootware.sh package-lock.json package.json /bootware/
COPY scripts/ /bootware/scripts/

WORKDIR /bootware
RUN npm ci

# Build Fedora package.
RUN node scripts/build_package.js rpm "${version}"

FROM fedora:39

ARG version=0.7.2

# Update DNF package lists.
RUN dnf check-update || {
rc=$?
[ "$rc" -eq 100 ] && exit 0
exit "$rc"
}

# Pull Fedora package from previous Docker stage.
COPY --from=builder "/bootware/dist/bootware-${version}-1.fc33.noarch.rpm" /tmp/

# Install Fedora package.
RUN dnf install --assumeyes "/tmp/bootware-${version}-1.fc33.noarch.rpm"

# Test package was installed successfully.
RUN bootware --help
