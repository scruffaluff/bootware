FROM archlinux:base-20250112.0.297543 AS build

ARG version

RUN pacman --noconfirm --refresh --sync --sysupgrade \
    && pacman --noconfirm --sync base-devel pacman-contrib perl

# Create non-priviledged user and grant user passwordless sudo.
RUN useradd --create-home --no-log-init arch \
    && groupadd sudo \
    && usermod --append --groups sudo arch \
    && printf "arch ALL=(ALL) NOPASSWD:ALL\n" >> /etc/sudoers

ENV HOME=/home/arch USER=arch
USER arch

# Copy bootware package build files.
COPY --chown="${USER}" bootware.sh /bootware/
COPY --chown="${USER}" completions/ /bootware/completions/
COPY --chown="${USER}" scripts/ /bootware/scripts/

WORKDIR /bootware

# Build Arch package.
RUN scripts/package.sh --version "${version?}" build alpm

FROM scratch AS dist

COPY --from=build "/bootware/dist/" /

FROM archlinux:base-20250112.0.297543

ARG version

RUN pacman --noconfirm --refresh --sync --sysupgrade \
    && pacman --noconfirm --sync perl

# Pull Arch package from previous Docker stage.
COPY --from=build "/bootware/dist/" .

# Verify checksum for Arch package.
RUN sha512sum --check "bootware-${version}-0-any.pkg.tar.zst.sha512"

# Install Arch package.
RUN pacman --noconfirm --upgrade "./bootware-${version}-0-any.pkg.tar.zst"

# Test package was installed successfully.
RUN bootware --help
