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
# Build all packages with checksums.
#######################################
all() {
  cp CHANGELOG.md README.md ansible_collections/scruffaluff/bootware/
  poetry run ansible-galaxy collection build --force \
    ansible_collections/scruffaluff/bootware

  mkdir -p dist
  mv "scruffaluff-bootware-${version}.tar.gz" "dist/bootware-${version}.tar.gz"
  deb "${version}"
  rpm "${version}"

  cd dist
  checksum "bootware_${version}_all.deb"
  checksum "bootware-${version}-1.fc33.noarch.rpm"
  checksum "bootware-${version}.tar.gz"
}

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
# Compute checksum for file.
#######################################
checksum() {
  shasum --algorithm 512 "${1}" > "${1}.sha512"
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
  rm -fr "${build}" "${tmp_dir}"
}

#######################################
# Script entrypoint.
#######################################
main() {
  package="${1?Package type required}"
  version="${2?Package version required}"

  case "${package}" in
    all)
      all "${version}"
      exit 0
      ;;
    apk)
      apk "${version}"
      exit 0
      ;;
    deb)
      deb "${version}"
      exit 0
      ;;
    rpm)
      rpm "${version}"
      exit 0
      ;;
    *)
      error_usage "error: Unsupported package type '${package}'."
      exit 2
      ;;
  esac
}

main "$@"
