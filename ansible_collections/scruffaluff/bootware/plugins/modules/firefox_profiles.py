#!/usr/bin/python
# -*- coding: utf-8 -*-


from configparser import ConfigParser
from pathlib import Path
import platform
import subprocess
from typing import List

from ansible.module_utils.basic import AnsibleModule


DOCUMENTATION = r"""
---
author:
    - Macklan Weinstein (@scruffaluff)
description: Find path of each Firefox profile folder for current user.
module: firefox_profiles
options: {}
short_description: Firefox profile paths
version_added: "0.6.0"
"""

EXAMPLES = r"""
---
- name: Find Firefox profile paths
  scruffaluff.bootware.firefox_profiles: {}
  register: profiles
"""

RETURN = r"""
---
path:
  description: Firefox profile_paths
  returned: always
  sample:
    - /home/user/.mozilla/firefox/8hs6hkt.default-release
  type: list
"""


def main() -> None:
    """Find name and path of Firefox default profile for current user."""
    result = {"changed": False, "name": "", "path": ""}
    module = AnsibleModule(
        argument_spec={
            "user": {"default": "", "required": False, "type": "str"}
        },
        supports_check_mode=True,
    )
    if module.check_mode:
        module.exit_json(**result)

    system = platform.system()
    database = profiles_database(module, system)
    try:
        paths = profiles_paths(module, database)
    except Exception as exception:
        module.fail_json(
            msg=(
                "Unable to parse default Firefox profile from profiles database"
                f" at '{database}'. Error: {exception}"
            ),
            **result,
        )

    result["paths"] = [str(database.parent / path) for path in paths]
    module.exit_json(**result)


def profiles_database(module: AnsibleModule, system: str) -> Path:
    """Find Firefox profiles database."""
    user = module.params["user"]
    if system == "Darwin":
        user_home = Path(f"/Users/{user}") if user else Path.home()
        path = user_home / "Library/Application Support/Firefox/profiles.ini"
    elif system in ["FreeBSD", "Linux"]:
        user_home = Path(f"/home/{user}") if user else Path.home()
        path = user_home / ".mozilla/firefox/profiles.ini"
    else:
        module.fail_json(
            msg=f"Module does not support operating system '{system}'.",
        )

    # Firefox profiles database may not exist after initial Firefox install. If
    # so, try creating a default profile from the command line.
    if not path.exists():
        subprocess.run(
            ["firefox", "--headless", "--createprofile", "default"],
            capture_output=True,
            check=True,
        )

    if not path.exists():
        module.fail_json(
            msg=f"Firefox profiles database path '{path}' does not exist.",
        )
    return path


def profiles_paths(module: AnsibleModule, path: Path) -> List[str]:
    """Parse default profile from Firefox profiles file."""
    parser = ConfigParser()
    try:
        parser.read(path)
    except Exception as exception:
        module.fail_json(
            msg=(
                "Unable to read default Firefox profile from profiles database"
                f" at '{path}'. Error: {exception}"
            )
        )

    paths = []
    for section, data in parser.items():
        if section.startswith("Profile") and "path" in data:
            paths.append(data["path"])
        elif data.get("locked") and "default" in data:
            paths.append(data["default"])

    snap_path = Path.home() / "snap"
    return [
        path for path in set(paths) if not Path(path).is_relative_to(snap_path)
    ]


if __name__ == "__main__":
    main()
