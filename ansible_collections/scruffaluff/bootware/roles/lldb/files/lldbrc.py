"""LLDB settings script."""

# ruff: noqa: ANN401, ARG001, BLE001, S307

from __future__ import annotations

import re
import shlex
import subprocess
from pprint import pprint
from subprocess import CalledProcessError
from typing import Any

import dbgrc
import plotrc
from dbgrc import Parser
from lldb import (
    SBCommandReturnObject,
    SBDebugger,
    SBExecutionContext,
    SBFrame,
    SBValue,
    eReturnStatusFailed,
)


def cmd_nushell(
    debugger: SBDebugger,
    command: str,
    exe_ctx: SBExecutionContext,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Execute Nushell expression or start interactive session."""
    line = parse_exprs(debugger, command)
    parser = Parser()
    parser.add_argument("-c", "--cwd", default=None)
    rest, args = parser.parse_line(line)
    cmd = ["nu", "--login", "--commands", rest] if rest else ["nu", "--login"]
    try:
        subprocess.run(cmd, check=True, cwd=args.cwd)
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
    frame = current_frame(debugger)
    variables = find_vars(frame)
    try:
        eval(command, {**globals(), "pp": pprint, "plotrc": plotrc}, variables)
    except Exception as exception:
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
    frame = current_frame(debugger)
    variable = frame.FindVariable(name)
    if variable.error.success:
        print(variable.type.name)
    else:
        result.SetError(f"Unable to find variable '{name}'.")
        result.SetStatus(eReturnStatusFailed)


def current_frame(debugger: SBDebugger) -> SBFrame:
    """Get current stack frame in debugger."""
    target = debugger.GetSelectedTarget()
    return target.GetProcess().GetSelectedThread().GetSelectedFrame()


def find_vars(frame: SBFrame) -> dict[str, Any]:
    """Find all variables in the current stack frame."""
    variables = {}
    for variable in frame.variables:
        try:
            variables[variable.name] = to_py(variable)
        except TypeError:
            pass
    return variables


def parse_exprs(debugger: SBDebugger, line: str) -> str:
    """Parse and possibly execute command line expressions."""
    frame = current_frame(debugger)
    variables = find_vars(frame)
    offset = 0
    for expr in dbgrc.find_exprs(line):
        try:
            result = str(eval(expr.expr, {}, variables))
        except Exception:  # noqa: S112
            continue
        insert = shlex.quote(result)
        line = line[: expr.start + offset] + insert + line[expr.stop + offset :]
        offset += len(insert) - expr.stop + expr.start
    return line


def to_py(variable: SBValue) -> Any:
    """Convert program type to Python type."""
    type_ = variable.type.name

    if re.fullmatch(
        r"^(((un)?signed\s+)?(short\s+|(long\s+){1,2})?int"
        r"|u?int\d+_(fast_|least_)?t|ptrdiff_t|s?size_t)$",
        type_,
    ):
        return int(variable.value)
    if re.match(r"^(float|(long\s+)?double|b?float\d+_t)$", type_):
        return float(variable.value)
    if type_ == "bool":
        return variable.value == "true"
    if type_ == "std::nullptr_t":
        return None
    if re.match(
        r"^(.*\[(f|i|u)\d+\]|"
        r"(alloc|core|std)::.*::(Box|Slice|Vec|VecDeque).*"
        r"|std::(.*::)?(array|deque|list|vector).*)$",
        type_,
    ):
        return [to_py(child) for child in variable.children]
    if variable.value is not None:
        return variable.value

    msg = f"Unsupported type '{variable.type.name}' for '{variable.name}'."
    raise TypeError(msg)


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
