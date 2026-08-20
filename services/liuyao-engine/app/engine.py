"""Pure Liuyao casting and contract normalization.

The adapter is extracted from Taoracle's proven Najia integration.  The public
contract deliberately keeps the original line values so archived cases remain
auditable even if the upstream library changes later.
"""

from __future__ import annotations

import random
from datetime import date as date_type
from datetime import datetime
from typing import Any

import arrow
from najia.najia import Najia

from .almanac import calculate_almanac
from .base_chart import build_base_chart, day_void, rule_package
from .rule_annotations import (
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
from .twenty_eight_mansions import (
    build_twenty_eight_mansions,
    rule_package as mansion_rule_package,
)

SCHEMA_VERSION = 13
ENGINE_VERSION = "0.13.0+najia-2.0.1"
VALID_LINE_VALUES = {6, 7, 8, 9}
LINE_POSITION_NAMES = ["初爻", "二爻", "三爻", "四爻", "五爻", "上爻"]


def _json_safe(value: Any) -> Any:
    if isinstance(value, arrow.Arrow):
        return value.isoformat()
    if isinstance(value, (datetime, date_type)):
        return value.isoformat()
    if isinstance(value, dict):
        return {key: _json_safe(item) for key, item in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [_json_safe(item) for item in value]
    return value


def _generate_three_coin_cast(
    seed: str | int | None,
) -> tuple[list[int], list[list[int]], dict[str, Any]]:
    rng = random.Random(seed) if seed is not None else random.SystemRandom()
    lines: list[int] = []
    coin_lines: list[list[int]] = []
    for _ in range(6):
        coins = [3 if rng.randint(0, 1) == 1 else 2 for _ in range(3)]
        coin_lines.append(coins)
        lines.append(sum(coins))
    random_source: dict[str, Any] = {
        "kind": "seeded_test" if seed is not None else "system",
        "generator": "python.Random" if seed is not None else "python.SystemRandom",
    }
    if seed is not None:
        random_source["seed"] = seed
    return lines, coin_lines, random_source


def _line_semantics(value: int) -> tuple[str, bool, str]:
    return {
        6: ("yin", True, "老阴"),
        7: ("yang", False, "少阳"),
        8: ("yin", False, "少阴"),
        9: ("yang", True, "老阳"),
    }[value]


def _casting_record(
    casting_method: str,
    lines: list[int],
    *,
    coin_lines: list[list[int]] | None,
    random_source: dict[str, Any] | None,
) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    for index, value in enumerate(lines):
        yin_yang, changing, traditional_name = _line_semantics(value)
        coins = coin_lines[index] if coin_lines is not None else []
        records.append(
            {
                "position": index + 1,
                "position_name": LINE_POSITION_NAMES[index],
                "source": "three_coins" if coin_lines is not None else "manual_input",
                "coins": coins,
                "total": sum(coins) if coins else value,
                "value": value,
                "yin_yang": yin_yang,
                "changing": changing,
                "traditional_name": traditional_name,
            }
        )
    return {
        "method": casting_method,
        "method_version": (
            "three_coins.sum_2_3.v1"
            if casting_method == "three_coins"
            else "manual.yin_yang_moving.v1"
        ),
        "line_order": "bottom_to_top",
        "line_values": lines,
        "lines": records,
        "random_source": random_source,
    }


def _casting_trace(record: dict[str, Any]) -> dict[str, Any]:
    if record["method"] == "three_coins":
        steps = [
            (
                f'{line["position_name"]}：'
                f'{" + ".join(str(coin) for coin in line["coins"])}'
                f' = {line["total"]} → {line["traditional_name"]}'
            )
            for line in record["lines"]
        ]
        rule_id = "casting.three_coins.sum_2_3.v1"
        inputs: Any = [line["coins"] for line in record["lines"]]
    else:
        steps = [
            f'{line["position_name"]}：{line["value"]} → {line["traditional_name"]}'
            for line in record["lines"]
        ]
        rule_id = "casting.manual.normalize.v1"
        inputs = record["line_values"]
    return {
        "rule_id": rule_id,
        "label": "起卦原始过程",
        "scope": "casting",
        "inputs": inputs,
        "steps": steps,
        "result": record["line_values"],
        "rule_version": "1.0.0",
    }


def _to_najia_params(lines: list[int]) -> list[int]:
    value_map = {7: 1, 8: 2, 9: 3, 6: 4}
    return [value_map[value] for value in lines]


def cast_chart(
    timestamp_iso: str,
    *,
    line_values: list[int] | None = None,
    seed: str | int | None = None,
    casting_method: str = "three_coins",
) -> dict[str, Any]:
    """Compile a chart. Lines are always ordered 初爻 -> 上爻."""
    if casting_method not in {"manual", "three_coins"}:
        raise ValueError("casting_method must be manual or three_coins")
    if casting_method == "manual":
        if line_values is None:
            raise ValueError("manual casting requires line_values")
        if seed is not None:
            raise ValueError("manual casting does not accept seed")
        lines = list(line_values)
        coin_lines = None
        random_source = None
    else:
        if line_values is not None:
            raise ValueError("three_coins casting does not accept line_values")
        lines, coin_lines, random_source = _generate_three_coin_cast(seed)
    if len(lines) != 6 or any(value not in VALID_LINE_VALUES for value in lines):
        raise ValueError("line_values must contain six integers chosen from 6, 7, 8, 9")

    casting_record = _casting_record(
        casting_method,
        lines,
        coin_lines=coin_lines,
        random_source=random_source,
    )

    cast_at = arrow.get(timestamp_iso)
    if cast_at.utcoffset() is None:
        raise ValueError("timestamp must include an explicit UTC offset")

    compiler = Najia(verbose=0).compile(
        params=_to_najia_params(lines),
        date=cast_at.format("YYYY-MM-DD HH:mm"),
    )
    return _transform_contract(
        compiler.data,
        lines,
        cast_at,
        casting_method=casting_method,
        casting_record=casting_record,
    )


def _transform_contract(
    data: dict[str, Any],
    raw_lines: list[int],
    cast_at: arrow.Arrow,
    *,
    casting_method: str,
    casting_record: dict[str, Any],
) -> dict[str, Any]:
    almanac = calculate_almanac(
        cast_at.isoformat(),
        timezone_name="Asia/Shanghai",
        year_boundary="lunar_new_year",
    )
    project_pillars = {
        item["position"]: {
            "gan_zhi": item["ganzhi"],
            "stem": item["stem"],
            "branch": item["branch"],
        }
        for item in almanac["four_pillars"]
    }
    pillar_voids = {}
    for position, pillar in project_pillars.items():
        pillar_void_text, pillar_void_branches = day_void(pillar["gan_zhi"])
        pillar_voids[position] = {
            "void": pillar_void_text,
            "branches": pillar_void_branches,
        }
    void_text = pillar_voids["day"]["void"]
    void_branches = pillar_voids["day"]["branches"]
    hexagram, chart_traces, diagnostics = build_base_chart(
        raw_lines,
        project_pillars=project_pillars,
        provider_data=data,
    )
    twelve_stages, twelve_stages_trace = build_five_element_twelve_stages(
        hexagram["base"]["lines"],
        project_pillars,
    )
    lu_shen, lu_shen_trace = build_lu_shen(
        hexagram["base"]["lines"],
        project_pillars["day"],
    )
    tian_yi, tian_yi_trace = build_tian_yi(
        hexagram["base"]["lines"],
        project_pillars["day"],
    )
    yi_ma, yi_ma_trace = build_yi_ma(
        hexagram["base"]["lines"],
        project_pillars["day"],
    )
    tao_hua, tao_hua_trace = build_tao_hua(
        hexagram["base"]["lines"],
        project_pillars["day"],
    )
    jiang_xing, jiang_xing_trace = build_jiang_xing(
        hexagram["base"]["lines"],
        project_pillars["day"],
    )
    hua_gai, hua_gai_trace = build_hua_gai(
        hexagram["base"]["lines"],
        project_pillars["day"],
    )
    mansions, mansions_trace = build_twenty_eight_mansions(hexagram["base"])

    time_trace = {
        "rule_id": "chart.time_context.cnlunar.v1",
        "label": "排盘时间上下文",
        "scope": "base_chart",
        "inputs": {
            "timestamp": cast_at.isoformat(),
            "timezone": "Asia/Shanghai",
            "year_boundary": "lunar_new_year",
        },
        "steps": [
            "将起卦时刻转换为 Asia/Shanghai 本地时间",
            "通过项目 cnlunar 适配层生成四柱",
            "分别以年、月、日、时四柱干支计算各柱旬空",
            f'日柱 {project_pillars["day"]["gan_zhi"]} 旬空 {void_text}，并以日干起六神',
        ],
        "result": {
            "pillars": project_pillars,
            "pillar_voids": pillar_voids,
            "day_void": void_branches,
        },
        "rule_version": "1.1.0",
        "source_ids": ["SRC-008"],
    }

    return {
        "schema_version": SCHEMA_VERSION,
        "engine_version": ENGINE_VERSION,
        "rule_package": rule_package(),
        "meta": {
            "cast_at": cast_at.isoformat(),
            "casting_method": casting_method,
            "line_order": "bottom_to_top",
            "line_values": raw_lines,
        },
        "casting_record": casting_record,
        "time": {
            "timezone": "Asia/Shanghai",
            "rule_status": "provisional",
            "source": "cnlunar_adapter",
            "year": project_pillars["year"]["gan_zhi"],
            "month": project_pillars["month"]["gan_zhi"],
            "day": project_pillars["day"]["gan_zhi"],
            "hour": project_pillars["hour"]["gan_zhi"],
            "pillars": project_pillars,
            "pillar_voids": pillar_voids,
            "day_void": void_text,
            "day_void_branches": void_branches,
        },
        "hexagram": hexagram,
        "annotations": {
            "rule_packages": [
                annotation_rule_package(),
                lu_shen_rule_package(),
                tian_yi_rule_package(),
                yi_ma_rule_package(),
                tao_hua_rule_package(),
                jiang_xing_rule_package(),
                hua_gai_rule_package(),
                mansion_rule_package(),
            ],
            "five_element_twelve_stages": twelve_stages,
            "shensha": {
                "catalog_version": "1.0.0",
                "results": [
                    lu_shen,
                    tian_yi,
                    yi_ma,
                    tao_hua,
                    jiang_xing,
                    hua_gai,
                ],
            },
            "twenty_eight_mansions": mansions,
        },
        "calculation_trace": [
            _casting_trace(casting_record),
            time_trace,
            *chart_traces,
            twelve_stages_trace,
            lu_shen_trace,
            tian_yi_trace,
            yi_ma_trace,
            tao_hua_trace,
            jiang_xing_trace,
            hua_gai_trace,
            mansions_trace,
        ],
        "diagnostics": diagnostics,
        "raw_najia": _json_safe(data),
    }
