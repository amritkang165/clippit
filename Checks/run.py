# Purpose: Build the app and run isolated checks without requiring XCTest or Xcode.
from pathlib import Path
import argparse
import json
import subprocess

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument("--suite", choices=["all", "core", "ocr"], default="all")
args = parser.parse_args()
# Verify every SwiftPM app source is present in Xcode's actual sources phase.
project = json.loads(subprocess.check_output([
    "plutil", "-convert", "json", "-o", "-", str(root / "Clippit.xcodeproj/project.pbxproj")
], text=True))["objects"]
source_ids = {entry for obj in project.values() if obj.get("isa") == "PBXSourcesBuildPhase"
              for entry in obj["files"]}
included = {project[project[entry]["fileRef"]].get("path") for entry in source_ids}
missing = {p.name for p in (root / "Clippit").glob("*.swift")} - included
if missing:
    raise SystemExit(f"Swift files missing from Xcode Sources: {sorted(missing)}")
subprocess.run(["swift", "build", "--build-system", "native"], cwd=root, check=True)
build = Path(subprocess.check_output(["swift", "build", "--build-system", "native", "--show-bin-path"], cwd=root, text=True).strip())
sources = sorted(str(p) for p in (root / "Clippit").glob("*.swift") if p.name != "ClippitApp.swift")
executable = build / "ClippitChecks"
subprocess.run([
    "xcrun", "swiftc", "-I", str(build / "Modules"), *sources,
    *[str(p) for p in sorted((root / "Checks").glob("*.swift"))],
    *[str(p) for p in (build / "SQLite.build").glob("*.swift.o")],
    "-lsqlite3", "-o", str(executable)
], cwd=root, check=True)
subprocess.run([str(executable), args.suite], cwd=root, check=True)
