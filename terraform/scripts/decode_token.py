#!/usr/bin/env python3

import argparse
import base64
import json
import os
from pathlib import Path


def decode_payload(token: str) -> dict:
    parts = token.strip().split(".")
    if len(parts) != 3:
        raise ValueError("The supplied value is not a JWT.")

    payload = parts[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(
        base64.urlsafe_b64decode(payload).decode("utf-8")
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Decode a JWT payload for lab inspection. "
            "This does not verify the JWT signature."
        )
    )
    parser.add_argument(
        "--token-file",
        default=os.environ.get(
            "TOKEN_FILE",
            "/tmp/security-lab-access-token",
        ),
    )
    arguments = parser.parse_args()

    token = Path(arguments.token_file).read_text(
        encoding="utf-8"
    )
    print(
        "Inspection only: this script does not verify the JWT signature."
    )
    print(json.dumps(decode_payload(token), indent=2))


if __name__ == "__main__":
    main()

