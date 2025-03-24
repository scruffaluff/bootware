#!/usr/bin/env nu

# Run all container end to end tests for an architecture.
def main [
    --arch (-a): string = "" # Chip architecture
    --cache (-c) # Use container cache
    --dists (-d): list<string> = ["alpine" "arch" "debian" "fedora" "suse" "ubuntu"] # Linux distributions list
    --skip (-s): string = "none" # Ansible roles to skip
    --tags (-t): string = "desktop,extras" # Ansible roles to keep
] {
    let args = if $cache { [] } else { ["--no-cache"] }
    let runner = if (which podman | is-empty) { "docker" } else { "podman" }

    for $dist in $dists {
        (
            ^$runner build ...$args --file $"test/e2e/($dist).dockerfile"
            --tag $"docker.io/scruffaluff/bootware:($dist)"
            --platform $"linux/($arch)" . --build-arg $"skip=($skip)"
            --build-arg $"tags=($tags)" --build-arg test=true
        )
        print $"End to end test ($dist) passed."
    }

    print "All end to end tests passed."
}
