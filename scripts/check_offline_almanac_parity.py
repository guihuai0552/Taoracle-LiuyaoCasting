"""Check legacy-compatible almanac fields against the frozen Python adapter.

Exact year/month Jie boundaries, canonical Nayin spellings and the thirteenth
23:00 Zi slot intentionally supersede this adapter. They are exhaustively
checked by ``check_private_reference_dart_parity.py`` instead.

Run from the repository root:
  services/liuyao-engine/.venv/bin/python scripts/check_offline_almanac_parity.py
"""

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MOBILE = ROOT / "apps" / "mobile"
sys.path.insert(0, str(ROOT / "services" / "liuyao-engine"))

from cnlunar.config import START_YEAR, lunarNewYearList  # noqa: E402
from cnlunar.solar24 import getTheYearAllSolarTermsList  # noqa: E402

from app.almanac import calculate_almanac  # noqa: E402

SHANGHAI = timezone(timedelta(hours=8))

NAYIN_ALIASES = {
    "井泉水": "泉中水",
    "砂中金": "沙中金",
    "砂中土": "沙中土",
}


def _samples(quick: bool) -> list[datetime]:
    years = [2024, 2025, 2026] if quick else range(1902, 2100)
    values: set[datetime] = set()
    for year in years:
        encoded_new_year = lunarNewYearList[year - START_YEAR]
        new_year = datetime(
            year,
            (encoded_new_year >> 5) & 0x3,
            encoded_new_year & 0x1F,
            12,
            tzinfo=SHANGHAI,
        )
        for delta in (-1, 0, 1):
            values.add(new_year + timedelta(days=delta))

        term_days = getTheYearAllSolarTermsList(year)
        for index, day in enumerate(term_days):
            term = datetime(year, index // 2 + 1, day, 12, tzinfo=SHANGHAI)
            for delta in (-1, 0, 1):
                values.add(term + timedelta(days=delta))

        for month, day in ((1, 1), (3, 15), (6, 15), (9, 15), (12, 31)):
            values.add(datetime(year, month, day, 12, tzinfo=SHANGHAI))
        values.add(datetime(year, 2, 4, 22, 30, tzinfo=SHANGHAI))
        values.add(datetime(year, 2, 4, 23, 30, tzinfo=SHANGHAI))
    return sorted(values)


def _normalize_python(value: dict[str, Any]) -> dict[str, Any]:
    lunar = dict(value["lunar"])
    # Dart wheel intentionally omits cnlunar's 大/小 suffix from month_cn.
    lunar["month_cn"] = lunar["month_cn"].removesuffix("大").removesuffix("小")
    pillars = [
        {
            **pillar,
            "nayin": NAYIN_ALIASES.get(pillar["nayin"], pillar["nayin"]),
        }
        for pillar in value["four_pillars"]
        if pillar["position"] in {"day", "hour"}
    ]
    return {
        "lunar": lunar,
        "day_hour_pillars": pillars,
        "two_hour_pillars": value["two_hour_pillars"][:12],
        "current_two_hour_index": value["current_two_hour_index"],
        "solar_terms": value["solar_terms"],
        "wealth_god": {
            "direction": value["wealth_god"]["direction"],
            "raw": value["wealth_god"]["raw"],
        },
    }


def _normalize_dart(value: dict[str, Any]) -> dict[str, Any]:
    return {
        "lunar": value["lunar"],
        "day_hour_pillars": [
            pillar
            for pillar in value["four_pillars"]
            if pillar["position"] in {"day", "hour"}
        ],
        "two_hour_pillars": value["two_hour_pillars"][:12],
        "current_two_hour_index": value["current_two_hour_index"],
        "solar_terms": {
            "today": value["solar_terms"]["today"],
            "next": value["solar_terms"]["next"],
        },
        "wealth_god": {
            "direction": value["wealth_god"]["direction"],
            "raw": value["wealth_god"]["raw"],
        },
    }


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--quick", action="store_true")
    args = parser.parse_args()
    samples = _samples(args.quick)
    iso_values = [value.isoformat() for value in samples]
    process = subprocess.run(
        ["dart", "run", "tool/almanac_probe.dart"],
        cwd=MOBILE,
        input=json.dumps(iso_values, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    dart_values = json.loads(process.stdout)

    failures: list[dict[str, Any]] = []
    for source, dart_value in zip(samples, dart_values, strict=True):
        python_value = calculate_almanac(
            source.isoformat(),
            timezone_name="Asia/Shanghai",
        )
        expected = _normalize_python(python_value)
        actual = _normalize_dart(dart_value)
        if actual != expected:
            failures.append({"input": source.isoformat(), "expected": expected, "actual": actual})
            if len(failures) >= 20:
                break

    if failures:
        print(json.dumps(failures, ensure_ascii=False, indent=2))
        raise SystemExit(f"offline parity failed; showing {len(failures)} differences")
    print(f"offline legacy-compatible almanac parity passed: {len(samples)} snapshots")


if __name__ == "__main__":
    main()
