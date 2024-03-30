"""LLDB settings script."""

import re
from typing import Dict

from lldb import SBCommandReturnObject, SBDebugger


def cmd_cb(
    debugger: SBDebugger,
    command: str,
    result: SBCommandReturnObject,
    internal_dict: Dict,
) -> None:
    """Add command to continue to temporary breakpoint."""
    interpreter = debugger.GetCommandInterpreter()
    interpreter.HandleCommand(f"b {command}", result)
    if result.Succeeded():
        id = re.match(r"^Breakpoint (\d):.*", result.GetOutput()).group(1)
        interpreter.HandleCommand("continue", result)
        interpreter.HandleCommand(f"breakpoint delete {id}", result)


def cmd_pdb(
    debugger: SBDebugger,
    command: str,
    result: SBCommandReturnObject,
    internal_dict: Dict,
) -> None:
    """Add command to debug LLDBInit."""
    breakpoint()


def __lldb_init_module(debugger: SBDebugger, internal_dict: Dict) -> None:
    """LLDB entrypoint for customization."""
    result = SBCommandReturnObject()
    interpreter = debugger.GetCommandInterpreter()

    interpreter.HandleCommand(
        "command script add --function lldbinit.cmd_cb cb", result
    )
    interpreter.HandleCommand(
        "command script add --function lldbinit.cmd_pdb pdb", result
    )
