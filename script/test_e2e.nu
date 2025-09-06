#!/usr/bin/env nu

# Run all container end to end tests for an architecture.
def main [
    --arch (-a): string = "" # Chip architecture
    --cache (-c) # Use container cache
    --dists (-d): string = "alpine,arch,debian,fedora,ubuntu" # Linux distributions list
    --skip (-s): string = "none" # Ansible roles to skip
    --tags (-t): string = "all,never" # Ansible roles to keep
] {
    let arch = if ($arch | is-empty) {
        match $nu.os-info.arch { "aarch64" => "arm64", "x86_64" => "x64" }
    } else {
        $arch
    }
    let args = if $cache { [] } else { ["--no-cache"] }
    let dists_ = $dists | split row ","
    let runner = if (which podman | is-empty) { "docker" } else { "podman" }

    for $dist in $dists_ {
        (
            ^$runner build ...$args --file $"test/e2e/($dist).dockerfile" --tag
            $"docker.io/scruffaluff/bootware:($dist)" --platform
            $"linux/($arch)" . --build-arg $"skip=($skip)" --build-arg
            $"tags=($tags)" --build-arg test=true
        )
        print $"End to end test ($dist) passed."
    }

    print "All end to end tests passed."
}
