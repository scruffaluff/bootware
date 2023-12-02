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
# Build a Debian package.
#
# For a tutorial on building an DEB package, visit
# https://www.debian.org/doc/manuals/debian-faq/pkg-basics.en.html.
#######################################
deb() {
  export version="${1}"
  build="build/bootware_${version}_all"

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

  rpmdev-setuptree
  tmp_dir="$(mktemp --directory)"
  copy_dir="${tmp_dir}/bootware-${version}"
  mkdir -p "${copy_dir}" dist

  cp completions/bootware.bash completions/bootware.fish "${copy_dir}/"
  cp completions/bootware.man "${copy_dir}/bootware.1"
  cp bootware.sh "${copy_dir}/bootware"
  tar czf "bootware-${version}.tar.gz" -C "${tmp_dir}" .
  mv "bootware-${version}.tar.gz" "${build}/SOURCES/"

  envsubst < scripts/templates/bootware.spec.tmpl > "${build}/SPECS/bootware.spec"
  rpmbuild -ba "${build}/SPECS/bootware.spec"
  mv "${build}/RPMS/noarch/bootware-${version}-1.fc33.noarch.rpm" dist/
  rm --force --recursive "${build}" "${tmp_dir}"
}

#######################################
# Script entrypoint.
#######################################
main() {
  package="${1?Package type required}"
  version="${2?Package version required}"

  case "${package}" in
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
