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

SCHEMA_VERSION = 1
ENGINE_VERSION = "0.1.0+najia-2.0.1"
VALID_LINE_VALUES = {6, 7, 8, 9}


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


def _generate_lines(seed: str | int | None) -> list[int]:
    rng = random.Random(seed) if seed is not None else random.SystemRandom()
    lines: list[int] = []
    for _ in range(6):
        coins = [rng.randint(0, 1) for _ in range(3)]
        lines.append(sum(3 if coin == 1 else 2 for coin in coins))
    return lines


def _to_najia_params(lines: list[int]) -> list[int]:
    value_map = {7: 1, 8: 2, 9: 3, 6: 4}
    return [value_map[value] for value in lines]


def _split_branch(value: str) -> tuple[str, str]:
    if len(value) >= 2:
        return value[:2], value[2:].strip()
    return value, ""


def cast_chart(
    timestamp_iso: str,
    *,
    line_values: list[int] | None = None,
    seed: str | int | None = None,
    casting_method: str = "three_coins",
) -> dict[str, Any]:
    """Compile a chart. Lines are always ordered 初爻 -> 上爻."""
    lines = list(line_values) if line_values is not None else _generate_lines(seed)
    if len(lines) != 6 or any(value not in VALID_LINE_VALUES for value in lines):
        raise ValueError("line_values must contain six integers chosen from 6, 7, 8, 9")

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
    )


def _transform_contract(
    data: dict[str, Any],
    raw_lines: list[int],
    cast_at: arrow.Arrow,
    *,
    casting_method: str,
) -> dict[str, Any]:
    base_lines: list[dict[str, Any]] = []
    for index in range(6):
        branch, element = _split_branch(data["qinx"][index])
        param = data["params"][index]
        position = index + 1
        role = None
        if position == data["shiy"][0]:
            role = "世"
        elif position == data["shiy"][1]:
            role = "应"

        hidden = None
        hide = data.get("hide")
        if hide and hide.get("seat") and index in hide["seat"]:
            hidden_branch, hidden_element = _split_branch(hide["qinx"][index])
            hidden = {
                "relation": hide["qin6"][index],
                "branch": hidden_branch,
                "element": hidden_element,
                "note": "伏神",
            }

        base_lines.append(
            {
                "position": position,
                "value": raw_lines[index],
                "yin_yang": "yang" if param in (1, 3) else "yin",
                "changing": param in (3, 4),
                "six_god": data["god6"][index],
                "relation": data["qin6"][index],
                "branch": branch,
                "element": element,
                "role": role,
                "hidden": hidden,
            }
        )

    palace_elements = {
        "乾": "金",
        "兑": "金",
        "离": "火",
        "震": "木",
        "巽": "木",
        "坎": "水",
        "艮": "土",
        "坤": "土",
    }
    palace_name = data["gong"][0] if data.get("gong") else ""
    base = {
        "name": data["name"],
        "palace_name": palace_name,
        "palace_element": palace_elements.get(palace_name, "未知"),
        "lines": base_lines,
    }
    changed = None
    changed_data = data.get("bian")
    if changed_data:
        mark = str(changed_data.get("mark") or "")
        changed_lines: list[dict[str, Any]] = []
        for index in range(6):
            branch, element = _split_branch(changed_data["qinx"][index])
            yin_yang = "yang" if index < len(mark) and mark[index] == "1" else "yin"
            changed_lines.append(
                {
                    "position": index + 1,
                    "yin_yang": yin_yang,
                    "relation": changed_data["qin6"][index],
                    "branch": branch,
                    "element": element,
                }
            )
        changed_palace = changed_data["gong"][0] if changed_data.get("gong") else ""
        changed = {
            "name": changed_data["name"],
            "palace_name": changed_palace,
            "palace_element": palace_elements.get(changed_palace, "未知"),
            "lines": changed_lines,
        }

    return {
        "schema_version": SCHEMA_VERSION,
        "engine_version": ENGINE_VERSION,
        "meta": {
            "cast_at": cast_at.isoformat(),
            "casting_method": casting_method,
            "line_order": "bottom_to_top",
            "line_values": raw_lines,
        },
        "time": {
            "year": data["lunar"]["gz"]["year"],
            "month": data["lunar"]["gz"]["month"],
            "day": data["lunar"]["gz"]["day"],
            "hour": data["lunar"]["gz"]["hour"],
            "day_void": data["lunar"]["xkong"],
        },
        "hexagram": {"base": base, "changed": changed},
        "raw_najia": _json_safe(data),
    }
