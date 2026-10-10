"""Make CI diagnostics readable through the GitHub Checks API as well as logs."""

import base64
import gzip
import os
from pathlib import Path
import re
import subprocess


# GitHub truncates individual annotation messages at 4 KiB. Stay well below it.
def chunks(text, limit=2800):
    part = []
    size = 0
    for char in text:
        char_size = len(char.encode("utf-8"))
        if size + char_size > limit:
            yield "".join(part)
            part = []
            size = 0
        part.append(char)
        size += char_size
    if part:
        yield "".join(part)


def annotate(level, title, text):
    escaped = text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::{level} title={title}::{escaped}")


status = os.environ.get("BUILD_STATUS", "")
if status == "failure":
    for log in sorted(Path(".ci").glob("*.log")):
        text = log.read_text(errors="replace")[-18000:]
        text = re.sub(r"\x1b\[[0-9;]*m", "", text)
        parts = list(chunks(text))
        for index, part in enumerate(parts, 1):
            annotate("error", f"{log.name} [{index}/{len(parts)}]", part)
elif status == "success":
    for name in ("analyze", "test", "build"):
        log = Path(f".ci/{name}.log")
        if log.exists():
            text = "\n".join(log.read_text(errors="replace").splitlines()[-8:])
            for index, part in enumerate(chunks(text), 1):
                annotate("notice", f"{name}.log summary {index}", part)

# Export the resolved lockfile only while it has not yet been committed. This
# lets the maintainer recover exact dependency versions without a local SDK.
# Compress it to stay below GitHub's per-step annotation count limit, too.
lockfile = Path("pubspec.lock")
if lockfile.exists():
    tracked = subprocess.run(
        ["git", "ls-files", "--error-unmatch", "pubspec.lock"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode == 0
    if not tracked:
        encoded = base64.b64encode(gzip.compress(lockfile.read_bytes(), mtime=0)).decode("ascii")
        for index, part in enumerate(chunks(encoded), 1):
            annotate("notice", f"pubspec-lock-gzip-{index:03d}", part)
