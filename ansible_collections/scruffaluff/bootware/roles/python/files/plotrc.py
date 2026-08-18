"""Python plotting utilities."""

# Explicit optional, union, and quoted types are used to support older Python versions.
# ruff: noqa: PLR0913, PYI034, UP007, UP037, UP045

from __future__ import annotations

import builtins
import dataclasses
import itertools
from enum import Enum
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


class Scale(Enum):
    """Signal amplitude scale."""

    Decibel = "decibel"
    FullScale = "fullscale"
    Linear = "linear"
    Normalized = "normalized"

    def __call__(self, array: Array) -> Array:
        """Transform array to scale."""
        if self == Scale.Decibel:
            return pyrc.decibel(array)
        if self == Scale.FullScale:
            return pyrc.decibel(pyrc.normalize(array))
        if self == Scale.Normalized:
            return pyrc.normalize(array)
        return array

    def __str__(self) -> str:
        """Get string representation."""
        return self.value

    def axis(self) -> str:
        """Get axis scale."""
        return {
            Scale.Decibel: "log",
            Scale.FullScale: "log",
            Scale.Linear: "linear",
            Scale.Normalized: "linear",
        }[self]

    @classmethod
    def from_prefix(cls, value: Union[str, "Scale"]) -> "Scale":
        """Create Scale instance from value prefix."""
        if isinstance(value, Scale):
            return value

        value_ = value.lower()
        if "decibel".startswith(value_) or value_ == "db":
            return cls.Decibel
        if "fullscale".startswith(value_) or value_ == "dbfs":
            return cls.FullScale
        if "linear".startswith(value_):
            return cls.Linear
        if "normalized".startswith(value_):
            return cls.Normalized
        msg = f"Invalid scale value '{value}'"
        raise ValueError(msg)

    def unit(self) -> str:
        """Get plot axis label unit."""
        return {
            Scale.Decibel: " (dB)",
            Scale.FullScale: " (dBFS)",
            Scale.Linear: "",
            Scale.Normalized: "",
        }[self]


@no_type_check
def export() -> None:
    """Add functions to global scope."""
    builtins.pfreq = frequency
    builtins.pgrid = grid
    builtins.pline = line
    builtins.phase = phase
    builtins.pspec = spectrogram
    builtins.pwave = waveform


def frequency(
    *signals: Signal,
    axes: Optional[list[Any]] = None,
    depth: int = 3,
    overlay: bool = True,
    rate: Optional[int] = None,
    scale: Scale = Scale.Linear,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency spectrum."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    overlay = kwargs.pop("o", overlay)
    rate = kwargs.pop("r", rate)
    scale = Scale.from_prefix(kwargs.pop("s", scale))

    if axes is None:
        _, axes = subplots(
            ncols=1 if overlay else len(signals),
            squeeze=False,
            title=pyrc.popall(kwargs, ["title", "t"], None),
        )
        axes = axes[0]
    axes[0].set_ylabel(f"Level{scale.unit()}")
    ticks = spectrum_ticks()
    x_range, y_range = Range(20, 20_000, True), Range()
    datas = sigdata(signals, x=x, depth=depth)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        y = scale(numpy.abs(numpy.fft.rfft(data["y"])))
        x_ = data.pop("x", numpy.fft.rfftfreq(len(data["y"]), 1 / rate_))
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, y, color=data["color"], label=data["label"])
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.set_yscale(scale.axis())
        axis.legend(loc="upper right")
        axis.minorticks_off()

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)


def grid(
    *signals: Signal,
    plots: list[str] | None = None,
    overlay: bool = True,
    rate: Optional[int] = None,
    scale: Scale = Scale.Linear,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot multiple graphs vertically in a grid."""
    pyplot = dyport("matplotlib.pyplot")
    overlay = kwargs.pop("o", overlay)
    plots = plots or kwargs.pop("p", ["frequency", "phase"])
    rate = kwargs.pop("r", rate)
    scale = Scale.from_prefix(kwargs.pop("s", scale))

    _, axes = subplots(
        nrows=len(plots),
        ncols=1 if overlay else len(signals),
        squeeze=False,
        title=pyrc.popall(kwargs, ["title", "t"], None),
    )
    for idx, plot in enumerate(plots):
        if "line".startswith(plot):
            line(
                *signals,
                axes=axes[idx],
                depth=4,
                overlay=overlay,
                scale=scale,
                show=False,
                x=x,
                **kwargs,
            )
        elif "frequency".startswith(plot):
            frequency(
                *signals,
                axes=axes[idx],
                depth=4,
                overlay=overlay,
                rate=rate,
                scale=scale,
                show=False,
                x=x,
                **kwargs,
            )
        elif "phase".startswith(plot):
            phase(
                *signals,
                axes=axes[idx],
                depth=4,
                overlay=overlay,
                rate=rate,
                show=False,
                x=x,
                **kwargs,
            )
        elif "spectrogram".startswith(plot):
            spectrogram(
                *signals, axes=axes[idx], depth=4, rate=rate, show=False, **kwargs
            )
        elif "waveform".startswith(plot):
            waveform(
                *signals,
                axes=axes[idx],
                depth=4,
                overlay=overlay,
                rate=rate,
                scale=scale,
                show=False,
                x=x,
                **kwargs,
            )
        else:
            msg = f"Unknown plot type '{plot}'."
            raise ValueError(msg)

    if show:
        pyplot.show(block=True)


def line(
    *signals: Signal,
    axes: Optional[list[Any]] = None,
    depth: int = 3,
    overlay: bool = True,
    scale: Scale = Scale.Linear,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot line."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    overlay = kwargs.pop("o", overlay)
    scale = Scale.from_prefix(kwargs.pop("s", scale))

    if axes is None:
        _, axes = subplots(
            ncols=1 if overlay else len(signals),
            squeeze=False,
            title=pyrc.popall(kwargs, ["title", "t"], None),
        )
        axes = axes[0]
    x_range, y_range = Range(), Range()
    datas = sigdata(signals, x=x, depth=depth)

    for index, data in enumerate(datas):
        x_ = data.pop("x", numpy.arange(len(data["y"])))
        y = scale(data["y"])
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, data["y"], color=data["color"], label=data["label"])
        axis.set_yscale(scale.axis())
        axis.legend(loc="upper right")

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)


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
    axes: Optional[list[Any]] = None,
    depth: int = 3,
    overlay: bool = True,
    rate: Optional[int] = None,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio frequency phase."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    overlay = kwargs.pop("o", overlay)
    rate = kwargs.pop("r", rate)

    if axes is None:
        _, axes = subplots(
            ncols=1 if overlay else len(signals),
            squeeze=False,
            title=pyrc.popall(kwargs, ["title", "t"], None),
        )
        axes = axes[0]
    axes[0].set_ylabel("Phase (rad)")
    ticks = spectrum_ticks()
    x_range, y_range = Range(20, 20_000, True), Range()
    datas = sigdata(signals, x=x, depth=depth)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        y = numpy.unwrap(numpy.angle(numpy.fft.rfft(data["y"])))
        x_ = data.pop("x", numpy.fft.rfftfreq(len(data["y"]), 1 / rate_))
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, y, color=data["color"], label=data["label"])
        axis.legend(loc="upper right")
        axis.set_xlabel("Frequency (Hz)")
        axis.set_xscale("log")
        axis.set_xticks(ticks[0])
        axis.set_xticklabels(ticks[1])
        axis.minorticks_off()

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)


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
    depth: int = 3,
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
                signal, ["label", "l"], pyrc.varname(signal, str(index), depth=depth)
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
                "label": pyrc.varname(signal, str(index), depth=depth),
            }
        else:
            y = mono(numpy.asarray(signal))
            data = {
                "y": y,
                "color": next(palette),
                "label": pyrc.varname(signal, str(index), depth=depth),
            }
            if x is not None:
                data["x"] = mono(numpy.asarray(x))
        datas.append(data)
    return datas


def spectrogram(
    *signals: Signal,
    axes: Optional[list[Any]] = None,
    depth: int = 3,
    rate: Optional[int] = None,
    show: bool = True,
    **kwargs: Any,
) -> None:
    """Plot audio frequency time heatmap with Matplotlib."""
    numpy, pyplot, signal = (
        dyport("numpy"),
        dyport("matplotlib.pyplot"),
        dyport("scipy.signal"),
    )
    rate = kwargs.pop("r", rate)

    if axes is None:
        _, axis = subplots(
            ncols=1,
            squeeze=True,
            title=pyrc.popall(kwargs, ["title", "t"], None),
        )
    else:
        axis = axes[0]
    axis.set_ylabel("Frequency (Hz)")
    ticks = spectrum_ticks()
    x_range, y_range = Range(), Range(20, 20_000, True)
    datas = sigdata(signals, depth=depth)

    for data in datas:
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
        z = pyrc.decibel(numpy.abs(z_))
        x_range += (x.min(), x.max())
        y_range += (y.min(), y.max())

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

    set_ranges([axis], x_range, y_range)
    axis.figure.colorbar(mesh, ax=axes, label="Level (dB)")
    if show:
        pyplot.show(block=True)


def spectrum_ticks() -> tuple[list[float], list[str]]:
    """Generate frequency spectrum plot ticks as octaves centered at 440Hz."""
    numpy = dyport("numpy")

    ticks = 440 * 2.0 ** numpy.arange(-4, 6)
    labels = [f"{tick:g}" if tick < 1_000 else f"{tick / 1_000:g}k" for tick in ticks]
    return ticks.tolist(), labels


def subplots(*args: Any, title: Optional[str] = None, **kwargs: Any) -> tuple[Any, Any]:
    """Wrapper for Matplotlib subplots."""
    pyplot = dyport("matplotlib.pyplot")
    figure, axes = pyplot.subplots(
        *args, figsize=(12, 6), layout="compressed", **kwargs
    )
    if title is not None:
        figure.suptitle(title)
    return figure, axes


def waveform(
    *signals: Signal,
    axes: Optional[list[Any]] = None,
    depth: int = 3,
    overlay: bool = True,
    rate: Optional[int] = None,
    scale: Scale = Scale.Linear,
    show: bool = True,
    x: Optional[Array] = None,
    **kwargs: Any,
) -> None:
    """Plot audio waveform."""
    numpy, pyplot = dyport("numpy"), dyport("matplotlib.pyplot")
    overlay = kwargs.pop("o", overlay)
    rate = kwargs.pop("r", rate)
    scale = Scale.from_prefix(kwargs.pop("s", scale))

    if axes is None:
        _, axes = subplots(
            ncols=1 if overlay else len(signals),
            squeeze=False,
            title=pyrc.popall(kwargs, ["title", "t"], None),
        )
        axes = axes[0]
    axes[0].set_ylabel(f"Amplitude{scale.unit()}")
    x_range, y_range = Range(), Range(-1, 1, True)
    datas = sigdata(signals, x=x, depth=depth)

    for index, data in enumerate(datas):
        rate_ = rate or data.pop("rate", len(data["y"]))
        x_ = data.pop("x", numpy.linspace(0, len(data["y"]) / rate_, len(data["y"])))
        y = scale(data["y"])
        x_range += (x_[0], x_[-1])
        y_range += (y.min(), y.max())

        axis = axes[0 if overlay else index]
        axis.plot(x_, y, color=data["color"], label=data["label"])
        axis.set_xlabel("Time (s)")
        axis.set_yscale(scale.axis())
        axis.legend(loc="upper right")

    set_ranges(axes, x_range, y_range)
    if show:
        pyplot.show(block=True)
