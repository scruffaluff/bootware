#!/usr/bin/env -S uv --no-config --quiet run --script
# /// script
# dependencies = [
#   "numpy~=2.4",
#   "pyyaml~=6.0",
#   "typer~=0.24.0",
# ]
# requires-python = "~=3.12"
# ///

"""Theme mapping tools."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING, Self

import numpy
import yaml
from typer import Typer

if TYPE_CHECKING:
    from collections.abc import Iterator

cli = Typer(
    add_completion=False,
    help="Color converter helper.",
    no_args_is_help=True,
    pretty_exceptions_enable=False,
)
repo = Path(__file__).parents[1]


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


def find_colors(text: str) -> Iterator[tuple[str, tuple[int, int, int]]]:
    """Find all color in a text."""
    for match in re.finditer(r"#\d{6}", text):
        start, stop = match.span()
        color = match.string[start:stop]
        yield color, hex_to_rgb(color)

    for match in re.finditer(r"(\d+)[,\s]+(\d+)[,\s]+(\d+)", text):
        start, stop = match.span()
        rgb: tuple[int, int, int] = tuple(int(group) for group in match.groups())  # ty:ignore[invalid-assignment]
        yield match.string[start:stop], rgb


def hex_to_rgb(color: str) -> tuple[int, int, int]:
    """Convert hexadecimal color to RGB array."""
    if len(color) != 7:
        msg = f"Hex color '{color}' must be 7 characters long."
        raise ValueError(msg)
    return tuple(int(color[1:][i : i + 2], 16) for i in (0, 2, 4))  # ty:ignore[invalid-return-type]


@cli.command()
def solar(path: Path) -> None:
    """Map all color values in a file to the closest solarized color."""
    theme = Theme.from_file("solarized")
    text = path.read_text()
    colors = find_colors(text)

    for color in colors:
        closest = theme.closest(color[1])[1]
        text = text.replace(color[0], f'"{closest}"')
    path.write_text(text)


if __name__ == "__main__":
    cli(prog_name="color")
