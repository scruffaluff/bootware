"""Python debugger settings file."""

import inspect
import os
from pathlib import Path
import pprint
import re
import shlex
import subprocess
from subprocess import CalledProcessError
import tempfile
from typing import Any, cast, Optional, Type, Union


def cat(
    object: Any, regex: Optional[str] = None, name: Optional[str] = None
) -> None:
    """Print object catalog with default pager."""
    regex = "^[^_].*" if regex is None else regex
    page(catalog(object, name=name, regex=regex))


def catalog(
    object: Any,
    regex: str = "^[^_].*",
    name: Optional[str] = None,
) -> str:
    """Convert object to string representation with all attributes."""
    if hasattr(object, "__dict__"):
        name = name or object.__name__
        regex_ = re.compile(regex, re.IGNORECASE)

        values = []
        for key in sorted(object.__dict__.keys()):
            # Avoid key __builtins__ since formatting it can cause a crash.
            if not isinstance(key, str) or (
                key != "__builtins__" and regex_.match(key)
            ):
                value = pprint.pformat(object.__dict__[key])
                values.append(f"{name}.{key} = {value}")
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
    object = parse(self, line)
    if object is None:
        error("Command cat takes one or two arguments")
    elif isinstance(object, tuple) and len(object) == 2:
        cat(*object)
    else:
        cat(object)


def do_doc(self, line: str) -> None:
    """doc [object]

    Print object signature and documentation in default pager.
    """
    object = parse(self, line)
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
    object = parse(self, line)
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
        result = parse(self, argument)
        arguments.append(argument if result is None else str(result))
    shell(shlex.join(arguments), self.curframe)


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
        signature = f"{object.__name__}{inspect.signature(object)}"
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
    editor = os.environ.get("EDITOR", "vim")
    if isinstance(object, int) and frame is not None:
        command = [editor, f"+{object}", frame.f_code.co_filename]
    elif object is None and frame is not None:
        file, line = frame.f_code.co_filename, frame.f_lineno
        command = [editor, f"+{line}", file]
    else:
        type_ = object if is_type(object) else type(object)
        if inspect.isbuiltin(object):
            error(f"Cannot view source code for builtin '{object}'")
            return
        file = inspect.getsourcefile(type_)
        line = inspect.findsource(type_)[1] + 1
        command = [editor, f"+{line}", file]
    subprocess.run(command, check=True)


def error(message: Union[str, Exception]) -> None:
    """Print error to console."""
    print(f"*** {message}")


def is_int(value: Any) -> bool:
    """Check if value can be converted to an integer."""
    try:
        int(value)
    except (TypeError, ValueError):
        return False
    else:
        return True


def is_type(value: Any) -> bool:
    """Check if value is a type or variable."""
    return any(
        (
            inspect.isclass(value),
            inspect.ismodule(value),
            inspect.isroutine(value),
        )
    )


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


def parse(pdb: Type, line: str) -> Any:
    """Parse and possibly execute command line input."""
    try:
        return eval(line, pdb.curframe.f_globals, pdb.curframe_locals)
    except Exception:
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


def shell(cmd: str, frame: Any = None) -> None:
    """Execute shell command or start interactive shell on empty command."""
    if cmd:
        command = cmd.split()
    else:
        command = [os.environ.get("SHELL", "/bin/sh")]
    folder = Path(frame.f_code.co_filename).parent if frame else None
    try:
        subprocess.run(command, check=True, cwd=folder)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)
