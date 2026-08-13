"""Python debugger settings file."""

# Explicit optional, union, and quoted types are used to support older Python versions.
# ruff: noqa: BLE001, D403, D415, SLF001, UP007

from __future__ import annotations

import os
import shlex
import traceback
from subprocess import CalledProcessError
from typing import TYPE_CHECKING, Any, Union, cast, no_type_check

import plotrc
import pyrc

if TYPE_CHECKING:
    from collections.abc import Callable
    from pdb import Pdb
    from types import FrameType, TracebackType


def break_exception(self: Pdb) -> Callable:
    """Create exception handler for debugging."""

    def excepthook(
        type_: type[BaseException], value: BaseException, trace: TracebackType
    ) -> None:
        """Start debugger on unhandled exception."""
        traceback.print_exception(type_, value, trace)
        self.pm()

    return excepthook


def curframe(pdb: Pdb) -> FrameType:
    """Attribute accessor wrapper to satisfy type checkers."""
    return cast("FrameType", pdb.curframe)


def do_cat(self: Pdb, line: str) -> None:
    """cat -r, --regex <regex> object

    Print object catalog with default pager.
    """
    parser = pyrc.Parser()
    parser.add_argument("-r", "--regex", default=None)
    rest, args = parser.parse_line(line)

    try:
        object_ = parse(self, rest)
        pyrc.cat(object_, regex=args.regex)
    except Exception as exception:
        error(exception)
        return


def do_doc(self: Pdb, line: str) -> None:
    """doc [object]

    Print object signature and documentation in default pager.
    """
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
            pyrc.cat(docstring)
    else:
        pyrc.doc(object_)


def do_edit(self: Pdb, line: str) -> None:
    """ed(it) [object]

    Open object source code or current module in default text editor.
    """
    try:
        object_ = parse(self, line)
    except Exception as exception:
        error(exception)
    else:
        pyrc.edit(object_, curframe(self))


def do_nextlist(self: Pdb, _arg: str) -> int:
    """nl | nextlist

    Continue execution until the next line and then list source code.
    """
    self.set_next(curframe(self))
    self.do_list("")
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


def do_nushell(self: Pdb, line: str) -> None:
    """nu(shell) -c, --cwd <path> [expression]

    Execute Nushell expression or start interactive session.
    """
    line_ = pyrc.parse_exprs(var_lookup(self), line)
    parser = pyrc.Parser()
    parser.add_argument("-c", "--cwd", default=None)
    rest, args = parser.parse_line(line_)
    try:
        pyrc.nushell(rest, cwd=args.cwd)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)


def do_shell(self: Pdb, line: str) -> None:
    """sh(ell) [command]

    Execute command or start interactive default shell session.
    """
    line_ = pyrc.parse_exprs(var_lookup(self), line)
    arguments = list(map(str, map(os.path.expanduser, shlex.split(line_.strip()))))
    try:
        pyrc.shell(arguments)
    except (CalledProcessError, FileNotFoundError) as exception:
        error(exception)


def do_steplist(self: Pdb, arg: str) -> int:
    """sl | steplist

    Execution current line and then list source code.
    """
    self.set_step()
    self.do_list(arg)
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


def error(message: Union[str, Exception]) -> None:
    """Print error to console."""
    if isinstance(message, str):
        print(f"*** {message}")
    else:
        print(f"*** {type(message).__name__}: {message}")


def parse(pdb: Pdb, input_: str) -> Any:  # noqa: ANN401
    """Parse and possibly execute command line input."""
    if input_.strip():
        return eval(input_, curframe(pdb).f_globals, pdb.curframe_locals)  # noqa: S307
    return None


@no_type_check
def setup(pdb: Pdb) -> None:
    """Add custom commands to PDB."""
    plotrc.export()
    pyrc.export()

    pdb.do_cat = do_cat
    pdb.complete_cat = pdb._complete_expression
    pdb.do_doc = do_doc
    pdb.complete_doc = pdb._complete_expression
    pdb.do_edit = do_edit
    pdb.complete_edit = pdb._complete_expression
    pdb.do_nl = do_nextlist
    pdb.do_nextlist = do_nextlist
    pdb.do_nu = do_nushell
    pdb.do_nushell = do_nushell
    pdb.do_sh = do_shell
    pdb.do_shell = do_shell
    pdb.do_sl = do_steplist
    pdb.do_steplist = do_steplist


def var_lookup(pdb: Pdb) -> Callable[[str], Any]:
    """Generate a variable lookup function for a debugger frame."""

    def lookup(name: str) -> Any:  # noqa: ANN401
        if name in pdb.curframe_locals:
            return pdb.curframe_locals[name]
        if name in curframe(pdb).f_globals:
            return curframe(pdb).f_globals[name]
        msg = f"Unable to find variable '{name}'."
        raise ValueError(msg)

    return lookup
