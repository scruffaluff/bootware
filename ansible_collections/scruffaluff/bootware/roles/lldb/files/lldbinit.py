"""LLDB settings script."""

# ruff: noqa: ARG001

import re

from lldb import SBCommandReturnObject, SBDebugger


def cmd_cb(
    debugger: SBDebugger,
    command: str,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Add command to continue to temporary breakpoint."""
    interpreter = debugger.GetCommandInterpreter()
    interpreter.HandleCommand(f"b {command}", result)
    if result.Succeeded():
        match = re.match(r"^Breakpoint (\d):.*", result.GetOutput())
        if match is None:
            return

        id_ = match.group(1)
        interpreter.HandleCommand("continue", result)
        interpreter.HandleCommand(f"breakpoint delete {id_}", result)


def cmd_pdb(
    debugger: SBDebugger,
    command: str,
    result: SBCommandReturnObject,
    internal_dict: dict,
) -> None:
    """Add command to debug LLDBInit."""
    breakpoint()  # noqa: T100


def __lldb_init_module(debugger: SBDebugger, internal_dict: dict) -> None:
    """LLDB entrypoint for customization."""
    result = SBCommandReturnObject()
    interpreter = debugger.GetCommandInterpreter()

    interpreter.HandleCommand(
        "command script add --function lldbinit.cmd_cb cb", result
    )
    interpreter.HandleCommand(
        "command script add --function lldbinit.cmd_pdb pdb", result
    )
