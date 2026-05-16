"""LLDB settings script."""

# ruff: noqa: ANN401, ARG001, BLE001, S307

from __future__ import annotations

import itertools
import shlex
import subprocess
from argparse import ArgumentError, ArgumentParser, Namespace
from collections.abc import Sequence
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, Any, NamedTuple

from lldb import SBCommandReturnObject, SBDebugger

if TYPE_CHECKING:
    from argparse import Namespace
    from collections.abc import Iterator, Sequence


class Expr(NamedTuple):
    """Command line expression with location."""

    expr: str
    start: int
    stop: int


class Parser(ArgumentParser):
    """Argument parser for LLDB commands."""

    def __init__(self) -> None:
        """Create a new Parser instance."""
        super().__init__(exit_on_error=False)

    def parse_line(self, line: str) -> tuple[str, Namespace]:
        """Parse line for LLDB command."""
        index = 0
        previous = False
        tokens = shlex.split(line)
        for token in tokens:
            if token.startswith("-"):
                previous = True
            elif previous:
                previous = False
            else:
                break
            index += 1

        try:
            args = self.parse_args(tokens[:index])
        except ArgumentError:
            index -= 1
            try:
                args = self.parse_args(tokens[:index])
            except ArgumentError:
                return line, self.parse_args([])
        rest = drop_tokens(tokens[:index], line)
        return rest, args


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


def drop_tokens(tokens: list[str], line: str) -> str:
    """Remove lexical tokens from start of line."""
    position = 0
    for token in tokens:
        index = line.find(token, position)
        if index == -1:
            message = f"Tokens {tokens} are not a subset of line '{line}'."
            raise ValueError(message)
        position = index + len(token)

        # Remove trailing quotes after token that shlex may have ignored.
        while not list_get(line, position, " ").isspace():
            position += 1
    return line[position:].lstrip()


def find_exprs(line: str) -> Iterator[Expr]:  # noqa: C901
    """Find Python variables starting with % or expressions surrounded by %{}."""
    first_chars = ["_", *map(chr, itertools.chain(range(65, 91), range(97, 123)))]
    chars = first_chars + list(map(chr, range(48, 58)))
    index = 0
    length = len(line)
    stack: list[int] = []
    variable: list[int] = []

    while index < length:
        character = line[index]
        try:
            next_ = line[index + 1]
        except IndexError:
            next_ = None

        if stack:
            if character == "}":
                start = stack.pop()
                if not stack:
                    stack = []
                    yield Expr(line[start:index], start - 2, index + 1)
            elif character == "{":
                stack.append(index + 1)
            index += 1
        elif variable:
            index += 1
            if next_ not in chars:
                start = variable.pop()
                yield Expr(line[start:index], start - 1, index)
        elif character == "%" and next_ == "{":
            stack.append(index + 2)
            index += 2
        elif character == "%" and next_ in first_chars:
            variable.append(index + 1)
            index += 1
        else:
            index += 1


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


def list_get(lst: Sequence[Any], pos: int, default: Any) -> Any:
    """Safe implementation of get for sequences."""
    try:
        return lst[pos]
    except IndexError:
        return default


def nushell(expr: str, **kwargs: Any) -> None:
    """Execute Nushell expression or start interactive session."""
    command = ["nu", "--login", "--commands", expr] if expr else ["nu", "--login"]
    try:
        subprocess.run(command, check=True, **kwargs)
    except (CalledProcessError, FileNotFoundError) as exception:
        print(exception)


def parse_exprs(debugger: SBDebugger, line: str) -> str:
    """Parse and possibly execute command line expressions."""
    variables = find_vars(debugger)
    offset = 0
    for expr in find_exprs(line):
        try:
            result = str(eval(expr.expr, {}, variables))
        except Exception:  # noqa: S112
            continue
        insert = shlex.quote(result)
        line = line[: expr.start + offset] + insert + line[expr.stop + offset :]
        offset += len(insert) - expr.stop + expr.start
    return line


def __lldb_init_module(debugger: SBDebugger, internal_dict: dict) -> None:
    """LLDB entrypoint for customization."""
    result = SBCommandReturnObject()
    interpreter = debugger.GetCommandInterpreter()

    interpreter.HandleCommand(
        "command script add --function lldbinit.cmd_nushell nu",
        result,
    )
