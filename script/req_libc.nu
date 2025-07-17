#!/usr/bin/env nu

def main [] {
    ls /usr/local/bin | get name
    | each {|path|
        let version = reqver $path
        { name: ($path | path basename) version: $version }
    } | where version != null
}

def reqver [file: string] {
    let messages = [
        "file format not recognized"
        "invalid operation"
        "not a dynamic object"
    ]
    let process = objdump -T $file | complete
    let error = $messages | any {|msg| $msg in $process.stderr }

    if not $error {
        let versions = objdump -T $file | parse --regex "GLIBC_([\\d.]+)"
        | get capture0

        if ($versions | is-not-empty) {
            $versions | sort --natural | last
        }
    }
}
