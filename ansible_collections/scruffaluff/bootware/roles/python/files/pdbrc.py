"""Python debugger settings file."""

# ruff: noqa: ANN401, BLE001, S307, SLF001

from __future__ import annotations

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
from pathlib import Path
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, Any, Callable, cast

if TYPE_CHECKING:
    from pdb import Pdb
    from types import FrameType, TracebackType


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
                key != "__builtins__" and regex_.match(key)
            ):
                value = pprint.pformat(object_.__dict__[key])
                values.append(f"{name_}.{key} = {value}")
        return "\n".join(values)
    if isinstance(object_, dict):
        return pprint.pformat({key: object_[key] for key in sorted(object_.keys())})
    return pprint.pformat(object_)


def curframe(pdb: Pdb) -> FrameType:
    """Attribute accessor wrapper to satisfy Mypy."""
    return cast("FrameType", pdb.curframe)


def do_cat(self: Pdb, line: str) -> None:
    """cat object [, regex]

    Print object catalog with default pager.
    """  # noqa: D403, D415
    if not line.strip():
        error("Command cat takes one or two arguments")
        return
    try:
        object_ = parse(self, line)
    except Exception as exception:
        error(exception)
        return

    if isinstance(object_, tuple) and len(object_) == 2 and isinstance(object_[1], str):  # noqa: PLR2004
        cat(*object_)
    else:
        cat(object_)


def do_doc(self: Pdb, line: str) -> None:
    """doc [object]

    Print object signature and documentation in default pager.
    """  # noqa: D403, D415
    try:
        object_ = parse(self, line)
    except Exception as exception:
        error(exception)
        return

    if object_ is None:
        try:
            docstring = curframe(self).f_globals["__doc__"]
        except KeyError:
            error("Unable to find current module docstring")
        else:
            cat(docstring)
    else:
        doc(object_)


def do_edit(self: Pdb, line: str) -> None:
    """ed(it) [object]

    Open object source code or current module in default text editor.
    """  # noqa: D415
    try:
        object_ = parse(self, line)
    except Exception as exception:
        error(exception)
    else:
        edit(object_, curframe(self))


def do_nextlist(self: Pdb, _arg: str) -> int:
    """nl | nextlist

    Continue execution until the next line and then list source code.
    """  # noqa: D403, D415
    self.set_next(curframe(self))
    self.do_list("")
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


def do_nushell(self: Pdb, line: str) -> None:
    """nu(shell) [command]

    Execute Nushell command or start interactive Nushell on empty command.
    """  # noqa: D415
    arguments = []
    for argument in map(os.path.expanduser, shlex.split(line.strip())):
        try:
            object_ = parse_expr(self, argument)
        except Exception:  # noqa: PERF203
            arguments.append(argument)
        else:
            arguments.append(str(object_))
    nushell(arguments, curframe(self))


def do_shell(self: Pdb, line: str) -> None:
    """sh(ell) [command]

    Execute shell command or start interactive shell on empty command.
    """  # noqa: D415
    arguments = []
    for argument in map(os.path.expanduser, shlex.split(line.strip())):
        try:
            object_ = parse_expr(self, argument)
        except Exception:  # noqa: PERF203
            arguments.append(argument)
        else:
            arguments.append(str(object_))
    shell(arguments, curframe(self))


def do_steplist(self: Pdb, arg: str) -> int:
    """sl | steplist

    Execution current line and then list source code.
    """  # noqa: D403, D415
    self.set_step()
    self.do_list(arg)
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


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


# TODO: Break function into smaller components.
def find_expr(input_: str) -> tuple[int, int, str]:  # noqa: C901
    """Find Python variables starting with % or expression surrounded by '%{}'."""
    first_chars = ["_", *map(chr, itertools.chain(range(65, 91), range(97, 123)))]
    chars = first_chars + list(map(chr, range(48, 58)))
    index = 0
    length = len(input_)
    stack: list[int] = []
    variable: list[int] = []

    while index < length:
        character = input_[index]
        try:
            next_ = input_[index + 1]
        except IndexError:
            next_ = None

        if stack:
            if character == "}":
                start = stack.pop()
                if not stack:
                    return start - 2, index + 1, input_[start:index]
            elif character == "{":
                stack.append(index + 1)
            index += 1
        elif variable:
            index += 1
            if next_ not in chars:
                start = variable.pop()
                return start - 1, index, input_[start:index]
        elif character == "%" and next_ == "{":
            stack.append(index + 2)
            index += 2
        elif character == "%" and next_ in first_chars:
            variable.append(index + 1)
            index += 1
        else:
            index += 1
    return length, length, ""


def find_source(type_: type) -> tuple[str, int]:
    """Find location of source code for a type."""
    file = inspect.getsourcefile(type_)
    if file is None or not isinstance(file, str):
        message = f"Unable to find source file for '{type_}'"
        raise ValueError(message)
    line = inspect.findsource(type_)[1] + 1
    return file, line


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
    """Get name object of name of its type."""
    return cast("str", getattr(object_, "__name__", object_.__class__.__name__))


def nushell(command: list[str], frame: Any = None) -> None:
    """Execute shell command or start interactive shell on empty command."""
    command = (
        ["nu", "--commands", " ".join(command).replace("'", "\\'")]
        if command
        else ["nu"]
    )
    folder = Path(frame.f_code.co_filename).parent if frame else None
    try:
        subprocess.run(command, check=True, cwd=folder)
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


def parse(pdb: Pdb, input_: str) -> Any:
    """Parse and possibly execute command line input."""
    if input_.strip():
        return eval(input_, curframe(pdb).f_globals, pdb.curframe_locals)
    return None


def parse_expr(pdb: Pdb, input_: str) -> Any:
    """Parse and possibly execute command line expressions."""
    while True:
        start, stop, expr = find_expr(input_)
        if expr == "":
            break
        result = eval(expr, curframe(pdb).f_globals, pdb.curframe_locals)
        input_ = input_[:start] + str(result) + input_[stop:]
    return input_


def setup(pdb: Pdb) -> None:
    """Extend PDB with custom functionality."""
    pdb.do_cat = do_cat  # type: ignore[attr-defined]
    pdb.complete_cat = pdb._complete_expression  # type: ignore[attr-defined]
    pdb.do_doc = do_doc  # type: ignore[attr-defined]
    pdb.complete_doc = pdb._complete_expression  # type: ignore[attr-defined]
    pdb.do_edit = do_edit  # type: ignore[attr-defined]
    pdb.complete_edit = pdb._complete_expression  # type: ignore[attr-defined]
    pdb.do_nl = do_nextlist  # type: ignore[attr-defined]
    pdb.do_nextlist = do_nextlist  # type: ignore[attr-defined]
    pdb.do_nu = do_nushell  # type: ignore[attr-defined]
    pdb.do_nushell = do_nushell  # type: ignore[attr-defined]
    pdb.do_sh = do_shell  # type: ignore[attr-defined]
    pdb.do_shell = do_shell  # type: ignore[attr-defined]
    pdb.do_sl = do_steplist  # type: ignore[attr-defined]
    pdb.do_steplist = do_steplist  # type: ignore[attr-defined]


def shell(command: list[str], frame: Any = None) -> None:
    """Execute shell command or start interactive shell on empty command."""
    if not command:
        command = [parent_shell()]
    folder = Path(frame.f_code.co_filename).parent if frame else None
    try:
        subprocess.run(command, check=True, cwd=folder)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)
