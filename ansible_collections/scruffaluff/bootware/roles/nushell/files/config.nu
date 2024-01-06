# Nushell settings file.
#
# For more information, visit https://www.nushell.sh/book/configuration.html.

let light_theme = {
    binary: dark_gray
    block: dark_gray
    bool: dark_cyan
    cell-path: dark_gray
    date: purple
    duration: dark_gray
    empty: blue
    filesize: cyan_bold
    float: dark_gray
    header: green_bold
    hints: dark_gray
    int: dark_gray
    leading_trailing_space_bg: { attr: n }
    list: dark_gray
    nothing: dark_gray
    range: dark_gray
    record: dark_gray
    row_index: green_bold
    search_result: {fg: white bg: red}
    separator: dark_gray
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external_resolved: light_purple_bold
    shape_external: cyan
    shape_externalarg: green_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string_interpolation: cyan_bold
    shape_string: green
    shape_table: blue_bold
    shape_vardecl: purple
    shape_variable: purple
    string: dark_gray
}

$env.config = {
    color_config: $light_theme,
    ls: { clickable_links: true, use_ls_colors: true },
    show_banner: false,
}
