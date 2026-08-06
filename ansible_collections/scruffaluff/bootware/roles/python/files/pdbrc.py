"""Python debugger settings file."""

# ruff: noqa: BLE001, D403, D415, SLF001

from __future__ import annotations

import os
import shlex
import traceback
from typing import TYPE_CHECKING, Any, cast

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
        # Mypy is incorrect since the method is defined at
        # https://docs.python.org/3/library/pdb.html#pdb.pm.
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
        object_ = pyrc.parse(self, rest)
        pyrc.cat(object_, regex=args.regex)
    except Exception as exception:
        pyrc.error(exception)
        return


def do_doc(self: Pdb, line: str) -> None:
    """doc [object]

    Print object signature and documentation in default pager.
    """
    try:
        object_ = pyrc.parse(self, line)
    except Exception as exception:
        pyrc.error(exception)
        return

    if object_ is None:
        try:
            docstring = pyrc.curframe(self).f_globals["__doc__"]
        except KeyError:
            pyrc.error("Unable to find current module docstring")
        else:
            pyrc.cat(docstring)
    else:
        pyrc.doc(object_)


def do_edit(self: Pdb, line: str) -> None:
    """ed(it) [object]

    Open object source code or current module in default text editor.
    """
    try:
        object_ = pyrc.parse(self, line)
    except Exception as exception:
        pyrc.error(exception)
    else:
        pyrc.edit(object_, pyrc.curframe(self))


def do_nextlist(self: Pdb, _arg: str) -> int:
    """nl | nextlist

    Continue execution until the next line and then list source code.
    """
    self.set_next(pyrc.curframe(self))
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
    pyrc.nushell(rest, cwd=args.cwd)


def do_shell(self: Pdb, line: str) -> None:
    """sh(ell) [command]

    Execute command or start interactive default shell session.
    """
    line_ = pyrc.parse_exprs(var_lookup(self), line)
    arguments = list(map(str, map(os.path.expanduser, shlex.split(line_.strip()))))
    pyrc.shell(arguments)


def do_steplist(self: Pdb, arg: str) -> int:
    """sl | steplist

    Execution current line and then list source code.
    """
    self.set_step()
    self.do_list(arg)
    # Returning "1" appears to be necessary for subsequent calls to work.
    return 1


def setup(pdb: Pdb) -> None:
    """Extend PDB with custom functionality."""
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
