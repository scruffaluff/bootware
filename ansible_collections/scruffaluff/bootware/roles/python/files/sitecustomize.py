"""Custom utilities for Python.

For more information, visit https://docs.python.org/3/library/site.html.
"""

import builtins
import importlib
import os
import subprocess
import sys
from pathlib import Path


def debugadapt(host: str = "localhost", port: int = 5678) -> None:
    """Start a debug adapter protocol session with debugpy."""
    os.environ["DEBUGPY_LOG_DIR"] = str(Path(__file__).parent / "log")
    packages = str(Path(__file__).parent / "package")
    sys.path.append(packages)
    try:
        debugpy = importlib.import_module("debugpy")
    except ModuleNotFoundError:
        subprocess.run(
            [
                sys.executable,
                "-m",
                "pip",
                "install",
                "--target",
                packages,
                "debugpy",
            ],
            check=True,
        )
        debugpy = importlib.import_module("debugpy")

    debugpy.listen((host, port))
    print(f"Debugpy session listening at {host}:{port}.")
    debugpy.wait_for_client()


# Export utilities as Python builtins.
builtins.debugadapt = debugadapt
