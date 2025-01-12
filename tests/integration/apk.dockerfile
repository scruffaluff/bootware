FROM alpine:3.21.2 AS build

ARG version

RUN apk update && apk add alpine-sdk atools doas gettext perl-utils

RUN cat <<EOF >> /etc/abuild.conf
MAINTAINER="$PACKAGER"
PACKAGER_PRIVKEY=/bootware/alpine.rsa
PACKAGER="Alpine <alpine>"
EOF

# Create non-priviledged user and grant user passwordless doas.
#
# Alpine does contain the useradd command.
RUN adduser --disabled-password alpine \
    && addgroup alpine abuild \
    && addgroup alpine wheel \
    && printf 'permit nopass alpine\n' >> /etc/doas.d/doas.conf

ENV HOME=/home/alpine USER=alpine
USER alpine

# Copy bootware package build files.
COPY --chown="${USER}" bootware.sh /bootware/
COPY --chown="${USER}" completions/ /bootware/completions/
COPY --chown="${USER}" scripts/ /bootware/scripts/

WORKDIR /bootware

# Generate Alpine package signing keys.
RUN openssl genrsa --out alpine.rsa  \
    && doas openssl rsa --pubout --in alpine.rsa --out alpine.rsa.pub \
    && doas cp alpine.rsa.pub /etc/apk/keys/alpine.rsa.pub

# Build Alpine package.
RUN scripts/package.sh --version "${version?}" build apk

FROM scratch AS dist

COPY --from=build "/bootware/dist/" /

FROM alpine:3.21.2

ARG version

RUN apk update && apk add perl-utils

# Install Alpine package signing keys.
COPY --from=build /bootware/alpine.rsa.pub /etc/apk/keys/alpine.rsa.pub

# Pull Alpine package from previous Docker stage.
COPY --from=build "/bootware/dist/" .

# Verify checksum for Alpine package.
RUN shasum --check --algorithm 512 "bootware-${version?}-r0.apk.sha512"

# Install Alpine package.
RUN apk add "./bootware-${version?}-r0.apk"

# Test package was installed successfully.
RUN bootware --help
