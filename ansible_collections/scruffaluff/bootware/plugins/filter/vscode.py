"""Custom filters for VSCode."""

import base64
import hashlib
from collections.abc import Callable


class FilterModule:
    """Custom filters for VSCode."""

    def filters(self) -> dict[str, Callable]:
        """Generate table of filters."""
        return {"vscode_checksum": self.vscode_checksum}

    def vscode_checksum(self, value: str) -> str:
        """Compute VSCode product.json compatible checksum."""
        hash_ = hashlib.sha256()
        hash_.update(value.encode())
        digest = hash_.digest()
        encode = base64.b64encode(digest).decode()
        return encode.replace("=", "")
