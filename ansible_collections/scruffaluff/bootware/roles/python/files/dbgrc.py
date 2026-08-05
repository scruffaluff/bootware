"""Python debugger settings file."""

# ruff: noqa: ANN401, BLE001, S307

from __future__ import annotations

import ast
import functools
import importlib
import inspect
import itertools
import os
import pprint
import re
import shlex
import subprocess
import sys
import tempfile
import traceback
from argparse import ArgumentError, ArgumentParser
from ast import Load, Name
from collections.abc import Callable
from pathlib import Path
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, Any, NamedTuple, cast

if TYPE_CHECKING:
    from argparse import Namespace
    from collections.abc import Callable, Iterator, Sequence
    from pdb import Pdb
    from types import ModuleType, TracebackType


class Expr(NamedTuple):
    """Command line expression with location."""

    expr: str
    start: int
    stop: int


class Parser(ArgumentParser):
    """Argument parser for debugger commands."""

    def __init__(self) -> None:
        """Create a new Parser instance."""
        super().__init__(exit_on_error=False)

    def parse_line(self, line: str) -> tuple[str, Namespace]:
        """Parse line for debugger command."""
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


def break_exception(self: Pdb) -> Callable:
    """Create exception handler for debugging."""

    def excepthook(
        type_: type[BaseException], value: BaseException, trace: TracebackType
    ) -> None:
        """Start debugger on unhandled exception."""
        traceback.print_exception(type_, value, trace)
        # Mypy is incorrect since the method is defined at
        # https://docs.python.org/3/library/pdb.html#pdb.pm.
        self.pm()  # type: ignore[attr-defined]

    return excepthook


def cat(object_: Any, regex: str | None = None) -> None:
    """Print object catalog with default pager."""
    regex = ".*" if regex is None else regex
    page(catalog(object_, regex=regex))


def catalog(
    object_: Any,
    regex: str = ".*",
) -> str:
    """Convert object to string representation with all attributes."""
    if hasattr(object_, "__dict__") and object_.__dict__:
        name_ = name(object_)
        regex_ = re.compile(regex, re.IGNORECASE)

        values = []
        for key in sorted(object_.__dict__.keys()):
            # Avoid key __builtins__ since formatting it can cause a crash.
            if not isinstance(key, str) or (
                key != "__builtins__" and regex_.search(key)
            ):
                value = pprint.pformat(object_.__dict__[key])
                values.append(f"{name_}.{key} = {value}")
        return "\n".join(values)
    if isinstance(object_, dict):
        return pprint.pformat({key: object_[key] for key in sorted(object_.keys())})
    return pprint.pformat(object_)


def doc(object_: Any) -> None:
    """Print object signature and documentation in default pager."""
    docstring = inspect.getdoc(object_)
    try:
        signature = f"{name(object_)}{inspect.signature(object_)}"
    except (AttributeError, TypeError):
        signature = None

    if docstring is None and signature is None:
        error(f"Unable to find documenation for '{object_}'")
    elif docstring is None:
        page(cast("str", signature))
    elif signature is None:
        page(docstring)
    else:
        page(f"{signature}\n{docstring}")


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


@functools.cache
def dyport(name: str) -> ModuleType:
    """Import library and install if necessary."""
    version = f"{sys.version_info.major}.{sys.version_info.minor}"
    target = str(Path.home() / f".config/pyrc/venv/python{version}")
    if target not in sys.path:
        sys.path.append(target)
        importlib.invalidate_caches()

    try:
        library = importlib.import_module(name)
    except ModuleNotFoundError:
        package = name.split(".", maxsplit=1)[0]
        subprocess.run(
            [
                "uv",
                "--no-config",
                "pip",
                "install",
                "--python",
                version,
                "--target",
                target,
                package,
            ],
            check=True,
        )
        importlib.invalidate_caches()
        library = importlib.import_module(name)
    return library


def edit(object_: Any = None, frame: Any = None) -> None:
    """Open object's source code in default editor."""
    editor = os.environ.get("EDITOR", "vi")
    if isinstance(object_, int) and frame is not None:
        command = [editor, f"+{object_}", frame.f_code.co_filename]
    elif object_ is None and frame is not None:
        file, line = frame.f_code.co_filename, frame.f_lineno
        command = [editor, f"+{line}", file]
    else:
        type_ = object_ if is_type(object_) else type(object_)
        try:
            file, line = find_source(type_)
        except Exception as exception:
            error(exception)
            return
        command = [editor, f"+{line}", file]

    if os.environ.get("ZELLIJ"):
        command = [
            "zellij",
            "action",
            "new-pane",
            "--close-on-exit",
            "--",
            *command,
        ]
    subprocess.run(command, check=True)


def error(message: str | Exception) -> None:
    """Print error to console."""
    if isinstance(message, str):
        print(f"*** {message}")
    else:
        print(f"*** {type(message).__name__}: {message}")


def find_exprs(line: str) -> Iterator[Expr]:  # noqa: C901
    """Find variables starting with % or expressions surrounded by %{}."""
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


def find_source(type_: type) -> tuple[str, int]:
    """Find location of source code for a type."""
    file = inspect.getsourcefile(type_)
    if file is None or not isinstance(file, str):
        message = f"Unable to find source file for '{type_}'"
        raise ValueError(message)
    line = inspect.findsource(type_)[1] + 1
    return file, line


def find_vars(lookup: Callable[[str], Any], expression: str) -> dict[str, Any]:
    """Extract variables and their values from a Python expression."""
    tree = ast.parse(expression, mode="eval")
    seen = set()
    variables = {}

    for node in ast.walk(tree):
        name = getattr(node, "id", "")
        if name not in seen and isinstance(node, Name) and isinstance(node.ctx, Load):
            seen.add(name)
            try:
                variables[name] = lookup(name)
            except ValueError:
                pass

    return variables


def is_type(value: Any) -> bool:
    """Check if value is a type or variable."""
    return any(
        (
            inspect.isclass(value),
            inspect.ismodule(value),
            inspect.isroutine(value),
        )
    )


def list_get(lst: Sequence[Any], pos: int, default: Any) -> Any:
    """Safe implementation of get for sequences."""
    try:
        return lst[pos]
    except IndexError:
        return default


def name(object_: Any) -> str:
    """Get name object of name of its type."""
    return cast("str", getattr(object_, "__name__", object_.__class__.__name__))


def nushell(expr: str, **kwargs: Any) -> None:
    """Execute Nushell expression or start interactive session."""
    command = ["nu", "--login", "--commands", expr] if expr else ["nu", "--login"]
    try:
        subprocess.run(command, check=True, **kwargs)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)


def page(text: str) -> None:
    """Print string with default pager."""
    pager = os.environ.get("PAGER", "less")
    basename = Path(pager).name
    command = [pager, "--language", "python"] if basename == "bat" else [pager]
    with tempfile.NamedTemporaryFile("w") as file:
        file.write(text)
        file.flush()
        subprocess.run([*command, file.name], check=True)


def parent_shell() -> str:
    """Get shell of parent process or default system shell."""
    if sys.platform == "win32":
        default = "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    else:
        default = "/bin/sh"
    return os.environ.get("SHELL", default)


def parse_exprs(lookup: Callable[[str], Any], line: str) -> str:
    """Parse and possibly execute command line expressions."""
    offset = 0
    for expr in find_exprs(line):
        variables = find_vars(lookup, expr.expr)
        try:
            result = str(eval(expr.expr, {}, variables))
        except Exception:  # noqa: S112
            continue
        insert = shlex.quote(result)
        line = line[: expr.start + offset] + insert + line[expr.stop + offset :]
        offset += len(insert) - expr.stop + expr.start
    return line


def shell(command: list[str]) -> None:
    """Execute command or start interactive default shell session."""
    if not command:
        command = [parent_shell()]
    try:
        subprocess.run(command, check=True)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)
