"""Custom utilities for Python.

For more information, visit https://docs.python.org/3/library/site.html.
"""

import builtins

import plotrc
import pyrc

builtins.aplay = pyrc.aplay
builtins.arec = pyrc.arec
builtins.dyport = pyrc.dyport
builtins.pline = plotrc.line
builtins.pphase = plotrc.phase
builtins.pspec = plotrc.spectrum
builtins.pwave = plotrc.waveform
builtins.plotrc = plotrc
builtins.pyrc = pyrc
