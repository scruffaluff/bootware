"""Tests for Pyrc custom modules."""

import sys
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import pytest

repo_path = Path(__file__).parents[2]
sys.path.append(str(repo_path / "ansible_collections/scruffaluff/bootware"))
from roles.python.files import pdbrc  # noqa: E402
from roles.python.files.pdbrc import Expr  # noqa: E402


@pytest.mark.parametrize(
    ("line", "expected"),
    [
        ("ls src", []),
        ("ls %src", [Expr("src", 3, 7)]),
        ("ls %{src + 'foo'}", [Expr("src + 'foo'", 3, 17)]),
    ],
)
def test_find_exprs(line: str, expected: str) -> None:
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
        ("touch %val %name", {"name": "data", "val": True}, "touch True data"),
    ],
)
def test_parse_exprs(line: str, locals_: dict[str, Any], expected: str) -> None:
    """Evaluation expressions from command lines."""
    pdb = SimpleNamespace(
        curframe=SimpleNamespace(f_globals=None), curframe_locals=locals_
    )
    actual = pdbrc.parse_exprs(pdb, line)
    assert actual == expected
