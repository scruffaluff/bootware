FROM docker.io/archlinux:base-20250112.0.297543 AS build

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
COPY --chown="${USER}" data/ /bootware/data/
COPY --chown="${USER}" script/ /bootware/script/
COPY --chown="${USER}" src/ /bootware/src/

WORKDIR /bootware

# Build Arch package.
RUN script/pkg.sh --version "${version?}" alpm

FROM docker.io/scratch AS dist

COPY --from=build /bootware/build/dist/ /

FROM docker.io/archlinux:base-20250112.0.297543

ARG version

RUN pacman --noconfirm --refresh --sync --sysupgrade \
    && pacman --noconfirm --sync perl

# Pull Arch package from previous Docker stage.
COPY --from=build /bootware/build/dist/ .

# Verify checksum for Arch package.
RUN sha512sum --check "bootware-${version}-0-any.pkg.tar.zst.sha512"

# Install Arch package.
RUN pacman --noconfirm --upgrade "./bootware-${version}-0-any.pkg.tar.zst"

# Test package was installed successfully.
RUN bootware --help
