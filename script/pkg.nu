#!/usr/bin/env nu

# Distribute Bootware in package formats.
def main [] {}

# Build Bootware Ansible collection.
def "main ansible" [--version (-v): string = "0.8.3"] {
    let path = $"build/dist/scruffaluff-bootware-($version).tar.gz"
    mkdir build/dist

    cp CHANGELOG.md README.md ansible_collections/scruffaluff/bootware/
    (
        poetry run ansible-galaxy collection build --force --output-path
        build/dist ansible_collections/scruffaluff/bootware
    )
    open $path | hash sha256 | save --force $"($path).sha512"
}

# Build Bootware packages.
def "main build" [] {}

# Build Bootware packages for distribution.
def "main dist" [--version (-v): string = "0.8.3" ...packages: string] {
    let packages_ = if ($packages | is-empty) {
        ["alpm" "apk" "brew" "deb" "rpm"]
    } else {
        $packages
    }
    let runner = if (which podman | is-empty) { "docker" } else { "podman" }

    for $package in $packages_ {
        (
            ^$runner build --build-arg $"version=($version)"
            --file $"test/e2e/($package).dockerfile"
            --output build/dist --target dist .
        )
    }
}

# Run Bootware package tests in Docker.
def "main test" [--version (-v): string = "0.8.3" ...packages: string] {
    # Brew package is skipped until new release that matches repository
    # reoganization.
    let packages_ = if ($packages | is-empty) {
        ["alpm" "apk" "deb" "rpm"]
    } else {
        $packages
    }
    let runner = if (which podman | is-empty) { "docker" } else { "podman" }

    for $package in $packages_ {
        (
            ^$runner build --build-arg $"version=($version)"
            --file $"test/e2e/($package).dockerfile"
            --tag $"scruffaluff/bootware:($package)" .
        )
    }
}
