# Tests for Nushell profile.

use std/assert
use std/testing *

source ../../ansible_collections/scruffaluff/bootware/roles/nushell/files/config.nu

# Test mocks.
export def commandline [] { $env.NUTEST_COMMANDLINE }
export def --env --wrapped "commandline edit" [--replace ...args: string] {
    $args | str join "" | save --force $"($env.NUTEST_TMPDIR)/commandline_edit"
}
export def "commandline get-cursor" [] {
    $env.NUTEST_COMMANDLINE_GETCURSOR | into int
}
export def --env --wrapped "commandline set-cursor" [...args: string] {
    $args | str join ""
    | save --force $"($env.NUTEST_TMPDIR)/commandline_setcursor"
}
def --wrapped fzf [...args: string] { $env.NUTEST_FZF }

@test
def "_cut-path-left cases" [] {
    $env.NUTEST_TMPDIR = mktemp --directory --tmpdir

    for case in [
        [cursor expected line];
        [0 { cursor: 0 line: "src/path" } "src/path"]
        [8 { cursor: 4 line: "vim " } "vim path"]
        [12 { cursor: 8 line: "vim src/" } "vim src/path"]
    ] {
        $env.NUTEST_COMMANDLINE = $case.line
        $env.NUTEST_COMMANDLINE_GETCURSOR = $case.cursor | into string

        _cut-path-left
        let actual = {
            cursor: (
                open --raw $"($env.NUTEST_TMPDIR)/commandline_setcursor"
                | into int
            )
            line: (open --raw $"($env.NUTEST_TMPDIR)/commandline_edit")
        }
        assert equal $actual $case.expected
    }
}

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
    $env.NUTEST_TMPDIR = mktemp --directory --tmpdir

    for case in [
        [cursor expected fzf line];
        [0 { cursor: 8 line: "src/path" } "src/path" ""]
        [4 { cursor: 8 line: "vim path" } "path" "vim "]
        [4 { cursor: 8 line: "vim path " } "path" "vim  "]
        [3 { cursor: 7 line: "   file " } "file" "    "]
        [6 { cursor: 9 line: " vim path" } "path" " vim foo"]
        [4 { cursor: 8 line: "vim path  foo" } "path" "vim   foo"]
        [8 { cursor: 13 line: "vim  src/path test" } "path" "vim  src/fa test"]
    ] {
        $env.NUTEST_COMMANDLINE = $case.line
        $env.NUTEST_COMMANDLINE_GETCURSOR = $case.cursor | into string
        $env.NUTEST_FZF = $case.fzf

        fzf-path-widget
        let actual = {
            cursor: (
                open --raw $"($env.NUTEST_TMPDIR)/commandline_setcursor"
                | into int
            )
            line: (
                open --raw $"($env.NUTEST_TMPDIR)/commandline_edit"
                | str replace "\\" "/"
            )
        }
        assert equal $actual $case.expected
    }
}
