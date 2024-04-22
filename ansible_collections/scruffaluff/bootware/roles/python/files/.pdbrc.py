"""Python debugger settings file.

Imports are renamed with a "__pdbrc_" prefix to reduce namespace pollution.
"""

import inspect as __pdbrc_inspect
import os as __pdbrc_os
import pprint as __pdbrc_pprint
import subprocess as __pdbrc_subprocess
import tempfile as __pdbrc_tempfile
import typing as __pdbrc_typing


def __pdbrc_doc(object: __pdbrc_typing.Any) -> str:
    try:
        signature = f"{object.__name__}{__pdbrc_inspect.signature(object)}\n"
    except TypeError:
        signature = ""
    return f"{signature}{__pdbrc_inspect.getdoc(object)}"


def __pdbrc_edit(*args: __pdbrc_typing.Any) -> None:
    editor = __pdbrc_os.environ.get("EDITOR", "vim")
    if args:
        object = args[0]
        if __pdbrc_inspect.ismodule(object):
            command = [editor, __pdbrc_inspect.getsourcefile(object)]
        elif isinstance(object, str):
            command = [editor, object]
        else:
            raise ValueError("")
    else:
        line = __pdb_convenience_variables["_frame"].f_lineno
        file = __pdb_convenience_variables["_frame"].f_code.co_filename
        command = [editor, f"+{line}", file]
    __pdbrc_subprocess.run(command, check=True)


def __pdbrc_format(object: __pdbrc_typing.Any) -> str:
    if hasattr(object, "__dict__"):
        values = []
        for key in __pdbrc_public_keys(object.__dict__):
            try:
                value = __pdbrc_pprint.pformat(object)
                values.append(f"{object.__name__}.{key} = {value}")
            except AttributeError:
                pass
        return "\n".join(values)
    elif isinstance(object, dict):
        return __pdbrc_pprint.pformat(
            {key: object[key] for key in __pdbrc_public_keys(object)}
        )
    else:
        return __pdbrc_pprint.pformat(object)


def __pdbrc_pager(text: str) -> None:
    pager = __pdbrc_os.environ.get("PAGER", "less")
    basename = __pdbrc_os.path.basename(pager)
    if basename == "bat":
        command = [pager, "--language", "python"]
    else:
        command = [pager]
    with __pdbrc_tempfile.NamedTemporaryFile("w") as file:
        file.write(text)
        file.flush()
        __pdbrc_subprocess.run(command + [file.name], check=True)


def __pdbrc_public_keys(dict: __pdbrc_typing.Dict) -> __pdbrc_typing.Iterator:
    for key in sorted(dict.keys()):
        if not isinstance(key, str) or not key.startswith("_"):
            yield key
