# Fish completion file for VSCodium.
#
# For a tutorial on writing Fish completions, visit
# https://fishshell.com/docs/current/completions.html.

function __fish_complete_vscodium_extensions
    command --quiet codium; and codium --list-extensions
end

complete -c codium -s d -l diff -d 'Compare two files with each other'
complete -c codium -s m -l merge -d 'Perform a three-way merge'
complete -c codium -s a -l add -d 'Add folder(s) to the last active window'
complete -c codium -s g -l goto -r -d 'line and character position'
complete -c codium -s n -l new-window -d 'Force to open a new window'
complete -c codium -s r -l reuse-window -d 'Force to open a file or folder in an already opened window'
complete -c codium -s w -l wait -d 'Wait for the files to be closed before returning'
complete -c codium -l locale -x -d 'The locale to use (e.g. en-US or zh-TW)'
complete -c codium -l user-data-dir -ra "(__fish_complete_directories)" -d 'Specifies the directory that user data is kept in'
complete -c codium -l profile -d 'Opens the provided folder or workspace with the given profile'
complete -c codium -s v -l version -d 'Print version'
complete -c codium -s h -l help -d 'Print usage'

# Extensions management.
complete -c codium -l extensions-dir -r -d 'Set the root path for extensions'
complete -c codium -l list-extensions -d 'List the installed extensions'
complete -c codium -l show-versions -d 'Show versions of installed extensions' -n '__fish_seen_argument -l list-extensions'
complete -c codium -l category -x -d 'Filters installed extensions by provided category' -n '__fish_seen_argument -l list-extensions'
complete -c codium -l install-extension -ra "(__fish_complete_vscodium_extensions)" -d 'Installs or updates the extension'
complete -c codium -l force -n '__fish_seen_argument -l install-extension' -d 'Updates to the latest version'
complete -c codium -l pre-release -n '__fish_seen_argument -l install-extension' -d 'Installs the pre-release version'
complete -c codium -l update-extensions -d 'Update the installed extensions'
complete -c codium -l enable-proposed-api -xa "(__fish_complete_vscodium_extensions)" -d 'Enables proposed API features for extensions'
complete -c codium -l uninstall-extension -xa "(__fish_complete_vscodium_extensions)" -d 'Uninstall extension'
complete -c codium -l disable-extension -xa "(__fish_complete_vscodium_extensions)" -d 'Disable extension(s)'
complete -c codium -l disable-extensions -d 'Disable all installed extensions'

# Troubleshooting.
complete -c codium -l verbose -d 'Print verbose output (implies --wait)'
complete -c codium -l log -xa 'critical error warn info debug trace off' -d 'Log level to use (default: info)'
complete -c codium -s s -l status -d 'Print process usage and diagnostics information'
complete -c codium -l prof-startup -d 'Run CPU profiler during startup'
complete -c codium -l sync -xa 'on off' -d 'Turn sync on or off'
complete -c codium -l inspect-extensions -x -d 'Allow debugging and profiling of extensions'
complete -c codium -l inspect-brk-extensions -x -d 'Allow debugging and profiling of extensions'
complete -c codium -l disable-lcd-text -d 'Disable LCD font rendering'
complete -c codium -l disable-gpu -d 'Disable GPU hardware acceleration'
complete -c codium -l disable-chromium-sandbox -d 'Disable the Chromium sandbox environment'
