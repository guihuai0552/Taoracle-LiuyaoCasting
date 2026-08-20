"""Exhaustively compare Python and Dart Liuyao structural calculations.

The full matrix covers every possible base/changed hexagram pair (64 × 64).
It deliberately excludes almanac and interpretive annotations, which have
their own date-based parity checks.

Schema v14 adds line-level Nayin and schema v15 adds changed-hexagram Shi/Ying.
This legacy Python implementation predates those fields, so the compatibility
projection removes them before comparison. The new fields have dedicated Dart
golden tests; Nayin is also checked across all 60 Jiazi by the private parity
gate.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "apps" / "mobile"
sys.path.insert(0, str(ROOT / "services" / "liuyao-engine"))

from app.base_chart import build_base_chart  # noqa: E402
from app.twenty_eight_mansions import build_twenty_eight_mansions  # noqa: E402

PILLARS = {
    "year": {"gan_zhi": "丙午", "stem": "丙", "branch": "午"},
    "month": {"gan_zhi": "乙未", "stem": "乙", "branch": "未"},
    "day": {"gan_zhi": "甲子", "stem": "甲", "branch": "子"},
    "hour": {"gan_zhi": "乙丑", "stem": "乙", "branch": "丑"},
}


def _line_values(base_code: int, changed_code: int) -> list[int]:
    values: list[int] = []
    for position in range(6):
        base_is_yang = bool(base_code & (1 << position))
        changed_is_yang = bool(changed_code & (1 << position))
        if base_is_yang:
            values.append(7 if changed_is_yang else 9)
        else:
            values.append(6 if changed_is_yang else 8)
    return values


def _samples(quick: bool) -> list[list[int]]:
    if quick:
        pairs = [(0, 0), (63, 63), (57, 49), (7, 56), (42, 21)]
    else:
        pairs = [(base, changed) for base in range(64) for changed in range(64)]
    return [_line_values(base, changed) for base, changed in pairs]


def _python_snapshot(values: list[int]) -> dict[str, Any]:
    chart, _, _ = build_base_chart(
        values,
        project_pillars=PILLARS,
        provider_data={},
        verify_provider=False,
    )
    mansions, _ = build_twenty_eight_mansions(chart["base"])
    return {
        "line_values": values,
        "hexagram": chart,
        "twenty_eight_mansions": mansions,
    }


def _without_nayin(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: _without_nayin(item)
            for key, item in value.items()
            if key != "nayin"
        }
    if isinstance(value, list):
        return [_without_nayin(item) for item in value]
    return value


def _legacy_projection(value: dict[str, Any]) -> dict[str, Any]:
    output = _without_nayin(value)
    changed = output.get("hexagram", {}).get("changed")
    if changed is not None:
        changed.pop("shi_position", None)
        changed.pop("ying_position", None)
        for line in changed.get("lines", []):
            line.pop("role", None)
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--quick", action="store_true")
    args = parser.parse_args()
    samples = _samples(args.quick)
    process = subprocess.run(
        ["dart", "run", "tool/liuyao_structure_probe.dart"],
        cwd=MOBILE,
        input=json.dumps(samples, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    actual_values = json.loads(process.stdout)

    failures: list[dict[str, Any]] = []
    for values, actual in zip(samples, actual_values, strict=True):
        expected = _python_snapshot(values)
        actual = _legacy_projection(actual)
        if actual != expected:
            failures.append(
                {"line_values": values, "expected": expected, "actual": actual}
            )
            if len(failures) >= 3:
                break
    if failures:
        print(json.dumps(failures, ensure_ascii=False, indent=2))
        raise SystemExit(
            f"offline Liuyao structure parity failed; showing {len(failures)} differences"
        )
    print(f"offline Liuyao structure parity passed: {len(samples)} base/changed pairs")


if __name__ == "__main__":
    main()
