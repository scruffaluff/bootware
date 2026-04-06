#!/usr/bin/env -S uv --no-config --quiet run --script
# /// script
# dependencies = [
#   "loguru~=0.7.0",
#   "numpy~=2.4",
#   "pyyaml~=6.0",
#   "typer~=0.24.0",
# ]
# requires-python = "~=3.12"
# ///

"""Map color themes for configuration files."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Annotated, Any, Self

import numpy
import yaml
from loguru import logger
from typer import Option, Typer

if TYPE_CHECKING:
    from collections.abc import Iterator

cli = Typer(
    add_completion=False,
    help="Map color themes for configuration files.",
    no_args_is_help=True,
    pretty_exceptions_enable=False,
)
repo = Path(__file__).parents[1]
# Shared state to hold global application flags.
state: dict[str, Any] = {"dry_run": False}


class Theme:
    """Color theme."""

    def __init__(self, colors: dict[str, str]) -> None:
        """Create a new theme instance."""
        self.colors = colors
        self.names = []
        rgbs = []
        for name, hex_ in colors.items():
            self.names.append(name)
            rgbs.append(hex_to_rgb(hex_))
        self.rgbs = numpy.array(rgbs)

    def closest(self, color: tuple[int, int, int]) -> tuple[str, str]:
        """Find closest theme color to input color."""
        diff = numpy.sum((self.rgbs - color) ** 2, axis=1)
        index = numpy.argmin(diff)
        name = self.names[index]
        return name, self.colors[name]

    @classmethod
    def from_file(cls, name: str) -> Self:
        """Load theme from color file."""
        with Path.open(repo / "data/color.yaml") as file:
            colors = yaml.safe_load(file)
        return cls(colors[name])


def find_colors(text: str) -> Iterator[tuple[str, tuple[int, int, int], bool]]:
    """Find all color in a text."""
    for match in re.finditer(r"#[A-Fa-f\d]{6}", text):
        start, stop = match.span()
        color = match.string[start:stop]
        yield color, hex_to_rgb(color), False

    for match in re.finditer(r"(\d+)[,\s]+(\d+)[,\s]+(\d+)", text):
        start, stop = match.span()
        rgb: tuple[int, int, int] = tuple(int(group) for group in match.groups())  # ty:ignore[invalid-assignment]
        yield match.string[start:stop], rgb, True


def hex_to_rgb(color: str) -> tuple[int, int, int]:
    """Convert hexadecimal color to RGB array."""
    if len(color) != 7:
        msg = f"Hex color '{color}' must be 7 characters long."
        raise ValueError(msg)
    return tuple(int(color[1:][i : i + 2], 16) for i in (0, 2, 4))  # ty:ignore[invalid-return-type]


@cli.callback()
def main(
    dry_run: Annotated[
        bool,
        Option("-d", "--dry-run", help="Only print actions to be taken."),
    ] = False,
    log_level: Annotated[str, Option("-l", "--log-level", help="Log level.")] = "info",
) -> None:
    """Rclone wrapper for interactive and conditional backups."""
    logger.remove()
    logger.add(sys.stderr, level=log_level.upper())
    state["dry_run"] = dry_run


@cli.command()
def solarize(path: Path) -> None:
    """Map all color values in a file to the closest solarized color."""
    theme = Theme.from_file("solarized")
    logger.debug(f"Analyzing file {path}.")
    text = path.read_text()
    colors = find_colors(text)

    for string, value, rgb in colors:
        logger.debug(f"Found color '{string}'.")
        closest = theme.closest(value)[1]
        replacement = f'"{closest}"' if rgb else closest
        if string != replacement:
            logger.info(f"Replacing '{string}' with '{replacement}'.")
            text = text.replace(string, replacement)

    if state["dry_run"]:
        print(text)
    else:
        path.write_text(text)


@cli.command()
def variable(path: Path) -> None:
    """Map all solarized color values to their variable reference."""
    theme_ = Theme.from_file("variable")
    theme = {value: key for key, value in theme_.colors.items()}
    logger.debug(f"Analyzing file {path}.")
    text = path.read_text()
    colors = find_colors(text)

    for string, _, _ in colors:
        logger.debug(f"Found color '{string}'.")
        try:
            name = theme[string]
        except KeyError:
            logger.warning(f"Color '{string}' is not defined in theme.")
            continue

        replacement = f"{{{{ theme.default.{name} }}}}"
        if string != replacement:
            logger.info(f"Replacing '{string}' with '{replacement}'.")
            text = text.replace(string, replacement)

    if state["dry_run"]:
        print(text)
    else:
        path.write_text(text)


if __name__ == "__main__":
    cli(prog_name="colormap")
