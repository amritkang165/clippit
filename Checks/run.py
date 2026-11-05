# Purpose: Build the app and run isolated checks without requiring XCTest or Xcode.
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent.parent
subprocess.run(["swift", "build"], cwd=root, check=True)
build = Path(subprocess.check_output(["swift", "build", "--show-bin-path"], cwd=root, text=True).strip())
sources = sorted(str(p) for p in (root / "Clippit").glob("*.swift") if p.name != "ClippitApp.swift")
executable = build / "ClippitChecks"
subprocess.run([
    "xcrun", "swiftc", "-I", str(build / "Modules"), *sources,
    *[str(p) for p in sorted((root / "Checks").glob("*.swift"))],
    *[str(p) for p in (build / "SQLite.build").glob("*.swift.o")],
    "-lsqlite3", "-o", str(executable)
], cwd=root, check=True)
subprocess.run([str(executable)], cwd=root, check=True)
