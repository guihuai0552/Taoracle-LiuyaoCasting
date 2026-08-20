"""Versioned, auditable base-chart rules for Liuyao.

The first rule package intentionally matches najia 2.0.1's structural tables,
but owns the product contract and calculation traces.  `raw_najia` remains a
diagnostic snapshot; downstream features must consume this module's output.
"""

from __future__ import annotations

from importlib.metadata import PackageNotFoundError, version
from typing import Any

from najia.const import GUA64

RULE_PACKAGE_ID = "liuyao.base.najia_2_0_1_compat.v1"
RULE_PACKAGE_VERSION = "1.3.0"
UPSTREAM_TAG = "v2.0.1"
UPSTREAM_COMMIT = "c67a5398632a80f368a17a884c1c71b203aab719"

LINE_POSITION_NAMES = ["初爻", "二爻", "三爻", "四爻", "五爻", "上爻"]
ELEMENTS = ("木", "火", "土", "金", "水")
BRANCH_ELEMENTS = {
    "子": "水",
    "丑": "土",
    "寅": "木",
    "卯": "木",
    "辰": "土",
    "巳": "火",
    "午": "火",
    "未": "土",
    "申": "金",
    "酉": "金",
    "戌": "土",
    "亥": "水",
}
GENERATES = {"木": "火", "火": "土", "土": "金", "金": "水", "水": "木"}
CONTROLS = {"木": "土", "土": "水", "水": "火", "火": "金", "金": "木"}
SIX_GODS = ("青龙", "朱雀", "勾陈", "螣蛇", "白虎", "玄武")
SIX_GOD_START = {
    "甲": "青龙",
    "乙": "青龙",
    "丙": "朱雀",
    "丁": "朱雀",
    "戊": "勾陈",
    "己": "螣蛇",
    "庚": "白虎",
    "辛": "白虎",
    "壬": "玄武",
    "癸": "玄武",
}

# code is always bottom -> top. The two triples below are inner / outer Najia.
TRIGRAMS: dict[str, dict[str, Any]] = {
    "111": {
        "name": "乾",
        "element": "金",
        "inner": ("甲", "子寅辰"),
        "outer": ("壬", "午申戌"),
    },
    "110": {
        "name": "兑",
        "element": "金",
        "inner": ("丁", "巳卯丑"),
        "outer": ("丁", "亥酉未"),
    },
    "101": {
        "name": "离",
        "element": "火",
        "inner": ("己", "卯丑亥"),
        "outer": ("己", "酉未巳"),
    },
    "100": {
        "name": "震",
        "element": "木",
        "inner": ("庚", "子寅辰"),
        "outer": ("庚", "午申戌"),
    },
    "011": {
        "name": "巽",
        "element": "木",
        "inner": ("辛", "丑亥酉"),
        "outer": ("辛", "未巳卯"),
    },
    "010": {
        "name": "坎",
        "element": "水",
        "inner": ("戊", "寅辰午"),
        "outer": ("戊", "申戌子"),
    },
    "001": {
        "name": "艮",
        "element": "土",
        "inner": ("丙", "辰午申"),
        "outer": ("丙", "戌子寅"),
    },
    "000": {
        "name": "坤",
        "element": "土",
        "inner": ("乙", "未巳卯"),
        "outer": ("癸", "丑亥酉"),
    },
}

OPPOSITE_TRIGRAMS = {
    "111": "000",  # 乾 ↔ 坤
    "000": "111",
    "100": "011",  # 震 ↔ 巽
    "011": "100",
    "010": "101",  # 坎 ↔ 离
    "101": "010",
    "001": "110",  # 艮 ↔ 兑
    "110": "001",
}


def _provider_version() -> str:
    try:
        return version("najia")
    except PackageNotFoundError:
        return "unknown"


def rule_package() -> dict[str, Any]:
    return {
        "id": RULE_PACKAGE_ID,
        "version": RULE_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-001", "SRC-008", "SRC-009", "SRC-010", "SRC-019"],
        "upstream": {
            "name": "najia",
            "installed_version": _provider_version(),
            "audited_tag": UPSTREAM_TAG,
            "audited_commit": UPSTREAM_COMMIT,
        },
    }


def _trace(
    rule_id: str,
    label: str,
    inputs: Any,
    steps: list[str],
    result: Any,
    *,
    source_ids: list[str] | None = None,
) -> dict[str, Any]:
    return {
        "rule_id": rule_id,
        "label": label,
        "scope": "base_chart",
        "inputs": inputs,
        "steps": steps,
        "result": result,
        "rule_version": RULE_PACKAGE_VERSION,
        "source_ids": source_ids or ["SRC-009"],
    }


def _invert(code: str) -> str:
    return "".join("0" if value == "1" else "1" for value in code)


def _shi_ying(code: str) -> tuple[int, int, int, str]:
    outer = code[3:]
    inner = code[:3]

    def result(shi: int, kind: str = "regular"):
        ying = shi - 3 if shi > 3 else shi + 3
        palace_sequence = {
            "pure": 1,
            "wandering_soul": 7,
            "returning_soul": 8,
        }.get(kind, shi + 1)
        return shi, ying, palace_sequence, kind

    if outer[2] == inner[2]:
        if outer[1] != inner[1] and outer[0] != inner[0]:
            return result(2)
    elif outer[1] == inner[1] and outer[0] == inner[0]:
        return result(5)

    if outer[1] == inner[1]:
        if outer[0] != inner[0] and outer[2] != inner[2]:
            return result(4, "wandering_soul")
    elif outer[0] == inner[0] and outer[2] == inner[2]:
        return result(3, "returning_soul")

    if outer[0] == inner[0]:
        if outer[1] != inner[1] and outer[2] != inner[2]:
            return result(4)
    elif outer[1] == inner[1] and outer[2] == inner[2]:
        return result(1)

    if outer == inner:
        return result(6, kind="pure")
    return result(3)


def _palace(code: str, shi: int, kind: str) -> dict[str, str]:
    outer = code[3:]
    inner = code[:3]
    if kind == "returning_soul":
        palace_code = inner
    elif shi in (1, 2, 3, 6):
        palace_code = outer
    else:
        palace_code = _invert(inner)
    trigram = TRIGRAMS[palace_code]
    return {
        "code": palace_code,
        "name": trigram["name"],
        "element": trigram["element"],
    }


def _najia(code: str) -> list[dict[str, str]]:
    lower = TRIGRAMS[code[:3]]
    upper = TRIGRAMS[code[3:]]
    lower_stem, lower_branches = lower["inner"]
    upper_stem, upper_branches = upper["outer"]
    values = [
        (lower_stem, branch) for branch in lower_branches
    ] + [
        (upper_stem, branch) for branch in upper_branches
    ]
    return [
        {
            "heavenly_stem": stem,
            "earthly_branch": branch,
            "branch": branch,
            "gan_zhi": f"{stem}{branch}",
            "element": BRANCH_ELEMENTS[branch],
        }
        for stem, branch in values
    ]


def _relation(palace_element: str, line_element: str) -> str:
    if palace_element == line_element:
        return "兄弟"
    if GENERATES[palace_element] == line_element:
        return "子孙"
    if GENERATES[line_element] == palace_element:
        return "父母"
    if CONTROLS[palace_element] == line_element:
        return "妻财"
    if CONTROLS[line_element] == palace_element:
        return "官鬼"
    raise ValueError(f"cannot determine relation: {palace_element=} {line_element=}")


def _six_gods(day_stem: str) -> list[str]:
    try:
        start = SIX_GODS.index(SIX_GOD_START[day_stem])
    except (KeyError, ValueError) as error:
        raise ValueError(f"invalid day stem for six gods: {day_stem!r}") from error
    return [SIX_GODS[(start + index) % len(SIX_GODS)] for index in range(6)]


def _trigram_summary(code: str) -> dict[str, str]:
    trigram = TRIGRAMS[code]
    return {"code": code, "name": trigram["name"], "element": trigram["element"]}


def _base_lines(
    code: str,
    line_values: list[int],
    palace: dict[str, str],
    shi: int,
    ying: int,
    day_stem: str,
) -> list[dict[str, Any]]:
    najia = _najia(code)
    gods = _six_gods(day_stem)
    return [
        {
            "id": f"base-{index + 1}",
            "position": index + 1,
            "position_name": LINE_POSITION_NAMES[index],
            "value": line_values[index],
            "yin_yang": "yang" if code[index] == "1" else "yin",
            "changing": line_values[index] in (6, 9),
            "six_god": gods[index],
            "relation": _relation(palace["element"], najia[index]["element"]),
            **najia[index],
            "role": "世" if index + 1 == shi else "应" if index + 1 == ying else None,
            "hidden": None,
        }
        for index in range(6)
    ]


def _hidden_hexagram(
    base_code: str,
    palace: dict[str, str],
) -> dict[str, Any]:
    palace_code = palace["code"]
    opposite_code = OPPOSITE_TRIGRAMS[palace_code]
    inner_code = base_code[:3]
    outer_code = base_code[3:]
    hidden_inner_code = opposite_code if inner_code == palace_code else palace_code
    hidden_outer_code = opposite_code if outer_code == palace_code else palace_code
    hidden_code = hidden_inner_code + hidden_outer_code

    def selection_rule(scope: str, original_code: str, selected_code: str) -> dict[str, Any]:
        matched = original_code == palace_code
        return {
            "scope": scope,
            "original_trigram": _trigram_summary(original_code),
            "matches_palace_trigram": matched,
            "selected_trigram": _trigram_summary(selected_code),
            "selection": "palace_opposite" if matched else "palace_trigram",
        }

    return {
        "id": "hidden",
        "code": hidden_code,
        "name": GUA64[hidden_code],
        "lower_trigram": _trigram_summary(hidden_inner_code),
        "upper_trigram": _trigram_summary(hidden_outer_code),
        "palace_basis": palace,
        "palace_opposite": _trigram_summary(opposite_code),
        "inner_rule": selection_rule("inner", inner_code, hidden_inner_code),
        "outer_rule": selection_rule("outer", outer_code, hidden_outer_code),
    }


def _attach_hidden(
    lines: list[dict[str, Any]],
    palace: dict[str, str],
    hidden_hexagram: dict[str, Any],
) -> list[dict[str, Any]]:
    present = {line["relation"] for line in lines}
    hidden_code = hidden_hexagram["code"]
    hidden_najia = _najia(hidden_code)
    hidden_items: list[dict[str, Any]] = []
    for index, hidden_line in enumerate(hidden_najia):
        position = index + 1
        relation = _relation(palace["element"], hidden_line["element"])
        item = {
            "id": f"hidden-{position}-{relation}",
            "position": position,
            "position_name": LINE_POSITION_NAMES[position - 1],
            "relation": relation,
            **hidden_line,
            "source_hexagram": {
                "code": hidden_code,
                "name": hidden_hexagram["name"],
            },
            "source_trigram": "inner" if position <= 3 else "outer",
            "flying_line_id": f"base-{position}",
            "relation_missing_from_base": relation not in present,
            "note": "伏神",
        }
        lines[position - 1]["hidden"] = item
        hidden_items.append(item)
    return hidden_items


def _changed_hexagram(
    base_code: str,
    line_values: list[int],
    base_palace: dict[str, str],
) -> dict[str, Any] | None:
    moving_positions = [index + 1 for index, value in enumerate(line_values) if value in (6, 9)]
    if not moving_positions:
        return None
    changed_code = "".join(
        _invert(bit) if index + 1 in moving_positions else bit
        for index, bit in enumerate(base_code)
    )
    shi, ying, palace_sequence, kind = _shi_ying(changed_code)
    changed_palace = _palace(changed_code, shi, kind)
    najia = _najia(changed_code)
    return {
        "id": "changed",
        "code": changed_code,
        "name": GUA64[changed_code],
        "lower_trigram": _trigram_summary(changed_code[:3]),
        "upper_trigram": _trigram_summary(changed_code[3:]),
        "palace_name": changed_palace["name"],
        "palace_element": changed_palace["element"],
        "palace": changed_palace,
        "palace_sequence": palace_sequence,
        "hexagram_kind": kind,
        "relative_basis": "base_palace",
        "relative_basis_element": base_palace["element"],
        "lines": [
            {
                "id": f"changed-{index + 1}",
                "position": index + 1,
                "position_name": LINE_POSITION_NAMES[index],
                "yin_yang": "yang" if changed_code[index] == "1" else "yin",
                "changed_from_base": index + 1 in moving_positions,
                "relation": _relation(base_palace["element"], najia[index]["element"]),
                **najia[index],
            }
            for index in range(6)
        ],
    }


def _provider_diagnostics(
    provider_data: dict[str, Any],
    base: dict[str, Any],
    changed: dict[str, Any] | None,
    project_pillars: dict[str, dict[str, str]],
) -> dict[str, Any]:
    provider_najia = provider_data.get("qinx") or []
    provider_relations = provider_data.get("qin6") or []
    expected_najia = [f'{line["gan_zhi"]}{line["element"]}' for line in base["lines"]]
    structural_checks = {
        "base_name": provider_data.get("name") == base["name"],
        "base_code": provider_data.get("mark") == base["code"],
        "palace": provider_data.get("gong") == base["palace_name"],
        "shi_ying": list(provider_data.get("shiy") or [])[:2]
        == [base["shi_position"], base["ying_position"]],
        "najia": provider_najia == expected_najia,
        "relations": provider_relations == [line["relation"] for line in base["lines"]],
    }
    provider_changed = provider_data.get("bian")
    if changed is None:
        structural_checks["changed"] = provider_changed is None
    else:
        structural_checks["changed"] = bool(
            provider_changed
            and provider_changed.get("name") == changed["name"]
            and provider_changed.get("mark") == changed["code"]
        )
    provider_pillars = provider_data.get("lunar", {}).get("gz", {})
    time_checks = {
        key: provider_pillars.get(key) == project_pillars[key]["gan_zhi"]
        for key in ("year", "month", "day", "hour")
    }
    return {
        "provider": "najia",
        "provider_version": _provider_version(),
        "structural_checks": structural_checks,
        "structural_match": all(structural_checks.values()),
        "provider_time_checks": time_checks,
        "provider_time_match": all(time_checks.values()),
        "time_authority": "project_cnlunar_adapter",
    }


def build_base_chart(
    line_values: list[int],
    *,
    project_pillars: dict[str, dict[str, str]],
    provider_data: dict[str, Any],
    verify_provider: bool = True,
) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, Any]]:
    """Build the schema-v3 base chart and a complete calculation trace."""
    code = "".join("1" if value in (7, 9) else "0" for value in line_values)
    moving_positions = [index + 1 for index, value in enumerate(line_values) if value in (6, 9)]
    shi, ying, palace_sequence, kind = _shi_ying(code)
    palace = _palace(code, shi, kind)
    lines = _base_lines(code, line_values, palace, shi, ying, project_pillars["day"]["stem"])
    hidden_hexagram = _hidden_hexagram(code, palace)
    hidden_items = _attach_hidden(lines, palace, hidden_hexagram)
    changed = _changed_hexagram(code, line_values, palace)
    base = {
        "id": "base",
        "code": code,
        "name": GUA64[code],
        "lower_trigram": _trigram_summary(code[:3]),
        "upper_trigram": _trigram_summary(code[3:]),
        "palace_name": palace["name"],
        "palace_element": palace["element"],
        "palace": palace,
        "palace_sequence": palace_sequence,
        "hexagram_kind": kind,
        "shi_position": shi,
        "ying_position": ying,
        "moving_positions": moving_positions,
        "hidden_hexagram": hidden_hexagram,
        "lines": lines,
    }
    chart = {
        "line_order": "bottom_to_top",
        "display_order": "top_to_bottom",
        "moving_positions": moving_positions,
        "base": base,
        "changed": changed,
    }

    changed_name = changed["name"] if changed else None
    traces = [
        _trace(
            "chart.hexagram.identify.v1",
            "本卦与变卦识别",
            {"line_values": line_values, "line_order": "bottom_to_top"},
            [
                f"6/8 记阴(0)，7/9 记阳(1)，得到本卦码 {code}",
                (
                    f"动爻位 {moving_positions} 逐位反转，得到变卦码 {changed['code']}"
                    if changed
                    else "没有 6/9 动爻，本次为静卦，不生成变卦"
                ),
                f"查 64 卦表：{GUA64[code]}"
                + (f" → {changed_name}" if changed_name else ""),
            ],
            {"base": GUA64[code], "changed": changed_name},
        ),
        _trace(
            "chart.trigrams.split.v1",
            "上下卦拆分",
            {"base_code": code},
            [
                f"前三位 {code[:3]} 为下卦：{base['lower_trigram']['name']}({base['lower_trigram']['element']})",
                f"后三位 {code[3:]} 为上卦：{base['upper_trigram']['name']}({base['upper_trigram']['element']})",
            ],
            {"lower": base["lower_trigram"], "upper": base["upper_trigram"]},
        ),
        _trace(
            "chart.palace.shi_ying.v1",
            "卦宫与世应",
            {"base_code": code, "inner": code[:3], "outer": code[3:]},
            [
                f"按寻世诀判定：世在{LINE_POSITION_NAMES[shi - 1]}，应在{LINE_POSITION_NAMES[ying - 1]}",
                f"按认宫诀判定：{palace['name']}宫，宫五行{palace['element']}",
                f"卦型标识：{kind}；八宫序位：{palace_sequence}",
            ],
            {
                "palace": palace,
                "shi_position": shi,
                "ying_position": ying,
                "kind": kind,
            },
        ),
        _trace(
            "chart.najia.table.v1",
            "纳甲",
            {"lower_trigram": code[:3], "upper_trigram": code[3:]},
            [
                f'{line["position_name"]}：查纳甲表得 {line["gan_zhi"]}，{line["earthly_branch"]}属{line["element"]}'
                for line in lines
            ],
            [
                {
                    "position": line["position"],
                    "gan_zhi": line["gan_zhi"],
                    "element": line["element"],
                }
                for line in lines
            ],
        ),
        _trace(
            "chart.six_relatives.five_elements.v1",
            "六亲",
            {"base_palace_element": palace["element"]},
            [
                f'{line["position_name"]}：宫{palace["element"]} 对 爻{line["element"]} → {line["relation"]}'
                for line in lines
            ],
            [line["relation"] for line in lines],
        ),
        _trace(
            "chart.six_gods.day_stem.v1",
            "六神",
            {"day_gan_zhi": project_pillars["day"]["gan_zhi"], "day_stem": project_pillars["day"]["stem"]},
            [
                f'{project_pillars["day"]["stem"]}日起{lines[0]["six_god"]}，按固定次序从初爻排至上爻',
                *[
                    f'{line["position_name"]}：{line["six_god"]}'
                    for line in lines
                ],
            ],
            [line["six_god"] for line in lines],
            source_ids=["SRC-008", "SRC-009"],
        ),
        _trace(
            "chart.hidden_hexagram.trigram_match.v3",
            "伏卦与伏神",
            {
                "display_mode": "full_hidden_hexagram_six_lines",
                "base_code": code,
                "present_relations": sorted({line["relation"] for line in lines}),
                "palace": palace,
                "palace_opposite": hidden_hexagram["palace_opposite"],
            },
            [
                (
                    f'内卦{TRIGRAMS[code[:3]]["name"]}'
                    f'{"等于" if hidden_hexagram["inner_rule"]["matches_palace_trigram"] else "不等于"}'
                    f'宫卦{palace["name"]}，伏内卦取'
                    f'{hidden_hexagram["lower_trigram"]["name"]}'
                ),
                (
                    f'外卦{TRIGRAMS[code[3:]]["name"]}'
                    f'{"等于" if hidden_hexagram["outer_rule"]["matches_palace_trigram"] else "不等于"}'
                    f'宫卦{palace["name"]}，伏外卦取'
                    f'{hidden_hexagram["upper_trigram"]["name"]}'
                ),
                f'伏内卦与伏外卦合成 {hidden_hexagram["name"]}（{hidden_hexagram["code"]}）',
                *[
                    f'查{item["source_hexagram"]["name"]}{item["position_name"]}：'
                    f'{item["relation"]}{item["gan_zhi"]}{item["element"]}，逐爻伏于 {item["flying_line_id"]}'
                    for item in hidden_items
                ],
            ],
            {"hidden_hexagram": hidden_hexagram, "lines": hidden_items},
            source_ids=["SRC-009", "SRC-019"],
        ),
    ]
    if changed:
        traces.append(
            _trace(
                "chart.changed.relatives.v1",
                "变卦纳甲与六亲",
                {"changed_code": changed["code"], "relative_basis": "base_palace", "base_palace": palace},
                [
                    f'{line["position_name"]}：{line["gan_zhi"]}{line["element"]}；'
                    f'仍以本卦{palace["name"]}宫{palace["element"]}定为{line["relation"]}'
                    for line in changed["lines"]
                ],
                {
                    "name": changed["name"],
                    "relative_basis": changed["relative_basis"],
                    "lines": changed["lines"],
                },
            )
        )

    if verify_provider:
        diagnostics = _provider_diagnostics(provider_data, base, changed, project_pillars)
        if not diagnostics["structural_match"]:
            raise ValueError(f"najia provider diverged from frozen rule package: {diagnostics}")
    else:
        diagnostics = {
            "provider": "not_checked",
            "structural_match": None,
            "provider_time_match": None,
            "time_authority": "project_cnlunar_adapter",
        }
    return chart, traces, diagnostics


def day_void(day_gan_zhi: str) -> tuple[str, list[str]]:
    stems = "甲乙丙丁戊己庚辛壬癸"
    branches = "子丑寅卯辰巳午未申酉戌亥"
    if len(day_gan_zhi) != 2 or day_gan_zhi[0] not in stems or day_gan_zhi[1] not in branches:
        raise ValueError(f"invalid day gan-zhi: {day_gan_zhi!r}")
    start = (branches.index(day_gan_zhi[1]) - stems.index(day_gan_zhi[0]) - 2) % 12
    values = [branches[start], branches[(start + 1) % 12]]
    return "".join(values), values
