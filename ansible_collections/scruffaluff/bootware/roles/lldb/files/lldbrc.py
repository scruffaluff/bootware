"""LLDB settings script."""

# ruff: noqa: ANN401, ARG001, BLE001, S307

from __future__ import annotations

import shlex
import subprocess
from collections.abc import Sequence
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, Any

import dbgrc
import lldb
import plotrc
from dbgrc import Parser
from lldb import SBCommandReturnObject, SBDebugger

if TYPE_CHECKING:
    from collections.abc import Sequence


def cmd_nushell(
    debugger: SBDebugger,
    command: str,
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
        print(exception)


def cmd_plot(
    debugger: SBDebugger,
    command: str,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Plot vector as line with Matplotlib."""
    target = debugger.GetSelectedTarget()
    frame = target.GetProcess().GetSelectedThread().GetSelectedFrame()
    var = frame.FindVariable(command.strip())
    if var.GetError().Success():
        array = []
        for idx in range(var.GetNumChildren()):
            child = var.GetChildAtIndex(idx, lldb.eNoDynamicValues, True)
            array.append(float(child.GetValue()))
        plotrc.line(array)
    else:
        result.SetError(f"could not find variable: {command.strip()}")
        result.SetStatus(lldb.eReturnStatusErrorMessage)


def find_vars(debugger: SBDebugger) -> dict[str, Any]:
    """Find all variables in the current stack frame."""
    target = debugger.GetSelectedTarget()
    frame = target.GetProcess().GetSelectedThread().GetSelectedFrame()
    variables = {}
    for variable in frame.GetVariables(True, True, True, True):
        name = variable.GetName()
        value = variable.GetSummary()
        if value is None:
            variables[name] = variable.GetValue()
        else:
            variables[name] = value.strip('"')
    return variables


def parse_exprs(debugger: SBDebugger, line: str) -> str:
    """Parse and possibly execute command line expressions."""
    variables = find_vars(debugger)
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


def seq_get(lst: Sequence[Any], pos: int, default: Any) -> Any:
    """Safe implementation of get for sequences."""
    try:
        return lst[pos]
    except IndexError:
        return default


def __lldb_init_module(debugger: SBDebugger, internal_dict: dict) -> None:
    """LLDB entrypoint for customization."""
    result = SBCommandReturnObject()
    interpreter = debugger.GetCommandInterpreter()

    interpreter.HandleCommand(
        "command script add --function lldbrc.cmd_nushell nu",
        result,
    )
    interpreter.HandleCommand(
        "command script add --function lldbrc.cmd_plot plot",
        result,
    )
