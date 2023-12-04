FROM alpine:3.18.4 AS build

ARG version

RUN apk update && apk add alpine-sdk atools doas gettext
RUN printf 'PACKAGER="Macklan Weinstein <macklan.weinstein@gmail.com>"\nMAINTAINER="$PACKAGER"\n' >> /etc/abuild.conf

# Create non-priviledged user and grant user passwordless doas.
#
# Alpine does contain the useradd command.
RUN adduser --disabled-password alpine \
    && addgroup alpine abuild \
    && addgroup alpine wheel \
    && printf 'permit nopass alpine as root\n' >> /etc/doas.d/doas.conf

ENV HOME=/home/alpine USER=alpine
USER alpine

# Copy bootware package build files.
COPY bootware.sh /bootware/
COPY completions/ /bootware/completions/
COPY scripts/ /bootware/scripts/

WORKDIR /bootware

# Build Alpine package.
RUN ./scripts/package.sh build "${version}" apk
