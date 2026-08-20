"""Fail when production mobile code or an APK contains network capability."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "apps" / "mobile"
MAIN_MANIFEST = MOBILE / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
SOURCE_ROOTS = (MOBILE / "lib", ROOT / "packages" / "liuyao_engine" / "lib")
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"
NETWORK_PERMISSIONS = {
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.CHANGE_NETWORK_STATE",
}
FORBIDDEN_SOURCE_MARKERS = {
    "package:http/": "package:http",
    "package:dio/": "package:dio",
    "HttpClient(": "dart:io HttpClient",
    "WebSocket.connect": "WebSocket.connect",
    "Socket.connect": "Socket.connect",
    "Uri.http(": "Uri.http",
    "Uri.https(": "Uri.https",
}


def _source_checks() -> list[str]:
    failures: list[str] = []
    manifest = ElementTree.parse(MAIN_MANIFEST).getroot()
    permissions = {
        item.attrib.get(f"{ANDROID_NS}name", "")
        for item in manifest.findall("uses-permission")
    }
    for permission in sorted(permissions & NETWORK_PERMISSIONS):
        failures.append(f"main AndroidManifest requests {permission}")

    for source_root in SOURCE_ROOTS:
        for path in source_root.rglob("*.dart"):
            text = path.read_text(encoding="utf-8")
            for marker, label in FORBIDDEN_SOURCE_MARKERS.items():
                if marker in text:
                    failures.append(f"{path.relative_to(ROOT)} uses {label}")
    return failures


def _apk_checks(apk: Path) -> list[str]:
    environment = os.environ.copy()
    android_studio_java = Path(
        "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    )
    if not environment.get("JAVA_HOME") and android_studio_java.is_dir():
        environment["JAVA_HOME"] = str(android_studio_java)
    local_properties = MOBILE / "android" / "local.properties"
    if local_properties.is_file() and not environment.get("ANDROID_HOME"):
        for line in local_properties.read_text(encoding="utf-8").splitlines():
            if line.startswith("sdk.dir="):
                sdk = line.removeprefix("sdk.dir=").replace(r"\:", ":")
                environment["ANDROID_HOME"] = sdk
                environment.setdefault("ANDROID_SDK_ROOT", sdk)
                break

    sdk_analyzer: Path | None = None
    sdk_root = environment.get("ANDROID_HOME") or environment.get("ANDROID_SDK_ROOT")
    if sdk_root:
        candidate = Path(sdk_root) / "cmdline-tools" / "latest" / "bin" / "apkanalyzer"
        if candidate.is_file():
            sdk_analyzer = candidate
    analyzer = str(sdk_analyzer) if sdk_analyzer else shutil.which("apkanalyzer")
    if analyzer is None:
        return ["apkanalyzer is unavailable; APK permissions were not verified"]

    process = subprocess.run(
        [analyzer, "manifest", "permissions", str(apk)],
        text=True,
        capture_output=True,
        env=environment,
    )
    if process.returncode != 0:
        detail = (process.stderr or process.stdout).strip()
        return [f"apkanalyzer failed: {detail}"]
    permissions = set(process.stdout.splitlines())
    return [
        f"APK requests {permission}"
        for permission in sorted(permissions & NETWORK_PERMISSIONS)
    ]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path)
    args = parser.parse_args()
    failures = _source_checks()
    if args.apk is not None:
        if not args.apk.is_file():
            raise SystemExit(f"APK not found: {args.apk}")
        failures.extend(_apk_checks(args.apk))
    if failures:
        raise SystemExit("offline release check failed:\n- " + "\n- ".join(failures))
    suffix = f" and {args.apk}" if args.apk else ""
    print(f"offline release check passed for production sources{suffix}")


if __name__ == "__main__":
    main()
