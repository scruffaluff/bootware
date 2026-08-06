"""Tests for custom plotting routines."""

# ruff: noqa: E402

import sys
from pathlib import Path

repo_path = Path(__file__).parents[2]
sys.path.append(
    str(repo_path / "ansible_collections/scruffaluff/bootware/roles/python/files")
)

import plotrc


def test_spectrum_ticks() -> None:
    """Spectrum ticks match octaves based on A4."""
    expected = [27.5, 55.0, 110.0, 220.0, 440.0, 880.0, 1760.0, 3520.0, 7040.0, 14080.0]
    ticks = plotrc.spectrum_ticks()[0]
    assert ticks == expected
