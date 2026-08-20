"""Confirmed Jingfang 64-hexagram / 28-mansion placement rules."""

from __future__ import annotations

from typing import Any

PACKAGE_ID = "liuyao.mansions.jingfang_world_line.v1"
PACKAGE_VERSION = "1.0.0"
RULE_ID = "mansion.jingfang.world_line_and_six_lines.v1"
SOURCE_IDS = ["SRC-006"]

MANSIONS = (
    "角",
    "亢",
    "氐",
    "房",
    "心",
    "尾",
    "箕",
    "斗",
    "牛",
    "女",
    "虚",
    "危",
    "室",
    "壁",
    "奎",
    "娄",
    "胃",
    "昴",
    "毕",
    "觜",
    "参",
    "井",
    "鬼",
    "柳",
    "星",
    "张",
    "翼",
    "轸",
)
PALACE_ORDER = ("乾", "震", "坎", "艮", "坤", "巽", "离", "兑")
WORLD_START_INDEX = MANSIONS.index("参")

# First place 世, then 应; alternate remaining lines of the 世 and 应 trigrams.
# Inner trigram remainder runs bottom -> top; outer trigram remainder top -> bottom.
PLACEMENT_POSITIONS = {
    1: (1, 4, 2, 6, 3, 5),
    2: (2, 5, 1, 6, 3, 4),
    3: (3, 6, 1, 5, 2, 4),
    4: (4, 1, 6, 2, 5, 3),
    5: (5, 2, 6, 1, 4, 3),
    6: (6, 3, 5, 1, 4, 2),
}
PLACEMENT_ROLES = ("世", "应", "世卦", "应卦", "世卦", "应卦")


def rule_package() -> dict[str, Any]:
    return {
        "id": PACKAGE_ID,
        "version": PACKAGE_VERSION,
        "status": "confirmed_user_rule",
        "source_ids": SOURCE_IDS,
        "system": "jingfang_64_hexagrams_world_line",
    }


def build_twenty_eight_mansions(
    base_hexagram: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any]]:
    palace_name = str(base_hexagram["palace_name"])
    palace_sequence = int(base_hexagram["palace_sequence"])
    shi_position = int(base_hexagram["shi_position"])
    ying_position = int(base_hexagram["ying_position"])
    lines = base_hexagram["lines"]

    if palace_name not in PALACE_ORDER:
        raise ValueError(f"unsupported palace for mansion placement: {palace_name}")
    if palace_sequence not in range(1, 9):
        raise ValueError("palace_sequence must be in 1..8")
    if shi_position not in PLACEMENT_POSITIONS:
        raise ValueError("shi_position must be in 1..6")
    expected_ying = shi_position - 3 if shi_position > 3 else shi_position + 3
    if ying_position != expected_ying:
        raise ValueError("ying_position must be opposite shi_position")
    if len(lines) != 6:
        raise ValueError("base hexagram must contain six lines")

    palace_index = PALACE_ORDER.index(palace_name)
    global_index = palace_index * 8 + palace_sequence - 1
    world_mansion_index = (WORLD_START_INDEX + global_index) % len(MANSIONS)
    positions = PLACEMENT_POSITIONS[shi_position]
    line_by_position = {int(line["position"]): line for line in lines}

    placements = []
    for offset, position in enumerate(positions):
        line = line_by_position[position]
        mansion_index = (world_mansion_index + offset) % len(MANSIONS)
        placements.append(
            {
                "order": offset + 1,
                "line_id": line["id"],
                "position": position,
                "position_name": line["position_name"],
                "placement_role": PLACEMENT_ROLES[offset],
                "mansion_index": mansion_index,
                "mansion": MANSIONS[mansion_index],
            }
        )

    result = {
        "rule_id": RULE_ID,
        "rule_version": PACKAGE_VERSION,
        "system": "jingfang_64_hexagrams_world_line",
        "scope": "base_lines",
        "mansion_order": list(MANSIONS),
        "palace_order": list(PALACE_ORDER),
        "hexagram": {
            "code": base_hexagram["code"],
            "name": base_hexagram["name"],
            "palace_name": palace_name,
            "palace_index": palace_index,
            "palace_sequence": palace_sequence,
            "global_index": global_index,
        },
        "world_line": {
            "position": shi_position,
            "position_name": line_by_position[shi_position]["position_name"],
            "mansion_index": world_mansion_index,
            "mansion": MANSIONS[world_mansion_index],
        },
        "response_line": {
            "position": ying_position,
            "position_name": line_by_position[ying_position]["position_name"],
        },
        "placement_position_order": list(positions),
        "line_placements": placements,
    }

    mansion_steps = [
        f'第{item["order"]}宿 {item["mansion"]} → '
        f'{item["position_name"]}（{item["placement_role"]}）'
        for item in placements
    ]
    trace = {
        "rule_id": RULE_ID,
        "label": "京房六十四卦配二十八宿",
        "scope": "rule_annotations",
        "inputs": {
            "hexagram_code": base_hexagram["code"],
            "hexagram_name": base_hexagram["name"],
            "palace_name": palace_name,
            "palace_sequence": palace_sequence,
            "shi_position": shi_position,
            "ying_position": ying_position,
            "palace_order": list(PALACE_ORDER),
            "mansion_order": list(MANSIONS),
        },
        "steps": [
            f"八宫顺序为 {'、'.join(PALACE_ORDER)}；{palace_name}宫序号为 {palace_index}",
            f"{base_hexagram['name']} 为{palace_name}宫第 {palace_sequence} 卦，"
            f"六十四卦全局序号 = {palace_index} × 8 + {palace_sequence - 1} = {global_index}",
            f"乾为天世爻从参宿（索引 {WORLD_START_INDEX}）起，"
            f"({WORLD_START_INDEX} + {global_index}) mod 28 = {world_mansion_index}，"
            f"故{line_by_position[shi_position]['position_name']}世爻配{MANSIONS[world_mansion_index]}宿",
            f"世在{line_by_position[shi_position]['position_name']}、"
            f"应在{line_by_position[ying_position]['position_name']}，"
            f"按世应两卦交替得到爻位次序：{'、'.join(str(item) for item in positions)}",
            *mansion_steps,
        ],
        "result": result,
        "rule_version": PACKAGE_VERSION,
        "source_ids": SOURCE_IDS,
    }
    return result, trace
