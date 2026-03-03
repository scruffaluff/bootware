#!/usr/bin/env sh
#
# Format TOML files with Prettier.
#
# Designed as a standalone Unix script because the Prettier TOML plugin does not
# respect the endOfLine setting on Windows.

npx prettier --write --plugin prettier-plugin-toml '**/*.toml'
