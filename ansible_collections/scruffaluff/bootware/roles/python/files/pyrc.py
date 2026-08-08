"""Python debugger settings file."""

# Explicit optional, union, and quoted types are used to support older Python versions.
# ruff: noqa: ANN401

from __future__ import annotations

import ast
import builtins
import contextlib
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
from argparse import ArgumentError, ArgumentParser
from ast import Load, Name
from collections.abc import Callable, Iterable, Sequence
from pathlib import Path
from typing import TYPE_CHECKING, Any, NamedTuple, cast, no_type_check

if TYPE_CHECKING:
    from argparse import Namespace
    from collections.abc import Callable, Iterator
    from types import ModuleType


Array = Sequence[float]


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


def aplay(*args: Any, **kwargs: Any) -> None:
    """Play back a NumPy array containing audio data."""
    sounddevice = dyport("sounddevice")
    sounddevice.play(*args, **kwargs)


def arec(*args: Any, **kwargs: Any) -> Array:
    """Record audio data into a NumPy array."""
    sounddevice = dyport("sounddevice")
    return sounddevice.record(*args, **kwargs)


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
        msg = f"Unable to find documenation for '{object_}'"
        raise LookupError(msg)

    if docstring is None:
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
        while not seq_get(line, position, " ").isspace():
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
    if isinstance(object_, int) and frame is not None:
        file, line = frame.f_code.co_filename, object_
    elif object_ is None and frame is not None:
        file, line = frame.f_code.co_filename, frame.f_lineno
    else:
        type_ = object_ if is_type(object_) else type(object_)
        file, line = find_source(type_)

    if os.environ.get("TERM_PROGRAM") == "zed":
        command = ["zed", f"{file}:{line}"]
    elif os.environ.get("TERM_PROGRAM") == "code":
        command = ["code", f"{file}:{line}"]
    else:
        command = [os.environ.get("EDITOR", "vi"), f"+{line}", file]

    if os.environ.get("ZELLIJ"):
        subprocess.run(
            [
                "zellij",
                "action",
                "new-pane",
                "--close-on-exit",
                "--",
                *command,
            ],
            check=True,
        )
    else:
        subprocess.run(command, check=True)


@no_type_check
def export() -> None:
    """Add functions to global scope."""
    builtins.aplay = aplay
    builtins.arec = arec
    builtins.cat = cat
    builtins.doc = doc
    builtins.dyport = dyport
    builtins.edit = edit
    builtins.nushell = nushell
    builtins.page = page
    builtins.shell = shell
    builtins.varname = varname


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
            with contextlib.suppress(ValueError):
                variables[name] = lookup(name)
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


def name(object_: Any) -> str:
    """Get object name or its type name."""
    return cast("str", getattr(object_, "__name__", object_.__class__.__name__))


def nushell(command: str, **kwargs: Any) -> None:
    """Execute Nushell expression or start interactive session."""
    cmd = ["nu", "--login", "--commands", command] if command else ["nu", "--login"]
    subprocess.run(cmd, check=True, **kwargs)


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
            result = str(eval(expr.expr, {}, variables))  # noqa: S307
        # Any exception can occur during an eval statement. If the expression
        # cannot be evaluated, then it should be treated as a literal.
        except Exception:  # noqa: BLE001, S112
            continue
        insert = shlex.quote(result)
        line = line[: expr.start + offset] + insert + line[expr.stop + offset :]
        offset += len(insert) - expr.stop + expr.start
    return line


def popall(obj: Any, keys: str | Iterable[str], default: Any) -> Any:
    """Pop possible keys from object until successful."""
    if isinstance(keys, str):
        return obj.pop(keys, default)
    for key in keys:
        with contextlib.suppress(KeyError):
            return obj.pop(key)
    return default


def seq_get(seq: Sequence[Any], pos: int, default: Any) -> Any:
    """Safe implementation of get for sequences."""
    try:
        return seq[pos]
    except IndexError:
        return default


def shell(command: list[str]) -> None:
    """Execute command or start interactive default shell session."""
    if not command:
        command = [parent_shell()]
    subprocess.run(command, check=True)


def varname(var: Any, default: str = "", depth: int = 2) -> str:
    """Trace variable name in calling scope."""
    frame = inspect.currentframe()
    if frame is None:
        return default

    for _ in range(depth):
        frame = frame.f_back
        if frame is None:
            return default
    vars_ = frame.f_locals.items()
    try:
        return next(name for name, value in vars_ if value is var)
    except StopIteration:
        return default
