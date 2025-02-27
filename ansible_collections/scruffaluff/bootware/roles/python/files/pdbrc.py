"""Python debugger settings file."""

import inspect
import os
from pathlib import Path
import pprint
import re
import shlex
import subprocess
from subprocess import CalledProcessError
import sys
import tempfile
from typing import Any, cast, List, Optional, Tuple, Type, Union


def cat(object: Any, regex: Optional[str] = None) -> None:
    """Print object catalog with default pager."""
    regex = ".*" if regex is None else regex
    page(catalog(object, regex=regex))


def catalog(
    object: Any,
    regex: str = ".*",
) -> str:
    """Convert object to string representation with all attributes."""
    if hasattr(object, "__dict__") and object.__dict__:
        name_ = name(object)
        regex_ = re.compile(regex, re.IGNORECASE)

        values = []
        for key in sorted(object.__dict__.keys()):
            # Avoid key __builtins__ since formatting it can cause a crash.
            if not isinstance(key, str) or (
                key != "__builtins__" and regex_.match(key)
            ):
                value = pprint.pformat(object.__dict__[key])
                values.append(f"{name_}.{key} = {value}")
        return "\n".join(values)
    elif isinstance(object, dict):
        return pprint.pformat(
            {key: object[key] for key in sorted(object.keys())}
        )
    else:
        return pprint.pformat(object)


def do_cat(self, line: str) -> None:
    """cat object [, regex]

    Print object catalog with default pager.
    """
    if not line.strip():
        error("Command cat takes one or two arguments")
        return
    try:
        object = parse(self, line)
    except Exception as exception:
        error(exception)
        return

    if (
        isinstance(object, tuple)
        and len(object) == 2
        and isinstance(object[1], str)
    ):
        cat(*object)
    else:
        cat(object)


def do_doc(self, line: str) -> None:
    """doc [object]

    Print object signature and documentation in default pager.
    """
    try:
        object = parse(self, line)
    except Exception as exception:
        error(exception)
        return

    if object is None:
        try:
            docstring = self.curframe.f_globals["__doc__"]
        except KeyError:
            error("Unable to find current module docstring")
        else:
            cat(docstring)
    else:
        doc(object)


def do_edit(self, line: str) -> None:
    """ed(it) [object]

    Open object source code or current module in default text editor.
    """
    try:
        object = parse(self, line)
    except Exception as exception:
        error(exception)
    else:
        edit(object, self.curframe)


def do_nextlist(self, arg) -> int:
    """nl | nextlist

    Continue execution until the next line and then list source code.
    """
    self.set_next(self.curframe)
    self.do_list(None)
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


def do_shell(self, line: str) -> None:
    """sh(ell) [command]

    Execute shell command or start interactive shell on empty command.
    """
    arguments = []
    for argument in shlex.split(line.strip()):
        try:
            object = parse(self, argument)
        except Exception:
            arguments.append(argument)
        else:
            arguments.append(str(object))
    shell(arguments, self.curframe)


def do_steplist(self, arg) -> int:
    """sl | steplist

    Execution current line and then list source code.
    """
    self.set_step()
    self.do_list(arg)
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


def doc(object: Any) -> None:
    """Print object signature and documentation in default pager."""
    docstring = inspect.getdoc(object)
    try:
        signature = f"{name(object)}{inspect.signature(object)}"
    except (AttributeError, TypeError):
        signature = None

    if docstring is None and signature is None:
        error(f"Unable to find documenation for '{object}'")
    elif docstring is None:
        page(cast(str, signature))
    elif signature is None:
        page(docstring)
    else:
        page(f"{signature}\n{docstring}")


def edit(object: Any = None, frame: Any = None) -> None:
    """Open object's source code in default editor."""
    editor = os.environ.get("EDITOR", "vi")
    if isinstance(object, int) and frame is not None:
        command = [editor, f"+{object}", frame.f_code.co_filename]
    elif object is None and frame is not None:
        file, line = frame.f_code.co_filename, frame.f_lineno
        command = [editor, f"+{line}", file]
    else:
        type_ = object if is_type(object) else type(object)
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
        ] + command
    subprocess.run(command, check=True)


def error(message: Union[str, Exception]) -> None:
    """Print error to console."""
    if isinstance(message, str):
        print(f"*** {message}")
    else:
        print(f"*** {type(message).__name__}: {message}")


def find_source(type: Type) -> Tuple[str, int]:
    """Find location of source code for a type."""
    file = inspect.getsourcefile(type)
    if file is None or not isinstance(file, str):
        raise ValueError(f"Unable to find source file for '{type}'")
    line = inspect.findsource(type)[1] + 1
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


def name(object: Any) -> str:
    """Get name object of name of its type."""
    return getattr(object, "__name__", object.__class__.__name__)


def page(text: str) -> None:
    """Print string with default pager."""
    pager = os.environ.get("PAGER", "less")
    basename = os.path.basename(pager)
    if basename == "bat":
        command = [pager, "--language", "python"]
    else:
        command = [pager]
    with tempfile.NamedTemporaryFile("w") as file:
        file.write(text)
        file.flush()
        subprocess.run(command + [file.name], check=True)


def parent_shell() -> str:
    """Get shell of parent process or default system shell."""
    if sys.platform == "win32":
        default = "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    else:
        default = "/bin/sh"
    return os.environ.get("SHELL", default)


def parse(pdb: Type, line: str) -> Any:
    """Parse and possibly execute command line input."""
    if line.strip():
        return eval(line, pdb.curframe.f_globals, pdb.curframe_locals)
    else:
        return None


def setup(pdb: Type) -> None:
    """Extend PDB with custom functionality."""
    pdb.do_cat = do_cat
    pdb.complete_cat = pdb._complete_expression
    pdb.do_doc = do_doc
    pdb.complete_doc = pdb._complete_expression
    pdb.do_edit = do_edit
    pdb.complete_edit = pdb._complete_expression
    pdb.do_nl = do_nextlist
    pdb.do_nextlist = do_nextlist
    pdb.do_sh = do_shell
    pdb.do_shell = do_shell
    pdb.do_sl = do_steplist
    pdb.do_steplist = do_steplist


def shell(command: List[str], frame: Any = None) -> None:
    """Execute shell command or start interactive shell on empty command."""
    if not command:
        command = [parent_shell()]
    folder = Path(frame.f_code.co_filename).parent if frame else None
    try:
        subprocess.run(command, check=True, cwd=folder)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)
