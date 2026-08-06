"""Python plotting utilities."""

# ruff: noqa: ANN401

from __future__ import annotations

import dataclasses
import inspect
import itertools
from collections.abc import Iterable, Sequence
from typing import Any, cast

import pyrc
from pyrc import dyport

Array = Sequence[float]
Signal = Array | tuple[Array, Array] | dict[str, Any]


@dataclasses.dataclass
class Range:
    """Plot axis range with support for expanding bounds."""

    start: float = float("inf")
    stop: float = float("-inf")
    fixed: bool = False

    # Quoted return type is used instead of Self to support older Python
    # versions, such as LLDB's 3.9.
    def __iadd__(self, other: tuple[float, float]) -> "Range":  # noqa: PYI034, UP037
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
    numpy = dyport("numpy")

    epsilon = numpy.finfo(signal.dtype).eps
    amplitude = numpy.maximum(numpy.abs(signal), epsilon)
    return 20 * numpy.log10(amplitude)


def flatten(array: Array) -> Array:
    """Convert array to one dimensional form."""
    if array.ndim > 1:
        return array.mean(axis=0)
    return array


def line(
    *signals: Signal,
    overlay: bool = True,
    show: bool = True,
    x: Array | None = None,
    **kwargs: Any,
) -> Any:
    """Plot line."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")

    datas = sigdata(signals, x=x)
    x_range, y_range = Range(), Range()
    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]

    for index, data in enumerate(datas):
        x_ = data.pop("x") or numpy.arange(len(data["y"]))
        x_range += (x_[0], x_[-1])
        y_range += (data["y"].min(), data["y"].max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, data["y"], color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.legend()

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
    return figure


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
    show: bool = True,
    x: Array | None = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency phase."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    datas = sigdata(signals, x=x)
    x_range, y_range = Range(20, 20_000, True), Range()
    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Phase (rad)")
    ticks = spectrum_ticks()

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate")
        y = numpy.unwrap(numpy.angle(numpy.fft.rfft(data["y"])))
        x_ = data.pop("x") or numpy.fft.rfftfreq(len(data["y"]), 1 / rate_)
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, data["y"], color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.minorticks_off()

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
    return figure


def set_ranges(axes: Iterable[Any], x_range: Range, y_range: Range) -> None:
    """Set ranges for axes if valid."""
    for axis in axes:
        if x_range.valid():
            axis.set_xlim(x_range.start, x_range.stop)
        if y_range.valid():
            axis.set_ylim(y_range.start, y_range.stop)


def sigdata(
    signals: Iterable[Array | tuple[Array, Array] | dict[str, Any]],
    x: Array | None = None,
) -> list[dict[str, Any]]:
    """Convert signal into standardized format."""
    numpy = dyport("numpy")
    palette = palette_cycle()

    datas = []
    for index, signal in enumerate(signals):
        if isinstance(signal, dict):
            signal = cast("dict[str, Any]", signal)
            y = numpy.asarray(signal.pop("y")).ravel()
            x_ = signal.pop("x", x)
            x_ = x_ if x_ is None else numpy.asarray(x).ravel()
            color = pyrc.popall(signal, ["color", "c"], next(palette))
            label = pyrc.popall(signal, ["label", "l"], var_name(signal, str(index)))
            data = {
                **signal,
                "x": x_,
                "y": y,
                "color": color,
                "label": label,
            }
        elif isinstance(signal, tuple):
            signal = cast("tuple[Array, Array]", signal)
            x_, y = signal
            data = {
                "x": numpy.asarray(x_).ravel(),
                "y": numpy.asarray(y).ravel(),
                "color": next(palette),
                "label": var_name(signal, str(index)),
            }
        else:
            y = numpy.asarray(signal).ravel()
            x_ = x if x is None else numpy.asarray(x).ravel()
            data = {
                "x": x_,
                "y": y,
                "color": next(palette),
                "label": var_name(signal, str(index)),
            }
        datas.append(data)
    return datas


def spectrum(
    *signals: Array | dict[str, Any],
    overlay: bool = True,
    rate: int | None = None,
    show: bool = True,
    x: Array | None = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency spectrum."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    datas = sigdata(signals, x=x)
    x_range, y_range = Range(20, 20_000, True), Range()
    ticks = spectrum_ticks()
    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Volume (dB)")

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate")
        y = numpy.fft.rfft(data["y"])
        x_ = data.pop("x") or numpy.fft.rfftfreq(len(data["y"]), 1 / rate_)
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, y, color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.legend()
        axis.minorticks_off()

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
    return figure


def spectrum_ticks() -> tuple[list[float], list[str]]:
    """Generate frequency spectrum plot ticks as octaves centered at 440Hz."""
    numpy = dyport("numpy")

    ticks = 440 * 2.0 ** numpy.arange(-4, 6)
    labels = [f"{tick:g}" if tick < 1_000 else f"{tick / 1_000:g}k" for tick in ticks]
    return ticks.tolist(), labels


def subplots(*args: Any, **kwargs: Any) -> tuple[Any, Any]:
    """Wrapper for Matplotlib subplots."""
    pyplot = dyport("matplotlib.pyplot")
    return pyplot.subplots(*args, figsize=(12, 6), layout="compressed", **kwargs)


def var_name(var: Any, default: str = "") -> str:
    """Trace variable name in calling scope."""
    vars_ = inspect.currentframe().f_back.f_back.f_locals.items()
    try:
        return next(name for name, value in vars_ if value is var)
    except StopIteration:
        return default


def waveform(
    *signals: Signal,
    overlay: bool = True,
    rate: int | None = None,
    show: bool = True,
    x: Array | None = None,
    **kwargs: Any,
) -> None:
    """Plot audio waveform."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    datas = sigdata(signals, x=x)
    x_range, y_range = Range(), Range(-1, 1, True)
    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Amplitude")

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate")
        x_ = data.pop("x") or numpy.linspace(0, len(data["y"]) / rate_, len(data["y"]))
        x_range += (x_[0], x_[-1])
        y_range += (data["y"].min(), data["y"].max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, data["y"], color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xlabel("Time (s)")
        axis.legend()

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
    return figure
