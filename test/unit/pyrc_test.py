"""Tests for Pyrc custom modules."""

import shlex
import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import pytest

repo_path = Path(__file__).parents[2]
sys.path.append(str(repo_path / "ansible_collections/scruffaluff/bootware"))
from roles.python.files import pdbrc  # noqa: E402
from roles.python.files.pdbrc import Expr, Parser  # noqa: E402


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
    actual = pdbrc.drop_tokens(tokens, line)
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
    actual = list(pdbrc.find_exprs(line))
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
        curframe=SimpleNamespace(f_globals=None), curframe_locals=locals_
    )
    actual = pdbrc.parse_exprs(pdb, line)
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
