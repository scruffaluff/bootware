"""Python debugger settings file."""

import inspect
import os
from pathlib import Path
import pprint
import re
import subprocess
import tempfile
from typing import Any, Dict, List, Optional


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
        regex = re.compile(regex, re.IGNORECASE)

        values = []
        for key in sorted(object.__dict__.keys()):
            # Avoid key __builtins__ since formatting it can cause a crash.
            if not isinstance(key, str) or (
                key != "__builtins__" and regex.match(key)
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
    object.__dict__ = dictionary
    return object


def docs(object: Any) -> None:
    """Print object signature and documentation in default pager."""
    docstring = inspect.getdoc(object)
    try:
        signature = f"{object.__name__}{inspect.signature(object)}"
    except TypeError:
        signature = None

    if docstring is None and signature is None:
        return
    elif docstring is None:
        page(signature)
    elif signature is None:
        page(docstring)
    else:
        page(f"{signature}\n{docstring}")


def edit(object: Any = None, frame: Any = None) -> None:
    """Open object's source code in default editor."""
    editor = os.environ.get("EDITOR", "vim")
    if object is None and frame is not None:
        file, line = frame.f_code.co_filename, frame.f_lineno
        command = [editor, f"+{line}", file]
    elif inspect.ismodule(object):
        command = [editor, inspect.getsourcefile(object)]
    elif isinstance(object, str):
        command = [editor, object]
    else:
        raise ValueError("Bad arguments")
    subprocess.run(command, check=True)


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


def shell(*args: Any, frame: Any = None) -> None:
    """Execute command or start default shell if empty."""
    command = args or [os.environ.get("SHELL", "/bin/sh")]
    folder = Path(frame.f_code.co_filename).parent if frame else None
    subprocess.run(command, check=True, cwd=folder)


type(exit).__repr__ = lambda self: self()
type(quit).__repr__ = lambda self: self()
