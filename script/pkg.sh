#!/usr/bin/env sh
#
# Distribute Bootware in package formats.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

#######################################
# Show CLI help information.
# Outputs:
#   Writes help information to stdout.
#######################################
usage() {
  cat 1>&2 << EOF
Distribute Bootware in package formats.

Usage: pkg [OPTIONS] PACKAGES...

Options:
      --debug               Enable shell debug traces
  -h, --help                Print help information
  -v, --version <VERSION>   Version of Bootware package
EOF
}

#######################################
# Build an Arch package.
#
# For a tutorial on building an ALPM package, visit
# https://wiki.archlinux.org/title/creating_packages.
#######################################
alpm() {
  file="bootware-${version}-0-any.pkg.tar.zst"
  export version="${1}"
  build="$(mktemp --directory)"

  mkdir -p build/dist
  cp src/completion/bootware.bash src/completion/bootware.fish "${build}/"
  cp src/completion/bootware.man "${build}/bootware.1"
  cp src/bootware.sh "${build}/bootware"

  # Single quotes around variable is intentional to inform envsubst which
  # patterns to replace in the template.
  # shellcheck disable=SC2016
  envsubst '${version}' < data/templates/PKGBUILD.tmpl > "${build}/PKGBUILD"

  (cd "${build}" && updpkgsums)
  (cd "${build}" && makepkg --install --noconfirm --syncdeps)

  mv "${build}/${file}" build/dist/
  (cd build/dist && sha512sum "${file}" > "${file}.sha512")
}

#######################################
# Build an Alpine package.
#
# For a tutorial on building an APK package, visit
# https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package.
#######################################
apk() {
  export version="${1}"
  build="$(mktemp --directory)"

  mkdir -p build/dist "${HOME}/.abuild"
  cp src/completion/bootware.bash src/completion/bootware.fish "${build}/"
  cp src/completion/bootware.man "${build}/bootware.1"
  cp src/bootware.sh "${build}/bootware"

  # Single quotes around variable is intentional to inform envsubst which
  # patterns to replace in the template.
  # shellcheck disable=SC2016
  envsubst '${version}' < data/templates/APKBUILD.tmpl > "${build}/APKBUILD"

  (cd "${build}" && abuild checksum && abuild -r)
  mv "${HOME}/packages/tmp/$(uname -m)/bootware-${version}-r0.apk" build/dist/
  checksum "build/dist/bootware-${version}-r0.apk"
}

#######################################
# Build a Homebrew package.
#
# For a tutorial on building an Homebrew package, visit
# https://docs.brew.sh/Formula-Cookbook.
#######################################
brew() {
  version="${1}"
  url="https://github.com/scruffaluff/bootware/archive/refs/tags/${version}.tar.gz"
  curl -LSfs --output /tmp/bootware.tar.gz "${url}"
  shasum="$(sha256sum /tmp/bootware.tar.gz | cut -d ' ' -f 1)"

  mkdir -p build/dist
  export shasum="${shasum}" version="${version}" url="${url}"
  # Single quotes around variable is intentional to inform envsubst which
  # patterns to replace in the template.
  # shellcheck disable=SC2016
  envsubst '${shasum} ${url} ${version}' < data/templates/bootware.rb.tmpl \
    > build/dist/bootware.rb
  checksum build/dist/bootware.rb
}

#######################################
# Compute checksum for file.
#######################################
checksum() {
  folder="$(dirname "${1}")"
  file="$(basename "${1}")"

  if [ -x "$(command -v shasum)" ]; then
    (cd "${folder}" && shasum --algorithm 512 "${file}" > "${file}.sha512")
  elif [ -x "$(command -v sha512sum)" ]; then
    (cd "${folder}" && sha512sum "${file}" > "${file}.sha512")
  else
    error 'Unable to find a checksum command'
  fi
}

#######################################
# Build a Debian package.
#
# For a tutorial on building an DEB package, visit
# https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html.
#######################################
deb() {
  export version="${1}"
  build="$(mktemp --directory)"

  mkdir -p "${build}/DEBIAN" "${build}/usr/share/bash-completion/completions" \
    "${build}/etc/fish/completions" "${build}/usr/bin" \
    "${build}/usr/share/man/man1" build/dist

  cp src/completion/bootware.bash "${build}/usr/share/bash-completion/completions/"
  cp src/completion/bootware.fish "${build}/etc/fish/completions/"
  cp src/completion/bootware.man "${build}/usr/share/man/man1/bootware.1"
  cp src/bootware.sh "${build}/usr/bin/bootware"

  envsubst < data/templates/control.tmpl > "${build}/DEBIAN/control"
  dpkg-deb --build "${build}" "build/dist/bootware_${version}_all.deb"
  checksum "build/dist/bootware_${version}_all.deb"
}

#######################################
# Print message if error or logging is enabled.
# Arguments:
#   Message to print.
# Globals:
#   SCRIPTS_NOLOG
# Outputs:
#   Message argument.
#######################################
log() {
  local file='1' newline="\n" text=''

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      -e | --stderr)
        file='2'
        shift 1
        ;;
      -n | --no-newline)
        newline=''
        shift 1
        ;;
      *)
        text="${1}"
        shift 1
        ;;
    esac
  done

  # Print if error or using quiet configuration.
  #
  # Flags:
  #   -z: Check if string has zero length.
  if [ -z "${BOOTWARE_NOLOG:-}" ] || [ "${file}" = '2' ]; then
    printf "%s${newline}" "${text}" >&"${file}"
  fi
}

#######################################
# Build a RPM package.
#
# For a tutorial on building an RPM package, visit
# https://rpm-packaging-guide.github.io/#packaging-software.
#######################################
rpm() {
  export version="${1}"
  build="${HOME}/rpmbuild"
  tmp_dir="$(mktemp --directory)"
  archive_dir="${tmp_dir}/bootware-${version}"

  mkdir -p "${archive_dir}" "${build}/SOURCES" "${build}/SPECS" build/dist

  cp src/completion/bootware.bash src/completion/bootware.fish "${archive_dir}/"
  cp src/completion/bootware.man "${archive_dir}/bootware.1"
  cp src/bootware.sh "${archive_dir}/bootware"
  tar czf "bootware-${version}.tar.gz" -C "${tmp_dir}" .
  mv "bootware-${version}.tar.gz" "${build}/SOURCES/"

  envsubst < data/templates/bootware.spec.tmpl > "${build}/SPECS/bootware.spec"
  rpmbuild -ba "${build}/SPECS/bootware.spec"
  mv "${build}/RPMS/noarch/bootware-${version}-0.fc33.noarch.rpm" build/dist/
  checksum "build/dist/bootware-${version}-0.fc33.noarch.rpm"
  rm -fr "${build}" "${tmp_dir}"
}

#######################################
# Script entrypoint.
#######################################
main() {
  version='0.9.1'

  # Parse command line arguments.
  while [ "${#}" -gt 0 ]; do
    case "${1}" in
      --debug)
        set -o xtrace
        shift 1
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      -v | --version)
        version="${2}"
        shift 2
        ;;
      alpm)
        alpm "${version}"
        shift 1
        ;;
      apk)
        apk "${version}"
        shift 1
        ;;
      brew)
        brew "${version}"
        shift 1
        ;;
      deb)
        deb "${version}"
        shift 1
        ;;
      rpm)
        rpm "${version}"
        shift 1
        ;;
      *)
        log --stderr "error: No such option or package '${1}'."
        log --stderr "Run 'pkg --help' for usage."
        exit 2
        ;;
    esac
  done
}

main "$@"
