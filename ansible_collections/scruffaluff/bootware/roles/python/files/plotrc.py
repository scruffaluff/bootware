"""Python plotting utilities."""

from __future__ import annotations

import dataclasses
import functools
import importlib
import inspect
import itertools
import subprocess
import sys
from collections.abc import Sequence
from typing import TYPE_CHECKING, Any, Self

if TYPE_CHECKING:
    from types import ModuleType

Array = Sequence[float]


@dataclasses.dataclass
class Range:
    """Plot axis range with support for expanding bounds."""

    start: float = float("inf")
    stop: float = float("-inf")
    fixed: bool = False

    def __iadd__(self, other: tuple[float, float]) -> Self:
        """Expand bounds if necessary."""
        if not self.fixed:
            self.start = min(other[0], self.start)
            self.stop = max(other[1], self.stop)
        return self

    def valid(self) -> bool:
        """Check if bounds are valid."""
        return self.start < self.stop


@functools.cache
def import_libraries(*names: str) -> ModuleType | tuple[ModuleType]:
    """Import library and install if necessary."""
    libraries = []
    for name in names:
        try:
            library = importlib.import_module(name)
        except ModuleNotFoundError:
            package = library.split(".")[0]
            subprocess.run([sys.executable, "-m", "ensurepip"], check=True)
            subprocess.run(
                [sys.executable, "-m", "pip", "install", package], check=True
            )
            library = importlib.import_module(name)
        libraries.append(library)
    if len(libraries) == 1:
        return libraries[0]
    return tuple(libraries)


def line(
    *signals: Array, overlay: bool = True, x: Array | None = None, **kwargs: Any
) -> None:
    """Plot line with Matplotlib."""
    numpy = import_libraries("numpy")

    palette = palette_cycle()
    x_range, y_range = Range(), Range()
    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]

    for index, signal in enumerate(signals):
        color = next(palette)
        y = numpy.asarray(signal).ravel()
        x = x or numpy.arange(len(y))
        x_range += (x[0], x[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x, y, color=color, label=var_name(signal))
        axis.set_title(kwargs.pop("title", None))
        axis.legend()

    for axis in axes:
        if x_range.valid():
            axis.set_xlim(x_range.start, x_range.stop)
        if y_range.valid():
            axis.set_ylim(y_range.start, y_range.stop)
    figure.show()


def palette_cycle() -> itertools.cycle:
    """Create a cycle of colors for plotting."""
    return itertools.cycle(
        (
            "#1f77b4",
            "#ff7f0e",
            "#2ca02c",
            "#d62728",
            "#9467bd",
            "#8c564b",
            "#e377c2",
            "#7f7f7f",
            "#bcbd22",
            "#17becf",
        )
    )


def subplots(*args: Any, **kwargs: Any) -> tuple[Any, Any]:
    """Wrapper for Matplotlib subplots."""
    pyplot = import_libraries("matplotlib.pyplot")
    return pyplot.subplots(*args, figsize=(12, 6), layout="compressed", **kwargs)


def var_name(var: Any) -> str:  # noqa: ANN401
    """Trace variable name in calling scope."""
    vars_ = inspect.currentframe().f_back.f_back.f_locals.items()
    return next(name for name, value in vars_ if value is var)
