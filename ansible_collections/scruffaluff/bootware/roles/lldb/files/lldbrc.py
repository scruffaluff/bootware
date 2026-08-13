"""LLDB settings script."""

# ruff: noqa: ANN401, ARG001

from __future__ import annotations

import pprint
import re
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, Any

from lldb import (
    SBCommandReturnObject,
    SBDebugger,
    SBExecutionContext,
    SBFrame,
    SBValue,
    eReturnStatusFailed,
)

import plotrc
import pyrc
from pyrc import Parser

if TYPE_CHECKING:
    from collections.abc import Callable


CPP_INT_RE = (
    r"((un)?signed\s+)?(short\s+|(long\s+){1,2})?int"
    r"|u?int\d+_(fast_|least_)?t|ptrdiff_t|s?size_t"
)
CPP_FLT_RE = r"float|(long\s+)?double|b?float\d+_t"
CPP_NUL_RE = r"std::nullptr_t"
CPP_STR_RE = (
    r"char\[\d+\]|const char \*"
    r"|std::([\w:]+::)?(u\d+)?string(_type|_view)?"
)
CPP_WRP_RE = r"std::([\w:]+::)filesystem::path|.*&"
CPP_ARR_RE = (
    f"({CPP_INT_RE}|{CPP_FLT_RE})\\[\\d+\\]"
    r"|std::([\w:]+::)?(array|deque|list|vector).*"
)
RS_INT_RE = r"(i|u)\d+"
RS_FLT_RE = r"f\d+"
RS_NUL_RE = r"\(\)"
RS_STR_RE = r"&?(str|std::path::Path(Buf)?|([\w:]+::)?(Os)?String)|unsigned char \*"
RS_WRP_RE = r"alloc::boxed::Box.*|.*\*"
RS_ARR_RE = (
    f"&?\\[({RS_INT_RE}|{RS_FLT_RE})\\]"
    r"|(alloc|core|std)::([\w:]+::)?(Slice|Vec|VecDeque).*"
)


def cmd_nushell(
    debugger: SBDebugger,
    command: str,
    exe_ctx: SBExecutionContext,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Execute Nushell expression or start interactive session."""
    frame = curframe(debugger)
    line = pyrc.parse_exprs(var_lookup(frame), command)
    parser = Parser()
    parser.add_argument("-c", "--cwd", default=None)
    cmd, args = parser.parse_line(line)
    try:
        pyrc.nushell(cmd, cwd=args.cwd)
    except (CalledProcessError, FileNotFoundError) as exception:
        result.SetError(str(exception))
        result.SetStatus(eReturnStatusFailed)


def cmd_py(
    debugger: SBDebugger,
    command: str,
    exe_ctx: SBExecutionContext,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Execute Python expression with frame variables."""
    frame = curframe(debugger)
    try:
        eval(  # noqa: S307
            command,
            {
                "aplay": pyrc.aplay,
                "arec": pyrc.arec,
                "cat": pyrc.cat,
                "decibel": pyrc.decibel,
                "doc": pyrc.doc,
                "dyport": pyrc.dyport,
                "edit": pyrc.edit,
                "normalize": pyrc.normalize,
                "nushell": pyrc.nushell,
                "page": pyrc.page,
                "pfreq": plotrc.frequency,
                "pgrid": plotrc.grid,
                "phase": plotrc.phase,
                "pline": plotrc.line,
                "plotrc": plotrc,
                "pprint": pprint.pprint,
                "pspec": plotrc.spectrogram,
                "pwave": plotrc.waveform,
                "shell": pyrc.shell,
                "varname": pyrc.varname,
            },
            pyrc.find_vars(var_lookup(frame), command),
        )
    except Exception as exception:  # noqa: BLE001
        result.SetError(str(exception))
        result.SetStatus(eReturnStatusFailed)


def cmd_pytype(
    debugger: SBDebugger,
    command: str,
    exe_ctx: SBExecutionContext,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Print variable type as it appears to Python."""
    name = command.strip()
    frame = curframe(debugger)
    variable = frame.FindVariable(name)
    if variable.error.success:
        print(variable.type.name)
    else:
        result.SetError(f"Unable to find variable '{name}'.")
        result.SetStatus(eReturnStatusFailed)


def curframe(debugger: SBDebugger) -> SBFrame:
    """Get current stack frame in debugger."""
    target = debugger.GetSelectedTarget()
    return target.GetProcess().GetSelectedThread().GetSelectedFrame()


# Function requires many cases to handle possible variable types.
def to_py(variable: SBValue) -> Any:  # noqa: PLR0911
    """Convert program type to Python type."""
    type_ = variable.type.name

    if type_ == "bool":
        return variable.value == "true"
    if re.match(f"^{CPP_NUL_RE}|{RS_NUL_RE}$", type_):
        return None
    if re.match(f"^({CPP_INT_RE}|{RS_INT_RE})$", type_):
        return int(variable.value)
    if re.match(f"^({CPP_FLT_RE}|{RS_FLT_RE})$", type_):
        return float(variable.value)
    if re.match(f"^({CPP_STR_RE}|{RS_STR_RE})$", type_):
        return variable.GetSummary().strip('"')
    if re.match(f"^({CPP_ARR_RE}|{RS_ARR_RE})$", type_):
        return [to_py(child) for child in variable.children]
    if re.match(f"^({CPP_WRP_RE}|{RS_WRP_RE})$", type_):
        # Dereference variable for inner content.
        return to_py(variable.children[0])
    if variable.value is not None:
        return variable.value

    msg = f"Unsupported type '{type_}' for '{variable.name}'."
    raise TypeError(msg)


def var_lookup(frame: SBFrame) -> Callable[[str], Any]:
    """Generate a variable lookup function for a debugger frame."""

    def lookup(name: str) -> Any:
        variable = frame.FindVariable(name)
        if variable.error.success:
            try:
                return to_py(variable)
            except TypeError as error:
                msg = f"Unable to convert variable '{name}' into a Python type."
                raise ValueError(msg) from error
        msg = f"Unable to find variable '{name}'."
        raise ValueError(msg)

    return lookup


def __lldb_init_module(debugger: SBDebugger, internal_dict: dict) -> None:
    """LLDB entrypoint for customization."""
    result = SBCommandReturnObject()
    interpreter = debugger.GetCommandInterpreter()

    interpreter.HandleCommand(
        "command script add --function lldbrc.cmd_nushell nu",
        result,
    )
    interpreter.HandleCommand(
        "command script add --function lldbrc.cmd_py py",
        result,
    )
    interpreter.HandleCommand(
        "command script add --function lldbrc.cmd_pytype pytype",
        result,
    )
