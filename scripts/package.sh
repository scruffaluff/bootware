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
# Cannot use function name help, since help is a pre-existing command.
# Outputs:
#   Writes help information to stdout.
#######################################
usage() {
  cat 1>&2 << EOF
Distribute Bootware in package formats.

Usage: package [OPTIONS] [SUBCOMMAND] PACKAGES

Options:
      --debug               Enable shell debug traces
  -h, --help                Print help information
  -v, --version <VERSION>   Version of Bootware package

Subcommands:
  ansible   Build Bootware Ansible collection
  build     Build Bootware packages
  dist      Build Bootware packages for distribution
  test      Run Bootware package tests in Docker
EOF
}

#######################################
# Build Ansible Galaxy collection.
#######################################
ansible_() {
  filename="scruffaluff-bootware-${1}.tar.gz"
  mkdir -p dist

  cp CHANGELOG.md README.md ansible_collections/scruffaluff/bootware/
  poetry run ansible-galaxy collection build --force --output-path dist \
    ansible_collections/scruffaluff/bootware
  checksum "dist/${filename}"
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

  mkdir -p dist
  cp completions/bootware.bash completions/bootware.fish "${build}/"
  cp completions/bootware.man "${build}/bootware.1"
  cp bootware.sh "${build}/bootware"

  # Single quotes around variable is intentional to inform envsubst which
  # patterns to replace in the template.
  # shellcheck disable=SC2016
  envsubst '${version}' < scripts/templates/PKGBUILD.tmpl > "${build}/PKGBUILD"

  (cd "${build}" && updpkgsums)
  (cd "${build}" && makepkg --install --noconfirm --syncdeps)

  mv "${build}/${file}" dist/
  (cd dist && sha512sum "${file}" > "${file}.sha512")
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

  mkdir -p dist "${HOME}/.abuild"
  cp completions/bootware.bash completions/bootware.fish "${build}/"
  cp completions/bootware.man "${build}/bootware.1"
  cp bootware.sh "${build}/bootware"

  # Single quotes around variable is intentional to inform envsubst which
  # patterns to replace in the template.
  # shellcheck disable=SC2016
  envsubst '${version}' < scripts/templates/APKBUILD.tmpl > "${build}/APKBUILD"

  (cd "${build}" && abuild checksum && abuild -r)
  mv "${HOME}/packages/tmp/$(uname -m)/bootware-${version}-r0.apk" dist/
  checksum "dist/bootware-${version}-r0.apk"
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

  mkdir -p dist
  export shasum="${shasum}" version="${version}" url="${url}"
  # Single quotes around variable is intentional to inform envsubst which
  # patterns to replace in the template.
  # shellcheck disable=SC2016
  envsubst '${shasum} ${url} ${version}' < scripts/templates/bootware.rb.tmpl \
    > dist/bootware.rb
  checksum "dist/bootware.rb"
}

#######################################
# Build subcommand.
#######################################
build() {
  version="${1}"
  shift 1

  for package in "$@"; do
    case "${package}" in
      alpm)
        alpm "${version}"
        ;;
      apk)
        apk "${version}"
        ;;
      brew)
        brew "${version}"
        ;;
      deb)
        deb "${version}"
        ;;
      rpm)
        rpm "${version}"
        ;;
      *)
        echo "error: Unsupported package type '${package}'."
        exit 2
        ;;
    esac
  done
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
    "${build}/usr/share/man/man1" dist

  cp completions/bootware.bash "${build}/usr/share/bash-completion/completions/"
  cp completions/bootware.fish "${build}/etc/fish/completions/"
  cp completions/bootware.man "${build}/usr/share/man/man1/bootware.1"
  cp bootware.sh "${build}/usr/bin/bootware"

  envsubst < scripts/templates/control.tmpl > "${build}/DEBIAN/control"
  dpkg-deb --build "${build}" "dist/bootware_${version}_all.deb"
  checksum "dist/bootware_${version}_all.deb"
}

#######################################
# Dist subcommand.
#######################################
dist() {
  version="${1}"
  shift 1

  container="$(find_container)"
  for package in "$@"; do
    "${container}" build --build-arg "version=${version}" \
      --file "tests/integration/${package}.dockerfile" \
      --output dist --target dist .
  done
}

#######################################
# Print error message and exit script with error code.
# Outputs:
#   Writes error message to stderr.
#######################################
error() {
  bold_red='\033[1;31m' default='\033[0m'
  printf "${bold_red}error${default}: %s\n" "${1}" >&2
  exit 1
}

#######################################
# Find command to manage containers.
#######################################
find_container() {
  # Flags:
  #   -v: Only show file path of command.
  #   -x: Check if file exists and execute permission is granted.
  if [ -x "$(command -v podman)" ]; then
    echo 'podman'
  elif [ -x "$(command -v docker)" ]; then
    echo 'docker'
  else
    error 'Unable to find a command for container management'
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

  mkdir -p "${archive_dir}" "${build}/SOURCES" "${build}/SPECS" dist

  cp completions/bootware.bash completions/bootware.fish "${archive_dir}/"
  cp completions/bootware.man "${archive_dir}/bootware.1"
  cp bootware.sh "${archive_dir}/bootware"
  tar czf "bootware-${version}.tar.gz" -C "${tmp_dir}" .
  mv "bootware-${version}.tar.gz" "${build}/SOURCES/"

  envsubst < scripts/templates/bootware.spec.tmpl > "${build}/SPECS/bootware.spec"
  rpmbuild -ba "${build}/SPECS/bootware.spec"
  mv "${build}/RPMS/noarch/bootware-${version}-0.fc33.noarch.rpm" dist/
  checksum "dist/bootware-${version}-0.fc33.noarch.rpm"
  rm -fr "${build}" "${tmp_dir}"
}

#######################################
# Test subcommand.
#######################################
test() {
  version="${1}"
  shift 1

  container="$(find_container)"
  for package in "$@"; do
    "${container}" build --build-arg "version=${version}" \
      --file "tests/integration/${package}.dockerfile" \
      --tag "scruffaluff/bootware:${package}" .
  done
}

#######################################
# Script entrypoint.
#######################################
main() {
  version='0.8.3'

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
      ansible)
        shift 1
        ansible_ "${version}" "$@"
        exit 0
        ;;
      build)
        shift 1
        build "${version}" "$@"
        exit 0
        ;;
      dist)
        shift 1
        dist "${version}" "$@"
        exit 0
        ;;
      test)
        shift 1
        test "${version}" "$@"
        exit 0
        ;;
      *)
        echo "error: No such subcommand or option '${1}'"
        exit 2
        ;;
    esac
  done

  usage
}

main "$@"
