"""Python debugger settings file."""

import inspect
import os
from pathlib import Path
import pprint
import re
import subprocess
from subprocess import CalledProcessError
import tempfile
from typing import Any, cast, Dict, List, Optional, Type, Union


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


def dictclass(dictionary: Dict) -> Any:
    """Convert dictionary to class."""
    object = lambda: None  # noqa: E731
    if isinstance(dictionary, dict):
        object.__dict__ = dictionary
    else:
        object.__dict__ = dict(dictionary)
    return object


def do_cat(self, line: str) -> None:
    """cat [object] [regex]

    Print object catalog with default pager.
    """
    arguments = line.strip().split()
    if arguments:
        try:
            object = variable(arguments[0], self.curframe)
        except (AttributeError, ValueError) as exception:
            error(exception)
            return
        regex = arguments[1] if len(arguments) > 1 else None
        cat(object, regex)
    else:
        error("Command cat takes one or two arguments")


def do_doc(self, line: str) -> None:
    """doc [object]

    Print object signature and documentation in default pager.
    """
    argument = line.strip()
    if argument:
        try:
            object = variable(argument, self.curframe)
        except (AttributeError, ValueError) as exception:
            error(exception)
            return
        doc(object)
    else:
        try:
            docstring = self.curframe.f_globals["__doc__"]
        except KeyError:
            error("Unable to find current module docstring")
        else:
            cat(docstring)


def do_edit(self, line: str) -> None:
    """ed(it) [object]

    Open object source code or current module in default text editor.
    """
    argument = line.strip()
    if not argument:
        edit(None, self.curframe)
    elif is_int(argument):
        edit(int(argument), self.curframe)
    else:
        try:
            object = variable(argument, self.curframe)
        except (AttributeError, ValueError) as exception:
            error(exception)
            return
        edit(object, self.curframe)


def do_shell(self, line: str) -> None:
    """sh(ell) [command]

    Execute shell command or start interactive shell on empty command.
    """
    shell(line.strip(), self.curframe)


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
    elif inspect.ismodule(object):
        command = [editor, inspect.getsourcefile(object)]
    elif isinstance(object, str):
        command = [editor, object]
    else:
        type_ = object if inspect.isclass(object) else type(object)
        file = inspect.getsourcefile(type_)
        line = inspect.findsource(type_)[1] + 1
        command = [editor, f"+{line}", file]
    subprocess.run(command, check=True)


def error(message: Union[str, Exception]) -> None:
    """Print error to console."""
    print(f"*** {message}")


def get(list: List, index: int = 0, default: Any = None) -> Any:
    """Get nth item from list or default."""
    try:
        item = list[index]
    except IndexError:
        return default

    # Split surrounding quotes for PDB parameters.
    if isinstance(item, str):
        return item.strip("'\"")
    else:
        return item


def is_int(value: Any) -> bool:
    """Check if value can be converted to an integer."""
    try:
        int(value)
    except ValueError:
        return False
    else:
        return True


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


def setup(pdb: Type) -> None:
    """Extend PDB with custom functionality."""
    pdb.do_cat = do_cat
    pdb.complete_cat = pdb._complete_expression
    pdb.do_doc = do_doc
    pdb.complete_doc = pdb._complete_expression
    pdb.do_edit = do_edit
    pdb.complete_edit = pdb._complete_expression
    pdb.do_sh = do_shell
    pdb.do_shell = do_shell


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


def variable(argument: str, frame: Any) -> Any:
    """Convert string argument to session variable."""
    value = None
    parts = argument.split(".")
    if parts[0] in frame.f_locals:
        value = frame.f_locals[parts[0]]
    elif parts[0] in frame.f_globals:
        value = frame.f_globals[parts[0]]

    if value is None:
        raise ValueError(f"Unable to find '{argument}' in the currect scope")
    else:
        for part in parts[1:]:
            value = getattr(value, part)
    return value
