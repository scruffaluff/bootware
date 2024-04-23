"""Python debugger settings file."""

import inspect
import os
from pathlib import Path
import pprint
import subprocess
import tempfile
from typing import Any, Dict, List, Iterator


def doc(object: Any) -> str:
    try:
        signature = f"{object.__name__}{inspect.signature(object)}\n"
    except TypeError:
        signature = ""
    return f"{signature}{inspect.getdoc(object)}"


def edit(args: List, file: str) -> None:
    editor = os.environ.get("EDITOR", "vim")
    try:
        object = args[0]
    except IndexError:
        command = [editor, file]
    else:
        if inspect.ismodule(object):
            command = [editor, inspect.getsourcefile(object)]
        elif isinstance(object, str):
            command = [editor, object]
        else:
            raise ValueError("")
    subprocess.run(command, check=True)


def format(object: Any, name: str, private: bool = False) -> str:
    if hasattr(object, "__dict__"):
        values = []
        for key in sorted(object.__dict__.keys()):
            if private or not isinstance(key, str) or not key.startswith("_"):
                value = pprint.pformat(object.__dict__[key])
                values.append(f"{name}.{key} = {value}")
        return "\n".join(values)
    elif isinstance(object, dict):
        return pprint.pformat(
            {key: object[key] for key in sorted(object.keys())}
        )
    else:
        return pprint.pformat(object)


def pager(text: str) -> None:
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


def shell(args: List, file: str) -> None:
    if args:
        command = args
    else:
        command = [os.environ.get("SHELL", "/bin/sh")]
    subprocess.run(command, check=True, cwd=Path(file).parent)
