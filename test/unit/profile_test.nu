# Tests for Nushell installer scripts.

use std/assert
use std/testing *

source ../../ansible_collections/scruffaluff/bootware/roles/nushell/files/config.nu

let output = mktemp --tmpdir

export def commandline [] { $env.NUTEST_COMMANDLINE }
export def --env --wrapped "commandline edit" [--replace ...args: string] {
    $args | str join "" | save --force $output
}
export def "commandline get-cursor" [] {
    $env.NUTEST_COMMANDLINE_GETCURSOR | into int
}
def --wrapped fzf [...args: string] { $env.NUTEST_FZF }

@test
def "commandline argument cases" [] {
    for case in [
        [cursor expected line];
        [0 {start: 0 stop: 3 token: "vim" } "vim"]
        [5 {start: 4 stop: 8 token: "path" } "vim path"]
        [4 {start: 4 stop: 4 token: "" } "vim  path"]
    ] {
        $env.NUTEST_COMMANDLINE = $case.line
        $env.NUTEST_COMMANDLINE_GETCURSOR = $case.cursor | into string

        let actual = commandline argument
        assert equal $actual $case.expected
    }
}

@test
def "fzf-path-widget cases" [] {
    for case in [
        [cursor expected fzf line];
        [0 "src/path" "src/path" ""]
        [4 "vim path" "path" "vim "]
        [4 "vim path " "path" "vim  "]
        [5 "vim path" "path" "vim foo"]
        [4 "vim path  foo" "path" "vim   foo"]
    ] {
        $env.NUTEST_COMMANDLINE = $case.line
        $env.NUTEST_COMMANDLINE_GETCURSOR = $case.cursor | into string
        $env.NUTEST_FZF = $case.fzf

        fzf-path-widget
        let actual = open --raw $output
        assert equal $actual $case.expected
    }
}
