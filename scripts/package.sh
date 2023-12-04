#!/usr/bin/env sh
#
# Extend ShellCheck to check files in directories.

# Exit immediately if a command exits or pipes a non-zero return code.
#
# Flags:
#   -e: Exit immediately when a command pipeline fails.
#   -u: Throw an error when an unset variable is encountered.
set -eu

#######################################
# Build an Alpine package.
#######################################
apk() {
  export version="${1}"
  build="$(mktemp --directory)"

  abuild-keygen -n --append --install

  cp completions/bootware.bash completions/bootware.fish "${build}/"
  cp completions/bootware.man "${build}/bootware.1"
  cp bootware.sh "${build}/bootware"
  # shellcheck disable=SC2016
  envsubst '${version}' < scripts/templates/APKBUILD.tmpl > "${build}/APKBUILD"

  cd "${build}"
  abuild checksum
  abuild -r
}

#######################################
# Build subcommand.
#######################################
build() {
  version="${1}"
  shift 1

  for package in "$@"; do
    case "${package}" in
      apk)
        apk "${version}"
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
  (cd "${folder}" && shasum --algorithm 512 "${file}" > "${file}.sha512")
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

  mkdir -p "${build}/DEBIAN" "${build}/etc/bash_completion.d" \
    "${build}/etc/fish/completions" "${build}/usr/local/bin" \
    "${build}/usr/local/share/man/man1" dist

  cp completions/bootware.bash "${build}/etc/bash_completion.d/"
  cp completions/bootware.fish "${build}/etc/fish/completions/"
  cp completions/bootware.man "${build}/usr/local/share/man/man1/bootware.1"
  cp bootware.sh "${build}/usr/local/bin/bootware"

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

  for package in "$@"; do
    docker build --build-arg "version=${version}" \
      --file "tests/integration/${package}.dockerfile" \
      --output dist --target dist .
  done
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
  mv "${build}/RPMS/noarch/bootware-${version}-1.fc33.noarch.rpm" dist/
  checksum "dist/bootware-${version}-1.fc33.noarch.rpm"
  rm -fr "${build}" "${tmp_dir}"
}

#######################################
# Test subcommand.
#######################################
test() {
  version="${1}"
  shift 1

  for package in "$@"; do
    docker build --build-arg "version=${version}" \
      --file "tests/integration/${package}.dockerfile" \
      --tag "scruffaluff/bootware:${package}" .
  done
}

#######################################
# Script entrypoint.
#######################################
main() {
  case "${1?Subcommand is required}" in
    build)
      shift 1
      build "$@"
      exit 0
      ;;
    dist)
      shift 1
      dist "$@"
      exit 0
      ;;
    test)
      shift 1
      test "$@"
      exit 0
      ;;
    *)
      echo "error: No such subcommand or option '${1}'"
      exit 2
      ;;
  esac
}

main "$@"
