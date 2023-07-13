#!/usr/bin/python
# -*- coding: utf-8 -*-


from configparser import ConfigParser
import os
from pathlib import Path
import platform

from ansible.module_utils.basic import AnsibleModule


DOCUMENTATION = r"""
---
author:
    - Macklan Weinstein (@scruffaluff)
description: Find name and path of Firefox default profile for current user.
module: firefox_default_profile
options: {}
short_description: Firefox default profile information
version_added: "0.5.4"
"""

EXAMPLES = r"""
---
- name: Find Firefox default profile information
  firefox_default_profile: {}
  register: profile
"""

RETURN = r"""
---
name:
  description: Firefox default profile name
  returned: always
  sample: 8hs6hkt.default-release
  type: strg
path:
  description: Firefox default profile path
  returned: always
  sample: /home/user/.mozilla/firefox/8hs6hkt.default-release
  type: str
"""


def default_profile(module: AnsibleModule, path: Path) -> str:
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

    for _, data in parser.items():
        if "default" in data:
            return data["default"]
    else:
        module.fail_json(
            msg=f"No default profile found in '{path}'.",
        )


def main() -> None:
    """Find name and path of Firefox default profile for current user."""
    result = {"changed": False, "name": "", "path": ""}
    module = AnsibleModule(argument_spec={}, supports_check_mode=True)
    if module.check_mode:
        module.exit_json(**result)

    system = platform.system()
    path = profiles_path(module, system)
    default = default_profile(module, path)

    try:
        default = default_profile(module, path)
    except Exception as exception:
        module.fail_json(
            msg=(
                "Unable to parse default Firefox profile from profiles database"
                f" at '{path}'. Error: {exception}"
            ),
            **result,
        )

    result["name"] = default
    result["path"] = str(path.parent / default)
    module.exit_json(**result)


def profiles_path(module: AnsibleModule, system: str) -> Path:
    """Find Firefox profiles file path."""
    if system == "Darwin":
        path = Path.home() / "/Library/Application Support/Firefox/profiles.ini"
    elif system in ["FreeBSD", "Linux"]:
        path = Path.home() / ".mozilla/firefox/profiles.ini"
    elif system == "Windows":
        try:
            app_data = os.environ.get["APPDATA"]
        except KeyError:
            module.fail_json(
                msg=(
                    "Module requires environment variable APPDATA to be defined"
                    "on Windows."
                )
            )
        path = Path(app_data) / "Mozilla/Firefox/profiles.ini"
    else:
        module.fail_json(
            msg=f"Module does not support operating system '{system}'.",
        )

    if not path.exists():
        module.fail_json(
            msg=f"Firefox profiles database path '{path}' does not exist.",
        )
    return path


if __name__ == "__main__":
    main()
