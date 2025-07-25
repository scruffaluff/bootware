# Add folders to system paths.
# shellcheck shell=sh

# Prepend existing directories that are not in the system path.
#
# Flags:
#   -d: Check if path is a directory.
prepend_paths() {
  local folder inode
  for inode in "$@"; do
    if [ -d "${inode}" ]; then
      # Expand folder to its full path.
      folder="$(cd "${inode}" && pwd)"
      case ":${PATH}:" in
        *:"${folder}":*) ;;
        *)
          export PATH="${folder}:${PATH}"
          ;;
      esac
    fi
  done
}

prepend_paths '/usr/sbin' '/usr/local/bin'
