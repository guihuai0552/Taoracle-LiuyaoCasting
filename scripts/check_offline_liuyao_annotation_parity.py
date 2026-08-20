"""Compare unchanged product annotations with the legacy Python rules.

Schema v14 intentionally replaces the legacy unified-Earth growth table and
Tianyi lineage. Schema v15 also removes Jiangxing from the current product
selection. Those fields are validated by their dedicated gates or retained
only for historical snapshots. This gate keeps exhaustive coverage for
non-Earth growth lines and the four unchanged product Shensha rules.
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

from cnlunar.config import the60HeavenlyEarth  # noqa: E402

from app.base_chart import build_base_chart  # noqa: E402
from app.rule_annotations import (  # noqa: E402
    annotation_rule_package,
    build_five_element_twelve_stages,
    build_hua_gai,
    build_jiang_xing,
    build_lu_shen,
    build_tao_hua,
    build_tian_yi,
    build_yi_ma,
    hua_gai_rule_package,
    jiang_xing_rule_package,
    lu_shen_rule_package,
    tao_hua_rule_package,
    tian_yi_rule_package,
    yi_ma_rule_package,
)


def _pillars(day: str) -> dict[str, dict[str, str]]:
    return {
        "year": {"gan_zhi": "丙午", "stem": "丙", "branch": "午"},
        "month": {"gan_zhi": "乙未", "stem": "乙", "branch": "未"},
        "day": {"gan_zhi": day, "stem": day[0], "branch": day[1]},
        "hour": {"gan_zhi": "丁亥", "stem": "丁", "branch": "亥"},
    }


def _line_values(code: int) -> list[int]:
    return [7 if code & (1 << position) else 8 for position in range(6)]


def _samples(quick: bool) -> list[dict[str, Any]]:
    codes = [0, 21, 42, 63] if quick else range(64)
    days = the60HeavenlyEarth[:4] if quick else the60HeavenlyEarth
    return [
        {"line_values": _line_values(code), "pillars": _pillars(day)}
        for code in codes
        for day in days
    ]


def _python_snapshot(sample: dict[str, Any]) -> dict[str, Any]:
    pillars = sample["pillars"]
    chart, _, _ = build_base_chart(
        sample["line_values"],
        project_pillars=pillars,
        provider_data={},
        verify_provider=False,
    )
    lines = chart["base"]["lines"]
    stages, _ = build_five_element_twelve_stages(lines, pillars)
    builders = (
        build_lu_shen,
        build_tian_yi,
        build_yi_ma,
        build_tao_hua,
        build_jiang_xing,
        build_hua_gai,
    )
    results = [builder(lines, pillars["day"])[0] for builder in builders]
    return {
        "rule_packages": [
            annotation_rule_package(),
            lu_shen_rule_package(),
            tian_yi_rule_package(),
            yi_ma_rule_package(),
            tao_hua_rule_package(),
            jiang_xing_rule_package(),
            hua_gai_rule_package(),
        ],
        "five_element_twelve_stages": stages,
        "shensha": {"catalog_version": "1.0.0", "results": results},
    }


def _differences(expected: Any, actual: Any, path: str = "$") -> list[dict[str, Any]]:
    if type(expected) is not type(actual):
        return [{"path": path, "expected": expected, "actual": actual}]
    if isinstance(expected, dict):
        output: list[dict[str, Any]] = []
        for key in sorted(set(expected) | set(actual)):
            if key not in expected or key not in actual:
                output.append(
                    {
                        "path": f"{path}.{key}",
                        "expected": expected.get(key, "<missing>"),
                        "actual": actual.get(key, "<missing>"),
                    }
                )
            else:
                output.extend(_differences(expected[key], actual[key], f"{path}.{key}"))
            if len(output) >= 12:
                break
        return output
    if isinstance(expected, list):
        if len(expected) != len(actual):
            return [{"path": path, "expected_length": len(expected), "actual_length": len(actual)}]
        output = []
        for index, (left, right) in enumerate(zip(expected, actual, strict=True)):
            output.extend(_differences(left, right, f"{path}[{index}]"))
            if len(output) >= 12:
                break
        return output
    return [] if expected == actual else [{"path": path, "expected": expected, "actual": actual}]


def _compatibility_projection(value: dict[str, Any]) -> dict[str, Any]:
    def strip_v2_metadata(item: Any) -> Any:
        if isinstance(item, dict):
            return {
                key: strip_v2_metadata(child)
                for key, child in item.items()
                if key not in {"source_model", "source_phases", "display_phases"}
            }
        if isinstance(item, list):
            return [strip_v2_metadata(child) for child in item]
        return item

    # Dart 引擎在四柱之外新增「具体选择五行」参照（reference 以 element: 开头）。
    # 该扩展无 Python legacy 对照，投影时仅保留四柱，避免误报 length 差异。
    stage_lines = [
        {
            **strip_v2_metadata(
                {key: child for key, child in line.items() if key != "pillar_results"},
            ),
            "pillar_results": [
                strip_v2_metadata(pillar)
                for pillar in line["pillar_results"]
                if not str(pillar.get("reference", "")).startswith("element:")
            ],
        }
        for line in value["five_element_twelve_stages"]["line_results"]
        if line["line_element"] != "土"
    ]
    shensha = [
        {key: child for key, child in result.items() if key != "rule_version"}
        for result in value["shensha"]["results"]
        if result["rule_id"]
        not in {
            "shensha.tianyi.day_stem.v1",
            "shensha.jiangxing.day_branch.v1",
        }
    ]
    return {
        "five_element_twelve_stages": {"line_results": stage_lines},
        "shensha": {"catalog_version": value["shensha"]["catalog_version"], "results": shensha},
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--quick", action="store_true")
    args = parser.parse_args()
    samples = _samples(args.quick)
    process = subprocess.run(
        ["dart", "run", "tool/liuyao_annotation_probe.dart"],
        cwd=MOBILE,
        input=json.dumps(samples, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    actual_values = json.loads(process.stdout)
    failures: list[dict[str, Any]] = []
    for sample, actual in zip(samples, actual_values, strict=True):
        expected = _compatibility_projection(_python_snapshot(sample))
        actual = _compatibility_projection(actual)
        if actual != expected:
            failures.append({"input": sample, "differences": _differences(expected, actual)})
            if len(failures) >= 3:
                break
    if failures:
        print(json.dumps(failures, ensure_ascii=False, indent=2))
        raise SystemExit(
            f"offline Liuyao annotation parity failed; showing {len(failures)} differences"
        )
    print(f"offline Liuyao legacy-compatible annotation parity passed: {len(samples)} snapshots")


if __name__ == "__main__":
    main()
