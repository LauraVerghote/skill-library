import json
import re
import sys


PATTERNS = {
    "email": re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.IGNORECASE),
    "phone": re.compile(r"(?<!\w)(?:\+?\d[\d .()-]{7,}\d)(?!\w)"),
}


def redact(text: str) -> dict[str, object]:
    counts: dict[str, int] = {}
    redacted = text
    for label, pattern in PATTERNS.items():
        redacted, count = pattern.subn(f"[{label.upper()}]", redacted)
        counts[label] = count
    return {"text": redacted, "counts": counts}


if __name__ == "__main__":
    source = sys.stdin.read()
    print(json.dumps(redact(source)))