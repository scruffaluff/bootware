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
from typing import TYPE_CHECKING, Any, Self, cast

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


def decibel(signal: Array) -> Array:
    """Convert signal to decibels.

    Avoids passing zeros to log10 by replacing them with the datatype epsilon.
    """
    numpy = import_libraries("numpy")

    epsilon = numpy.finfo(signal.dtype).eps
    amplitude = numpy.maximum(numpy.abs(signal), epsilon)
    return 20 * numpy.log10(amplitude)


def flatten(array: Array) -> Array:
    """Convert array to one dimensional form."""
    if array.ndim > 1:
        return array.mean(axis=0)
    return array


@functools.cache
def import_libraries(*names: str) -> ModuleType | tuple[ModuleType]:
    """Import library and install if necessary."""
    libraries = []
    for name in names:
        try:
            library = importlib.import_module(name)
        except ModuleNotFoundError:
            package = name.split(".")[0]
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
    """Plot line."""
    numpy = import_libraries("numpy")

    palette = palette_cycle()
    x_range, y_range = Range(), Range()
    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]

    for index, signal in enumerate(signals):
        if isinstance(signal, dict):
            signal = cast("dict[str, Any]", signal)
            color = signal.pop("color", next(palette))
            label = signal.pop("label", None)
        else:
            color = next(palette)
            label = var_name(signal)

        y = numpy.asarray(signal)
        x = numpy.arange(len(y)) if x is None else numpy.asarray(x)
        x_range += (x[0], x[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x, y, color=color, label=label)
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


def phase(
    *signals: Array | dict[str, Any],
    overlay: bool = True,
    rate: int | None = None,
    x: Array | None = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency phase."""
    palette = palette_cycle()
    x_range, y_range = Range(), Range(20, 20_000)

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Phase (rad)")
    ticks = spectrum_ticks()

    for index, signal in enumerate(signals):
        if isinstance(signal, dict):
            signal = cast("dict[str, Any]", signal)
            color = signal.pop("color", next(palette))
            label = signal.pop("label", None)
        else:
            color = next(palette)
            label = var_name(signal)

        x, y = signal_phase(signal, rate, x)
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x, y, color=color, label=label)
        axis.set_title(kwargs.pop("title", None))
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.minorticks_off()

    for axis in axes:
        if x_range.valid():
            axis.set_xlim(x_range.start, x_range.stop)
        if y_range.valid():
            axis.set_ylim(y_range.start, y_range.stop)
    figure.show()


def signal_phase(
    signal: Array | dict[str, Any], rate: int | None = None, x: Array | None = None
) -> tuple[Array, Array]:
    """Extract frequency phase from signal dictionary."""
    numpy = import_libraries("numpy")

    if isinstance(signal, dict):
        signal = cast("dict[str, Any]", signal)
        if "f" in signal:
            y = signal.pop("f")
        else:
            y_ = signal.pop("y")
            y = numpy.unwrap(numpy.angle(numpy.fft.rfft(y_)))

        if "x" in signal:
            x = signal.pop("x")
        elif x is None:
            length = 2 * (len(y) - 1)
            rate = signal.pop("rate") if rate is None else rate
            x = numpy.fft.rfftfreq(length, 1 / rate)
        else:
            x = numpy.asarray(x)
    else:
        y = numpy.asarray(signal)
        x = numpy.arange(len(y)) if x is None else numpy.asarray(x)

    return flatten(x), flatten(y)


def signal_spectrum(
    signal: Array | dict[str, Any],
    rate: int | None = None,
    x: Array | None = None,
) -> tuple[Array, Array]:
    """Extract frequency spectrum from signal dictionary."""
    numpy = import_libraries("numpy")

    if isinstance(signal, dict):
        signal = cast("dict[str, Any]", signal)
        y = signal.pop("f") if "f" in signal else numpy.fft.rfft(signal.pop("y"))
        if "x" in signal:
            x = signal.pop("x")
        elif x is None:
            length = 2 * (len(y) - 1)
            rate = signal.pop("rate") if rate is None else rate
            x = numpy.fft.rfftfreq(length, 1 / rate)
        else:
            x = numpy.asarray(x)
    else:
        y = numpy.fft.rfft(numpy.asarray(signal))
        x = numpy.arange(len(y)) if x is None else numpy.asarray(x)

    return flatten(x), flatten(y)


def signal_waveform(
    signal: Array | dict[str, Any],
    rate: int | None = None,
    x: Array | None = None,
) -> tuple[Array, Array]:
    """Extract waveform from signal dictionary."""
    numpy = import_libraries("numpy")

    if isinstance(signal, dict):
        signal = cast("dict[str, Any]", signal)
        y = signal.pop("y")
        if "x" in signal:
            x = numpy.asarray(signal.pop("x"))
        else:
            rate = signal.pop("rate") if rate is None else rate
            x = (
                numpy.linspace(0, len(y) / rate, len(y))
                if x is None
                else numpy.asarray(x)
            )
    else:
        y = numpy.asarray(signal)
        x = numpy.arange(len(y)) if x is None else numpy.asarray(x)

    return flatten(x), flatten(y)


def spectrum(
    *signals: Array | dict[str, Any],
    overlay: bool = True,
    rate: int | None = None,
    x: Array | None = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency spectrum."""
    palette = palette_cycle()
    ticks = spectrum_ticks()
    x_range, y_range = Range(), Range(20, 20_000, True)

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Volume (dB)")

    for index, signal in enumerate(signals):
        if isinstance(signal, dict):
            signal = cast("dict[str, Any]", signal)
            color = signal.pop("color", next(palette))
            label = signal.pop("label", None)
        else:
            color = next(palette)
            label = var_name(signal)

        x, y = signal_spectrum(signal, rate, x)
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x, y, color=color, label=label)
        axis.set_title(kwargs.pop("title", None))
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.legend()
        axis.minorticks_off()

    for axis in axes:
        if x_range.valid():
            axis.set_xlim(x_range.start, x_range.stop)
        if y_range.valid():
            axis.set_ylim(y_range.start, y_range.stop)
    figure.show()


def spectrum_ticks() -> tuple[list[float], list[str]]:
    """Generate frequency spectrum plot ticks as octaves centered at 440Hz."""
    numpy = import_libraries("numpy")

    ticks = 440 * 2.0 ** numpy.arange(-4, 6)
    labels = [f"{tick:g}" if tick < 1_000 else f"{tick / 1_000:g}k" for tick in ticks]
    return ticks.tolist(), labels


def subplots(*args: Any, **kwargs: Any) -> tuple[Any, Any]:
    """Wrapper for Matplotlib subplots."""
    pyplot = import_libraries("matplotlib.pyplot")
    return pyplot.subplots(*args, figsize=(12, 6), layout="compressed", **kwargs)


def var_name(var: Any) -> str:  # noqa: ANN401
    """Trace variable name in calling scope."""
    vars_ = inspect.currentframe().f_back.f_back.f_locals.items()
    return next(name for name, value in vars_ if value is var)


def waveform(
    *signals: Array | dict[str, Any],
    overlay: bool = True,
    rate: int | None = None,
    x: Array | None = None,
    **kwargs: Any,
) -> None:
    """Plot audio waveform."""
    palette = palette_cycle()
    x_range, y_range = Range(), Range(-1, 1, True)

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Amplitude")

    for index, signal in enumerate(signals):
        if isinstance(signal, dict):
            signal = cast("dict[str, Any]", signal)
            color = signal.pop("color", next(palette))
            label = signal.pop("label", None)
        else:
            color = next(palette)
            label = var_name(signal)

        x, y = signal_waveform(signal, rate, x)
        x_range += (x[0], x[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x, y, color=color, label=label)
        axis.set_title(kwargs.pop("title", None))
        axis.set_xlabel("Time (s)")
        axis.legend()

    for axis in axes:
        if x_range.valid():
            axis.set_xlim(x_range.start, x_range.stop)
        if y_range.valid():
            axis.set_ylim(y_range.start, y_range.stop)
    figure.show()
