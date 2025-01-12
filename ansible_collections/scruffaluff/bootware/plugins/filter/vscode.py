"""Custom filters for VSCode."""

import base64
import hashlib
from typing import Callable, Dict


class FilterModule:
    """Custom filters for VSCode."""

    def filters(self) -> Dict[str, Callable]:
        """Generate table of filters."""

        return {"vscode_checksum": self.vscode_checksum}

    def vscode_checksum(self, value: str) -> str:
        """Compute VSCode product.json compatible checksum."""

        hash = hashlib.sha256()
        hash.update(value.encode())
        digest = hash.digest()
        encode = base64.b64encode(digest).decode()
        return encode.replace("=", "")
