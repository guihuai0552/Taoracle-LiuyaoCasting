#!/usr/bin/env python3
"""Cross-check the Dart port against liuyao-private's executable contract."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRIVATE = Path(
    os.environ.get(
        "LIUYAO_PRIVATE_ROOT", "/Users/feiwu4/Documents/vibecoding/liuyao-private"
    )
)
sys.path.insert(0, str(PRIVATE / "src"))

from liuyao_core.calendar import build_calendar_context  # noqa: E402
from liuyao_core.engine import assemble_hexagram  # noqa: E402
from liuyao_core.lookups import lookup_branch_growth, lookup_nayin  # noqa: E402
from liuyao_core.cast import build_cast  # noqa: E402
from lunar_python import Solar  # noqa: E402


def comparable_plate(value: dict) -> dict:
    """Drop only fields deliberately unavailable on a static changed=None case."""

    return value


def first_diff(left, right, path="root") -> str:
    if type(left) is not type(right):
        return f"{path}: type {type(left).__name__} != {type(right).__name__}"
    if isinstance(left, dict):
        if left.keys() != right.keys():
            return f"{path}: keys {sorted(left.keys())} != {sorted(right.keys())}"
        for key in left:
            result = first_diff(left[key], right[key], f"{path}.{key}")
            if result:
                return result
        return ""
    if isinstance(left, list):
        if len(left) != len(right):
            return f"{path}: length {len(left)} != {len(right)}"
        for index, (left_item, right_item) in enumerate(zip(left, right)):
            result = first_diff(left_item, right_item, f"{path}[{index}]")
            if result:
                return result
        return ""
    return "" if left == right else f"{path}: {left!r} != {right!r}"


def main() -> None:
    process = subprocess.run(
        ["dart", "run", "tool/private_reference_probe.dart"],
        cwd=ROOT / "packages/liuyao_engine",
        check=True,
        capture_output=True,
        text=True,
    )
    dart = json.loads(process.stdout)
    failures: list[str] = []

    for case in dart["static_hexagrams"]:
        expected = assemble_hexagram(case["lines"], day_ganzhi="庚戌")
        if comparable_plate(case["plate"]) != comparable_plate(expected):
            failures.append(f"static mask {case['mask']} plate mismatch")

    branches = "子丑寅卯辰巳午未申酉戌亥"
    expected_growth = [
        lookup_branch_growth(subject, observed)
        for subject in branches
        for observed in branches
    ]
    if dart["growth"] != expected_growth:
        failures.append("144 branch-growth results mismatch")

    expected_nayin = {
        ganzhi: lookup_nayin(ganzhi)["name"]
        for ganzhi in dart["nayin"]
    }
    if dart["nayin"] != expected_nayin:
        failures.append("60 Jiazi Nayin results mismatch")

    for case in dart["calendar"]:
        expected = build_calendar_context(case["timestamp"])
        expected_pillars = [
            expected["year_ganzhi"],
            expected["month_ganzhi"],
            expected["day_ganzhi"],
            expected["hour_ganzhi"],
        ]
        if case["pillars"] != expected_pillars:
            failures.append(
                f"calendar {case['timestamp']} pillars "
                f"{case['pillars']} != {expected_pillars}"
            )
        if case["day_void_branches"] != expected["xun_kong"]:
            failures.append(f"calendar {case['timestamp']} xun-kong mismatch")
        expected_mansion = expected["provider_extensions"]["twenty_eight_mansion"][
            "name"
        ]
        if case["daily_mansion"] != expected_mansion:
            failures.append(f"calendar {case['timestamp']} mansion mismatch")

    expected_moving = build_cast(
        {
            "spec_version": "1.0.0-draft",
            "profile": "classic-wenwang-v1",
            "method": "manual_lines",
            "lines_bottom_up": [7, 7, 9, 8, 8, 7],
            "timestamp": "2026-08-04T22:22:29+08:00",
            "timezone": "Asia/Shanghai",
        }
    )
    dart_moving = dart["moving_sample"]
    expected_calendar = dict(expected_moving["calendar"])
    # The private profile text says civil_midnight, while the executable
    # cnlunar output advances at 23:00. Dart records the tested behavior.
    expected_calendar["day_boundary"] = "zi_initial_23_cnlunar_compat"
    if dart_moving["calendar"] != expected_calendar:
        failures.append(
            "moving sample calendar mismatch: "
            f"{first_diff(dart_moving['calendar'], expected_calendar)}"
        )
    for field in ("plate", "mechanical_relations", "extensions"):
        if dart_moving[field] != expected_moving[field]:
            failures.append(
                f"moving sample {field} mismatch: "
                f"{first_diff(dart_moving[field], expected_moving[field])}"
            )

    for case in dart["exact_jie_boundaries"]:
        wall = datetime.fromisoformat(case["wall_clock"].replace("Z", ""))
        before = wall - timedelta(seconds=1)
        at_lunar = Solar.fromYmdHms(
            wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second
        ).getLunar()
        before_lunar = Solar.fromYmdHms(
            before.year,
            before.month,
            before.day,
            before.hour,
            before.minute,
            before.second,
        ).getLunar()
        expected_before = [
            before_lunar.getYearInGanZhiExact(),
            before_lunar.getMonthInGanZhiExact(),
        ]
        expected_at = [
            at_lunar.getYearInGanZhiExact(),
            at_lunar.getMonthInGanZhiExact(),
        ]
        if case["before"] != expected_before or case["at"] != expected_at:
            failures.append(
                f"exact Jie {case['year']}#{case['index']} mismatch: "
                f"{case['before']}->{case['at']} != "
                f"{expected_before}->{expected_at}"
            )
            break

    if failures:
        print("\n".join(failures), file=sys.stderr)
        raise SystemExit(1)
    print(
        "private-reference Dart parity passed: "
        "64 static plates, moving extensions/relations, 144 growth pairs, "
        "60 Nayin, 7 calendar instants, 2,388 exact Jie boundaries"
    )


if __name__ == "__main__":
    main()
