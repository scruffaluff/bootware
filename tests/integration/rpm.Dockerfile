FROM fedora:38 AS builder

ARG version=1.0.0

# Update DNF package lists.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }

RUN dnf install --assumeyes nodejs rpm-build

# # Copy bootware package build files.
COPY scripts/ /bootware/scripts/
COPY bootware.1 /bootware/
COPY bootware.sh /bootware/
COPY package.json /bootware/

WORKDIR /bootware
RUN npm install

# Build Fedora package.
RUN node scripts/build_package.js rpm "${version}"

FROM fedora:37

ARG version=1.0.0

# Update DNF package lists.
RUN dnf check-update || { rc=$?; [ "$rc" -eq 100 ] && exit 0; exit "$rc"; }

# Pull Fedora package from previous Docker stage.
COPY --from=builder "/bootware/dist/bootware-${version}-1.fc33.noarch.rpm" /tmp/

# Install Fedora package.
RUN dnf install --assumeyes "/tmp/bootware-${version}-1.fc33.noarch.rpm"

# Test package was installed successfully.
RUN bootware --help
