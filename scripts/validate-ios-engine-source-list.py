#!/usr/bin/env python3
"""Check that the iOS CMake target tracks the authoritative AssaultCube client source list."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MAKEFILE = ROOT / "source/src/Makefile"
CMAKE = ROOT / "ios/Engine/CMakeLists.txt"

def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)

make_text = MAKEFILE.read_text(encoding="utf-8")
cmake_text = CMAKE.read_text(encoding="utf-8")

lines = make_text.splitlines()
start = next((i for i, line in enumerate(lines) if line.startswith("CLIENT_OBJS=")), None)
if start is None:
    fail("Could not find CLIENT_OBJS in source/src/Makefile")

objects = []
for line in lines[start + 1:]:
    stripped = line.strip()
    if not stripped:
        break
    token = stripped.removesuffix("\\").strip()
    if token:
        objects.append(token)

if not objects:
    fail("CLIENT_OBJS was empty or could not be parsed")

expected = {Path("source/src") / (obj[:-2] + ".cpp") for obj in objects if obj.endswith(".o")}
if len(expected) != len(objects):
    fail("Unexpected non-.o entry in CLIENT_OBJS")

match = re.search(r"set\(AC_ENGINE_SOURCES(.*?)\n\)", cmake_text, re.S)
if not match:
    fail("Could not find AC_ENGINE_SOURCES in ios/Engine/CMakeLists.txt")

actual = {
    Path("source") / path
    for path in re.findall(r'\$\{AC_ROOT\}/(source/src/[^"]+\.cpp)', match.group(1))
}

missing = sorted(expected - actual)
extra = sorted(actual - expected)
missing_files = sorted(path for path in expected if not (ROOT / path).is_file())

if missing:
    fail("iOS target is missing client sources: " + ", ".join(map(str, missing)))
if extra:
    fail("iOS target contains sources absent from CLIENT_OBJS: " + ", ".join(map(str, extra)))
if missing_files:
    fail("Client source files do not exist: " + ", ".join(map(str, missing_files)))

enet_sources = [
    "callbacks.c", "compress.c", "host.c", "list.c", "packet.c",
    "peer.c", "protocol.c", "unix.c", "win32.c",
]
for name in enet_sources:
    if not (ROOT / "source/enet" / name).is_file():
        fail(f"Missing vendored ENet source: source/enet/{name}")

print(f"Validated {len(expected)} iOS C++ client translation units against CLIENT_OBJS.")
print(f"Validated {len(enet_sources)} vendored ENet C source files.")
