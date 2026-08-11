"""Python plotting utilities."""

# Explicit optional, union, and quoted types are used to support older Python versions.
# ruff: noqa: ANN401, PYI034, UP007, UP037, UP045

from __future__ import annotations

import builtins
import dataclasses
import itertools
from typing import TYPE_CHECKING, Any, Optional, Union, cast, no_type_check

import pyrc
from pyrc import Array, dyport

if TYPE_CHECKING:
    from collections.abc import Iterable

Signal = Union[Array, tuple[Array, Array], dict[str, Any]]


@dataclasses.dataclass
class Range:
    """Plot axis range with support for expanding bounds."""

    start: float = float("inf")
    stop: float = float("-inf")
    fixed: bool = False

    def __iadd__(self, other: tuple[float, float]) -> "Range":
        """Expand bounds if necessary."""
        if not self.fixed:
            self.start = min(other[0], self.start)
            self.stop = max(other[1], self.stop)
        return self

    def valid(self) -> bool:
        """Check if bounds are valid."""
        return self.start < self.stop


def bode(
    *signals: Signal,
    overlay: bool = True,
    rate: Optional[int] = None,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency magnitude and phase."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    figure, axes = subplots(
        ncols=1 if overlay else len(signals), nrows=2, squeeze=False
    )
    axes[0][0].set_ylabel("Volume (dB)")
    axes[1][0].set_ylabel("Phase (rad)")
    x_range, freq_range, phase_range = Range(20, 20_000, True), Range(), Range()
    ticks = spectrum_ticks()
    datas = sigdata(signals, x=x)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        fft = numpy.fft.rfft(data["y"])
        freq = numpy.abs(fft)
        phase = numpy.unwrap(numpy.angle(fft))
        x_ = data.pop("x", numpy.fft.rfftfreq(len(data["y"]), 1 / rate_))
        x_range += (x_[0], x_[-1])

        freq_range += (freq.min(), freq.max())
        phase_range += (phase.min(), phase.max())
        axis = axes[0][0 if overlay else index]
        axis.plot(x_, freq, color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.legend(loc="upper right")
        axis.minorticks_off()

        axis = axes[1][0 if overlay else index]
        axis.plot(x_, phase, color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.legend(loc="upper right")
        axis.minorticks_off()

    set_ranges(axes[0], x_range, freq_range)
    set_ranges(axes[1], x_range, phase_range)
    if show:
        pyplot.show(block=True)
    return figure


@no_type_check
def export() -> None:
    """Add functions to global scope."""
    builtins.pbode = bode
    builtins.pfreq = spectrum
    builtins.pline = line
    builtins.phase = phase
    builtins.pspec = spectrogram
    builtins.pwave = waveform


def line(
    *signals: Signal,
    overlay: bool = True,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> Any:
    """Plot line."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    x_range, y_range = Range(), Range()
    datas = sigdata(signals, x=x)

    for index, data in enumerate(datas):
        x_ = data.pop("x", numpy.arange(len(data["y"])))
        x_range += (x_[0], x_[-1])
        y_range += (data["y"].min(), data["y"].max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, data["y"], color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.legend(loc="upper right")

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
    return figure


@no_type_check
def mono(array: Array) -> Array:
    """Average 2 dimensional array into 1 dimension."""
    if array.ndim == 1:
        return array
    if array.shape[0] < array.shape[1]:
        return array.mean(axis=0)
    return array.mean(axis=1)


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
    *signals: Signal,
    overlay: bool = True,
    rate: Optional[int] = None,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency phase."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Phase (rad)")
    ticks = spectrum_ticks()
    x_range, y_range = Range(20, 20_000, True), Range()
    datas = sigdata(signals, x=x)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        y = numpy.unwrap(numpy.angle(numpy.fft.rfft(data["y"])))
        x_ = data.pop("x", numpy.fft.rfftfreq(len(data["y"]), 1 / rate_))
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, y, color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.legend(loc="upper right")
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
    signals: Iterable[Signal],
    x: Optional[Array] = None,
) -> list[dict[str, Any]]:
    """Convert signal into standardized format."""
    numpy = dyport("numpy")
    palette = palette_cycle()

    datas = []
    for index, signal in enumerate(signals):
        if isinstance(signal, dict):
            signal = cast("dict[str, Any]", signal)
            y = mono(numpy.asarray(signal.pop("y")))
            x_ = signal.pop("x", x)
            color = pyrc.popall(signal, ["color", "c"], next(palette))
            label = pyrc.popall(
                signal, ["label", "l"], pyrc.varname(signal, str(index), depth=3)
            )
            data = {
                **signal,
                "y": y,
                "color": color,
                "label": label,
            }
            if x_ is not None:
                data["x"] = mono(numpy.asarray(x_))
        elif isinstance(signal, tuple):
            signal = cast("tuple[Array, Array]", signal)
            x_, y = signal
            data = {
                "x": mono(numpy.asarray(x_)),
                "y": mono(numpy.asarray(y)),
                "color": next(palette),
                "label": pyrc.varname(signal, str(index), depth=3),
            }
        else:
            y = mono(numpy.asarray(signal))
            data = {
                "y": y,
                "color": next(palette),
                "label": pyrc.varname(signal, str(index), depth=3),
            }
            if x is not None:
                data["x"] = mono(numpy.asarray(x))
        datas.append(data)
    return datas


def spectrogram(
    *signals: Signal, rate: Optional[int] = None, show: bool = True, **kwargs: Any
) -> Any:
    """Plot audio frequency time heatmap with Matplotlib."""
    numpy, pyplot, signal = (
        dyport("numpy"),
        dyport("matplotlib.pyplot"),
        dyport("scipy.signal"),
    )
    rate = rate or kwargs.pop("r", None)

    figure, axes = subplots(ncols=len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Frequency (Hz)")
    ticks = spectrum_ticks()
    x_range, y_range = Range(), Range(20, 20_000, True)
    datas = sigdata(signals)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        transform = signal.ShortTimeFFT.from_window(
            ("gaussian", 1e-2 * rate_),
            fft_mode="onesided",
            fs=rate_,
            noverlap=64,
            nperseg=512,
        )
        bounds = transform.extent(len(data["y"]), center_bins=True)

        z_ = transform.stft(data["y"])
        x = numpy.linspace(bounds[0], bounds[1], num=z_.shape[1])
        y = numpy.linspace(bounds[2], bounds[3], num=z_.shape[0])
        z = pyrc.decibel(z_)
        x_range += (x.min(), x.max())
        y_range += (y.min(), y.max())

        axis = axes[index]
        mesh = axis.pcolormesh(
            x,
            y,
            z,
            antialiased=True,
            cmap="viridis",
            shading="auto",
        )
        axis.set_xlabel("Time (s)")
        axis.set_yscale("log")
        axis.set_yticks(ticks[0])
        axis.set_yticklabels(ticks[1])

    set_ranges(axes, x_range, y_range)
    figure.colorbar(mesh, ax=axes, label="Volume (dB)")
    if show:
        pyplot.show(block=True)
    return figure


def spectrum(
    *signals: Signal,
    overlay: bool = True,
    rate: Optional[int] = None,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency spectrum."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Volume (dB)")
    ticks = spectrum_ticks()
    x_range, y_range = Range(20, 20_000, True), Range()
    datas = sigdata(signals, x=x)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        y = numpy.abs(numpy.fft.rfft(data["y"]))
        x_ = data.pop("x", numpy.fft.rfftfreq(len(data["y"]), 1 / rate_))
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, y, color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.legend(loc="upper right")
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


def waveform(
    *signals: Signal,
    overlay: bool = True,
    rate: Optional[int] = None,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio waveform."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    rate = rate or kwargs.pop("r", None)

    figure, axes = subplots(ncols=1 if overlay else len(signals), squeeze=False)
    axes = axes[0]
    axes[0].set_ylabel("Amplitude")
    x_range, y_range = Range(), Range(-1, 1, True)
    datas = sigdata(signals, x=x)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        x_ = data.pop("x", numpy.linspace(0, len(data["y"]) / rate_, len(data["y"])))
        x_range += (x_[0], x_[-1])
        y_range += (data["y"].min(), data["y"].max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, data["y"], color=data["color"], label=data["label"])
        axis.set_title(pyrc.popall(kwargs, ["title", "t"], None))
        axis.set_xlabel("Time (s)")
        axis.legend(loc="upper right")

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
    return figure
