"""Tests for Pyrc custom modules."""

# ruff: noqa: E402

import shlex
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any
from unittest import mock
from unittest.mock import MagicMock, Mock

import pytest

repo_path = Path(__file__).parents[2]
sys.path.append(
    str(repo_path / "ansible_collections/scruffaluff/bootware/roles/lldb/files")
)
sys.path.append(
    str(repo_path / "ansible_collections/scruffaluff/bootware/roles/python/files")
)
patch = mock.patch.dict(
    "sys.modules",
    {
        "lldb": Mock(
            SBCommandReturnObject=MagicMock(),
            SBDebugger=MagicMock(),
            SBExecutionContext=MagicMock(),
            SBFrame=MagicMock(),
            SBValue=MagicMock(),
            eReturnStatusFailed=MagicMock(),
        )
    },
)
patch.start()

import lldbrc
import pdbrc
import pyrc
from pyrc import Expr, Parser


@pytest.mark.parametrize(
    ("line", "count", "expected"),
    [
        ("ls src", 0, "ls src"),
        ("ls src", 2, ""),
        ("ls src   path", 2, "path"),
        ("ls 'src' path", 2, "path"),
    ],
)
def test_drop_tokens(line: str, count: int, expected: str) -> None:
    """Remove tokens from start of line."""
    tokens = shlex.split(line)[:count]
    actual = pyrc.drop_tokens(tokens, line)
    assert actual == expected


@pytest.mark.parametrize(
    ("line", "expected"),
    [
        ("ls src", []),
        ("ls %src", [Expr("src", 3, 7)]),
        ("ls %{src + 'foo'}", [Expr("src + 'foo'", 3, 17)]),
    ],
)
def test_find_exprs(line: str, expected: list[Expr]) -> None:
    """Find expressions in command lines."""
    actual = list(pyrc.find_exprs(line))
    assert actual == expected


@pytest.mark.parametrize(
    ("line", "locals_", "expected"),
    [
        ("ls src", {}, "ls src"),
        ("ls %val", {"val": "longpath"}, "ls longpath"),
        ("echo %{val + 4} hours", {}, "echo %{val + 4} hours"),
        ("echo %{val + 4} hours", {"val": 5}, "echo 9 hours"),
        (
            "touch %val %name",
            {"name": "data search", "val": True},
            "touch True 'data search'",
        ),
    ],
)
def test_parse_exprs(line: str, locals_: dict[str, Any], expected: str) -> None:
    """Evaluation expressions from command lines."""
    pdb = SimpleNamespace(
        curframe=SimpleNamespace(f_globals={}), curframe_locals=locals_
    )
    actual = pyrc.parse_exprs(pdbrc.var_lookup(pdb), line)
    assert actual == expected


@pytest.mark.parametrize(
    ("line", "expected"),
    [
        (" ls src   path", "ls src   path"),
        ("-l ", ""),
        ("-p /folder --login ls ", "ls "),
    ],
)
def test_parse_line(line: str, expected: str) -> None:
    """Parse arguments from start of line."""
    parser = Parser()
    parser.add_argument("-l", "--login", action="store_true")
    parser.add_argument("-p", "--path", default=None)
    rest, _ = parser.parse_line(line)
    assert rest == expected


@pytest.mark.parametrize(
    ("type_"),
    [
        "&[f64]",
        "alloc::vec::Vec<alloc::string::String, alloc::alloc::Global>",
        "int[5]",
        "std::__1::list<char, std::__1::allocator<float> >",
        "std::array",
        "std::vector<int>",
    ],
)
def test_to_py_array(type_: str) -> None:
    """Python conversion uses correct array types."""
    variable = SimpleNamespace(
        children=[], name="list", type=SimpleNamespace(name=type_), value=[1, 4, 6]
    )
    pyvar = lldbrc.to_py(variable)
    actual = type(pyvar)
    assert actual is list


@pytest.mark.parametrize(
    ("type_"),
    ["sint", "float64_", "long long double", "signed float"],
)
def test_to_py_error(type_: str) -> None:
    """Python conversion fails on bad types."""
    variable = SimpleNamespace(name=type_, type=SimpleNamespace(name=type_), value=None)
    with pytest.raises(TypeError, match="Unsupported type"):
        lldbrc.to_py(variable)


@pytest.mark.parametrize(
    ("type_", "expected"),
    [
        ("bfloat16_t", float),
        ("double", float),
        ("float", float),
        ("float32_t", float),
        ("int", int),
        ("long double", float),
        ("unsigned int", int),
    ],
)
def test_to_py_number(type_: str, expected: str) -> None:
    """Python conversion uses correct number types."""
    variable = SimpleNamespace(name="0", type=SimpleNamespace(name=type_), value=0)
    pyvar = lldbrc.to_py(variable)
    actual = type(pyvar)
    assert actual is expected


@pytest.mark.parametrize(
    ("type_"),
    [
        "const char *",
        "std::__1::string",
        "std::__1::string_view",
        "char[7]",
        "&str",
        "alloc::string::String",
        "std::path::PathBuf",
        "std::ffi::os_str::OsString",
    ],
)
def test_to_py_string(type_: str) -> None:
    """Python conversion uses correct string types."""
    variable = SimpleNamespace(
        GetSummary=lambda: "string",
        name="string",
        type=SimpleNamespace(name=type_),
        value="string",
    )
    pyvar = lldbrc.to_py(variable)
    actual = type(pyvar)
    assert actual is str
