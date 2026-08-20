"""Versioned rule annotations layered on top of the frozen base chart."""

from __future__ import annotations

from typing import Any

ANNOTATION_PACKAGE_ID = "liuyao.annotations.wuxing_changsheng.v1"
ANNOTATION_PACKAGE_VERSION = "1.0.0"
LU_SHEN_PACKAGE_ID = "liuyao.shensha.lushen_day_stem.v1"
LU_SHEN_PACKAGE_VERSION = "1.0.0"
TIAN_YI_PACKAGE_ID = "liuyao.shensha.tianyi_day_stem.v1"
TIAN_YI_PACKAGE_VERSION = "1.0.0"
YI_MA_PACKAGE_ID = "liuyao.shensha.yima_day_branch.v1"
YI_MA_PACKAGE_VERSION = "1.0.0"
TAO_HUA_PACKAGE_ID = "liuyao.shensha.taohua_day_branch.v1"
TAO_HUA_PACKAGE_VERSION = "1.0.0"
JIANG_XING_PACKAGE_ID = "liuyao.shensha.jiangxing_day_branch.v1"
JIANG_XING_PACKAGE_VERSION = "1.0.0"
HUA_GAI_PACKAGE_ID = "liuyao.shensha.huagai_day_branch.v1"
HUA_GAI_PACKAGE_VERSION = "1.0.0"

PILLAR_ORDER = ("year", "month", "day", "hour")
PILLAR_LABELS = {"year": "年", "month": "月", "day": "日", "hour": "时"}
BRANCH_ORDER = tuple("子丑寅卯辰巳午未申酉戌亥")
TWELVE_STAGES = (
    "长生",
    "沐浴",
    "冠带",
    "临官",
    "帝旺",
    "衰",
    "病",
    "死",
    "墓",
    "绝",
    "胎",
    "养",
)

# 《卜筮全书》五行长生：木亥、火寅、水土申、金巳，皆顺行。
FIVE_ELEMENT_START_BRANCHES = {
    "木": "亥",
    "火": "寅",
    "土": "申",
    "金": "巳",
    "水": "申",
}

# 《卜筮全书》天元禄：十干以临官位为禄。
LU_SHEN_BY_DAY_STEM = {
    "甲": "寅",
    "乙": "卯",
    "丙": "巳",
    "丁": "午",
    "戊": "巳",
    "己": "午",
    "庚": "申",
    "辛": "酉",
    "壬": "亥",
    "癸": "子",
}

# 《卜筮全书》天乙贵人：甲戊牛羊、乙己鼠猴、丙丁猪鸡、
# 壬癸兔蛇、庚辛马虎。目标支顺序按原口诀保留。
TIAN_YI_BY_DAY_STEM = {
    "甲": ("丑", "未"),
    "乙": ("子", "申"),
    "丙": ("亥", "酉"),
    "丁": ("亥", "酉"),
    "戊": ("丑", "未"),
    "己": ("子", "申"),
    "庚": ("午", "寅"),
    "辛": ("午", "寅"),
    "壬": ("卯", "巳"),
    "癸": ("卯", "巳"),
}

# 《增删卜易》星煞章明确以占日日支起驿马；
# 申子辰见寅、巳酉丑见亥、寅午戌见申、亥卯未见巳。
YI_MA_BY_DAY_BRANCH = {
    "子": "寅",
    "丑": "亥",
    "寅": "申",
    "卯": "巳",
    "辰": "寅",
    "巳": "亥",
    "午": "申",
    "未": "巳",
    "申": "寅",
    "酉": "亥",
    "戌": "申",
    "亥": "巳",
}

# 《古筮真诠（总论易理篇）》第 111 页明确以日支为标尺：
# 申子辰见酉、巳酉丑见午、寅午戌见卯、亥卯未见子。
# 产品显示名用“桃花”，规范名用古籍常见名称“咸池”。
TAO_HUA_BY_DAY_BRANCH = {
    "子": "酉",
    "丑": "午",
    "寅": "卯",
    "卯": "子",
    "辰": "酉",
    "巳": "午",
    "午": "卯",
    "未": "子",
    "申": "酉",
    "酉": "午",
    "戌": "卯",
    "亥": "子",
}

# 《卜筮全书》给出四组三合局将星表，《古筮真诠（总论易理篇）》
# 第 111 页明确现代六爻以日支为标尺：申子辰见子、巳酉丑见酉、
# 寅午戌见午、亥卯未见卯。出师章的农历月序将星属于另一规则包。
JIANG_XING_BY_DAY_BRANCH = {
    "子": "子",
    "丑": "酉",
    "寅": "午",
    "卯": "卯",
    "辰": "子",
    "巳": "酉",
    "午": "午",
    "未": "卯",
    "申": "子",
    "酉": "酉",
    "戌": "午",
    "亥": "卯",
}

# 《卜筮全书》马前神杀以驿马为第一位、华盖为第三位；
# 《古筮真诠（总论易理篇）》第 111 页明确现代六爻以日支为标尺：
# 申子辰见辰、巳酉丑见丑、寅午戌见戌、亥卯未见未。
# 《易林补遗》的农历月序华盖属于另一规则包。
HUA_GAI_BY_DAY_BRANCH = {
    "子": "辰",
    "丑": "丑",
    "寅": "戌",
    "卯": "未",
    "辰": "辰",
    "巳": "丑",
    "午": "戌",
    "未": "未",
    "申": "辰",
    "酉": "丑",
    "戌": "戌",
    "亥": "未",
}


def annotation_rule_package() -> dict[str, Any]:
    return {
        "id": ANNOTATION_PACKAGE_ID,
        "version": ANNOTATION_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012"],
        "system": "five_elements_forward",
    }


def lu_shen_rule_package() -> dict[str, Any]:
    return {
        "id": LU_SHEN_PACKAGE_ID,
        "version": LU_SHEN_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012"],
        "system": "day_stem_to_visible_base_line_branch",
    }


def tian_yi_rule_package() -> dict[str, Any]:
    return {
        "id": TIAN_YI_PACKAGE_ID,
        "version": TIAN_YI_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012"],
        "system": "day_stem_to_visible_base_line_branches",
    }


def yi_ma_rule_package() -> dict[str, Any]:
    return {
        "id": YI_MA_PACKAGE_ID,
        "version": YI_MA_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012", "SRC-016"],
        "system": "day_branch_to_visible_base_line_branch",
    }


def tao_hua_rule_package() -> dict[str, Any]:
    return {
        "id": TAO_HUA_PACKAGE_ID,
        "version": TAO_HUA_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012", "SRC-015", "SRC-017"],
        "system": "day_branch_to_visible_base_line_branch",
    }


def jiang_xing_rule_package() -> dict[str, Any]:
    return {
        "id": JIANG_XING_PACKAGE_ID,
        "version": JIANG_XING_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012", "SRC-015"],
        "system": "day_branch_to_visible_base_line_branch",
    }


def hua_gai_rule_package() -> dict[str, Any]:
    return {
        "id": HUA_GAI_PACKAGE_ID,
        "version": HUA_GAI_PACKAGE_VERSION,
        "status": "provisional_authority",
        "source_ids": ["SRC-011", "SRC-012", "SRC-015"],
        "system": "day_branch_to_visible_base_line_branch",
    }


def twelve_stage(element: str, reference_branch: str) -> str:
    """Return one of the twelve stages for an element at a branch."""
    try:
        start_index = BRANCH_ORDER.index(FIVE_ELEMENT_START_BRANCHES[element])
    except KeyError as error:
        raise ValueError(f"invalid five-element value: {element!r}") from error
    try:
        branch_index = BRANCH_ORDER.index(reference_branch)
    except ValueError as error:
        raise ValueError(f"invalid earthly branch: {reference_branch!r}") from error
    return TWELVE_STAGES[(branch_index - start_index) % len(BRANCH_ORDER)]


def build_five_element_twelve_stages(
    base_lines: list[dict[str, Any]],
    project_pillars: dict[str, dict[str, str]],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Annotate every base line against all four project-authority pillars."""
    missing_pillars = [name for name in PILLAR_ORDER if name not in project_pillars]
    if missing_pillars:
        raise ValueError(f"missing pillars for twelve stages: {missing_pillars}")

    line_results: list[dict[str, Any]] = []
    calculation_steps = [
        "采用五行顺行十二长生：木亥、火寅、土申、金巳、水申起长生",
        "阶段固定为：" + " → ".join(TWELVE_STAGES),
    ]
    for line in base_lines:
        element = line["element"]
        pillar_results = []
        for reference in PILLAR_ORDER:
            pillar = project_pillars[reference]
            branch = pillar["branch"]
            stage = twelve_stage(element, branch)
            pillar_result = {
                "reference": reference,
                "reference_label": PILLAR_LABELS[reference],
                "pillar_gan_zhi": pillar["gan_zhi"],
                "reference_branch": branch,
                "stage": stage,
            }
            pillar_results.append(pillar_result)
            calculation_steps.append(
                f'{line["position_name"]}{element}：'
                f'{PILLAR_LABELS[reference]}支{branch} → {stage}'
            )
        line_results.append(
            {
                "line_id": line["id"],
                "position": line["position"],
                "position_name": line["position_name"],
                "line_element": element,
                "pillar_results": pillar_results,
            }
        )

    result = {
        "rule_id": "annotation.wuxing_twelve_stages.forward.v1",
        "rule_version": ANNOTATION_PACKAGE_VERSION,
        "system": "five_elements_forward",
        "scope": "base_lines",
        "reference_order": list(PILLAR_ORDER),
        "stage_order": list(TWELVE_STAGES),
        "start_branches": dict(FIVE_ELEMENT_START_BRANCHES),
        "line_results": line_results,
    }
    trace = {
        "rule_id": result["rule_id"],
        "label": "五行十二长生",
        "scope": "rule_annotations",
        "inputs": {
            "line_elements": [
                {"line_id": line["id"], "element": line["element"]}
                for line in base_lines
            ],
            "pillars": {
                name: project_pillars[name]
                for name in PILLAR_ORDER
            },
            "start_branches": dict(FIVE_ELEMENT_START_BRANCHES),
        },
        "steps": calculation_steps,
        "result": line_results,
        "rule_version": ANNOTATION_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012"],
    }
    return result, trace


def build_lu_shen(
    base_lines: list[dict[str, Any]],
    day_pillar: dict[str, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate day-stem Lu Shen and match visible base-chart branches."""
    day_stem = day_pillar.get("stem", "")
    try:
        target_branch = LU_SHEN_BY_DAY_STEM[day_stem]
    except KeyError as error:
        raise ValueError(f"invalid day stem for lu shen: {day_stem!r}") from error

    matches = [
        {
            "line_id": line["id"],
            "position": line["position"],
            "position_name": line["position_name"],
            "gan_zhi": line["gan_zhi"],
            "branch": line["earthly_branch"],
            "relation": line["relation"],
        }
        for line in base_lines
        if line["earthly_branch"] == target_branch
    ]
    status = "computed_match" if matches else "computed_no_match"
    result = {
        "rule_id": "shensha.lushen.day_stem.v1",
        "rule_version": LU_SHEN_PACKAGE_VERSION,
        "display_name": "禄神",
        "canonical_name": "天元禄",
        "aliases": ["禄神", "天元禄"],
        "category": "stem_shensha",
        "scope": "base_visible_lines",
        "basis": {
            "type": "day_stem",
            "pillar_gan_zhi": day_pillar["gan_zhi"],
            "value": day_stem,
        },
        "target_branches": [target_branch],
        "status": status,
        "matches": matches,
        "excluded_scopes": ["hidden", "changed"],
    }
    scan_steps = [
        f'{line["position_name"]}{line["gan_zhi"]}：'
        f'爻支{line["earthly_branch"]} '
        f'{"=" if line["earthly_branch"] == target_branch else "≠"} '
        f'禄支{target_branch} → '
        f'{"命中" if line["earthly_branch"] == target_branch else "未命中"}'
        for line in base_lines
    ]
    trace = {
        "rule_id": result["rule_id"],
        "label": "禄神",
        "scope": "rule_annotations",
        "inputs": {
            "day_pillar": day_pillar,
            "lookup_table": dict(LU_SHEN_BY_DAY_STEM),
            "base_visible_line_branches": [
                {
                    "line_id": line["id"],
                    "branch": line["earthly_branch"],
                }
                for line in base_lines
            ],
        },
        "steps": [
            f'读取项目日柱 {day_pillar["gan_zhi"]}，取日干 {day_stem}',
            f"查天元禄表：{day_stem}干禄在{target_branch}",
            *scan_steps,
            (
                "命中本卦明爻："
                + "、".join(item["position_name"] for item in matches)
                if matches
                else f"本卦六个明爻均无{target_branch}支，结果为已计算未命中"
            ),
            "v1 不扫描伏神与变卦爻",
        ],
        "result": result,
        "rule_version": LU_SHEN_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012"],
    }
    return result, trace


def build_tian_yi(
    base_lines: list[dict[str, Any]],
    day_pillar: dict[str, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate day-stem Tian Yi and match both target branches in order."""
    day_stem = day_pillar.get("stem", "")
    try:
        target_branches = TIAN_YI_BY_DAY_STEM[day_stem]
    except KeyError as error:
        raise ValueError(f"invalid day stem for tian yi: {day_stem!r}") from error

    matches = [
        {
            "line_id": line["id"],
            "position": line["position"],
            "position_name": line["position_name"],
            "gan_zhi": line["gan_zhi"],
            "branch": line["earthly_branch"],
            "relation": line["relation"],
            "target_index": target_branches.index(line["earthly_branch"]),
        }
        for line in base_lines
        if line["earthly_branch"] in target_branches
    ]
    matches.sort(key=lambda item: (item["target_index"], item["position"]))
    status = "computed_match" if matches else "computed_no_match"
    result = {
        "rule_id": "shensha.tianyi.day_stem.v1",
        "rule_version": TIAN_YI_PACKAGE_VERSION,
        "display_name": "天乙",
        "canonical_name": "天乙贵人",
        "aliases": ["天乙", "天乙贵人"],
        "category": "stem_shensha",
        "scope": "base_visible_lines",
        "basis": {
            "type": "day_stem",
            "pillar_gan_zhi": day_pillar["gan_zhi"],
            "value": day_stem,
        },
        "target_branches": list(target_branches),
        "status": status,
        "matches": matches,
        "excluded_scopes": ["hidden", "changed"],
    }
    scan_steps = [
        f'{line["position_name"]}{line["gan_zhi"]}：'
        f'爻支{line["earthly_branch"]} '
        f'{"∈" if line["earthly_branch"] in target_branches else "∉"} '
        f'天乙支{"、".join(target_branches)} → '
        f'{"命中" if line["earthly_branch"] in target_branches else "未命中"}'
        for line in base_lines
    ]
    trace = {
        "rule_id": result["rule_id"],
        "label": "天乙贵人",
        "scope": "rule_annotations",
        "inputs": {
            "day_pillar": day_pillar,
            "lookup_table": {
                stem: list(branches)
                for stem, branches in TIAN_YI_BY_DAY_STEM.items()
            },
            "base_visible_line_branches": [
                {
                    "line_id": line["id"],
                    "branch": line["earthly_branch"],
                }
                for line in base_lines
            ],
        },
        "steps": [
            f'读取项目日柱 {day_pillar["gan_zhi"]}，取日干 {day_stem}',
            f'查天乙贵人表：{day_stem}干天乙在{"、".join(target_branches)}',
            *scan_steps,
            (
                "命中本卦明爻："
                + "、".join(item["position_name"] for item in matches)
                if matches
                else (
                    f'本卦六个明爻均无{"、".join(target_branches)}支，'
                    "结果为已计算未命中"
                )
            ),
            "v1 不扫描伏神与变卦爻",
        ],
        "result": result,
        "rule_version": TIAN_YI_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012"],
    }
    return result, trace


def build_yi_ma(
    base_lines: list[dict[str, Any]],
    day_pillar: dict[str, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate day-branch Yi Ma and match every visible base-chart branch."""
    day_branch = day_pillar.get("branch", "")
    try:
        target_branch = YI_MA_BY_DAY_BRANCH[day_branch]
    except KeyError as error:
        raise ValueError(f"invalid day branch for yi ma: {day_branch!r}") from error

    matches = [
        {
            "line_id": line["id"],
            "position": line["position"],
            "position_name": line["position_name"],
            "gan_zhi": line["gan_zhi"],
            "branch": line["earthly_branch"],
            "relation": line["relation"],
        }
        for line in base_lines
        if line["earthly_branch"] == target_branch
    ]
    status = "computed_match" if matches else "computed_no_match"
    result = {
        "rule_id": "shensha.yima.day_branch.v1",
        "rule_version": YI_MA_PACKAGE_VERSION,
        "display_name": "驿马",
        "canonical_name": "驿马",
        "aliases": ["驿马", "驛馬"],
        "category": "branch_shensha",
        "scope": "base_visible_lines",
        "basis": {
            "type": "day_branch",
            "pillar_gan_zhi": day_pillar["gan_zhi"],
            "value": day_branch,
        },
        "target_branches": [target_branch],
        "status": status,
        "matches": matches,
        "excluded_scopes": ["hidden", "changed"],
    }
    scan_steps = [
        f'{line["position_name"]}{line["gan_zhi"]}：'
        f'爻支{line["earthly_branch"]} '
        f'{"=" if line["earthly_branch"] == target_branch else "≠"} '
        f'驿马支{target_branch} → '
        f'{"命中" if line["earthly_branch"] == target_branch else "未命中"}'
        for line in base_lines
    ]
    trace = {
        "rule_id": result["rule_id"],
        "label": "驿马",
        "scope": "rule_annotations",
        "inputs": {
            "day_pillar": day_pillar,
            "lookup_table": dict(YI_MA_BY_DAY_BRANCH),
            "base_visible_line_branches": [
                {
                    "line_id": line["id"],
                    "branch": line["earthly_branch"],
                }
                for line in base_lines
            ],
        },
        "steps": [
            f'读取项目日柱 {day_pillar["gan_zhi"]}，取日支 {day_branch}',
            f"查驿马表：{day_branch}日驿马在{target_branch}",
            *scan_steps,
            (
                "命中本卦明爻："
                + "、".join(item["position_name"] for item in matches)
                if matches
                else f"本卦六个明爻均无{target_branch}支，结果为已计算未命中"
            ),
            "v1 不扫描伏神与变卦爻",
        ],
        "result": result,
        "rule_version": YI_MA_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012", "SRC-016"],
    }
    return result, trace


def build_tao_hua(
    base_lines: list[dict[str, Any]],
    day_pillar: dict[str, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate day-branch Tao Hua/Xian Chi on visible base-chart lines."""
    day_branch = day_pillar.get("branch", "")
    try:
        target_branch = TAO_HUA_BY_DAY_BRANCH[day_branch]
    except KeyError as error:
        raise ValueError(
            f"invalid day branch for tao hua: {day_branch!r}"
        ) from error

    matches = [
        {
            "line_id": line["id"],
            "position": line["position"],
            "position_name": line["position_name"],
            "gan_zhi": line["gan_zhi"],
            "branch": line["earthly_branch"],
            "relation": line["relation"],
        }
        for line in base_lines
        if line["earthly_branch"] == target_branch
    ]
    status = "computed_match" if matches else "computed_no_match"
    result = {
        "rule_id": "shensha.taohua.day_branch.v1",
        "rule_version": TAO_HUA_PACKAGE_VERSION,
        "display_name": "桃花",
        "canonical_name": "咸池",
        "aliases": ["桃花", "桃花煞", "咸池", "咸池杀"],
        "category": "branch_shensha",
        "scope": "base_visible_lines",
        "basis": {
            "type": "day_branch",
            "pillar_gan_zhi": day_pillar["gan_zhi"],
            "value": day_branch,
        },
        "target_branches": [target_branch],
        "status": status,
        "matches": matches,
        "excluded_scopes": ["hidden", "changed"],
    }
    scan_steps = [
        f'{line["position_name"]}{line["gan_zhi"]}：'
        f'爻支{line["earthly_branch"]} '
        f'{"=" if line["earthly_branch"] == target_branch else "≠"} '
        f'桃花支{target_branch} → '
        f'{"命中" if line["earthly_branch"] == target_branch else "未命中"}'
        for line in base_lines
    ]
    trace = {
        "rule_id": result["rule_id"],
        "label": "桃花（咸池）",
        "scope": "rule_annotations",
        "inputs": {
            "day_pillar": day_pillar,
            "lookup_table": dict(TAO_HUA_BY_DAY_BRANCH),
            "base_visible_line_branches": [
                {
                    "line_id": line["id"],
                    "branch": line["earthly_branch"],
                }
                for line in base_lines
            ],
        },
        "steps": [
            f'读取项目日柱 {day_pillar["gan_zhi"]}，取日支 {day_branch}',
            f"查桃花（咸池）表：{day_branch}日桃花在{target_branch}",
            *scan_steps,
            (
                "命中本卦明爻："
                + "、".join(item["position_name"] for item in matches)
                if matches
                else f"本卦六个明爻均无{target_branch}支，结果为已计算未命中"
            ),
            "v1 不扫描伏神与变卦爻，也不读取月支或年支",
        ],
        "result": result,
        "rule_version": TAO_HUA_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012", "SRC-015", "SRC-017"],
    }
    return result, trace


def build_jiang_xing(
    base_lines: list[dict[str, Any]],
    day_pillar: dict[str, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate day-branch Jiang Xing on visible base-chart lines."""
    day_branch = day_pillar.get("branch", "")
    try:
        target_branch = JIANG_XING_BY_DAY_BRANCH[day_branch]
    except KeyError as error:
        raise ValueError(
            f"invalid day branch for jiang xing: {day_branch!r}"
        ) from error

    matches = [
        {
            "line_id": line["id"],
            "position": line["position"],
            "position_name": line["position_name"],
            "gan_zhi": line["gan_zhi"],
            "branch": line["earthly_branch"],
            "relation": line["relation"],
        }
        for line in base_lines
        if line["earthly_branch"] == target_branch
    ]
    status = "computed_match" if matches else "computed_no_match"
    result = {
        "rule_id": "shensha.jiangxing.day_branch.v1",
        "rule_version": JIANG_XING_PACKAGE_VERSION,
        "display_name": "将星",
        "canonical_name": "将星",
        "aliases": ["将星", "將星", "将曜", "將曜"],
        "category": "branch_shensha",
        "scope": "base_visible_lines",
        "basis": {
            "type": "day_branch",
            "pillar_gan_zhi": day_pillar["gan_zhi"],
            "value": day_branch,
        },
        "target_branches": [target_branch],
        "status": status,
        "matches": matches,
        "excluded_scopes": ["hidden", "changed"],
    }
    scan_steps = [
        f'{line["position_name"]}{line["gan_zhi"]}：'
        f'爻支{line["earthly_branch"]} '
        f'{"=" if line["earthly_branch"] == target_branch else "≠"} '
        f'将星支{target_branch} → '
        f'{"命中" if line["earthly_branch"] == target_branch else "未命中"}'
        for line in base_lines
    ]
    trace = {
        "rule_id": result["rule_id"],
        "label": "将星",
        "scope": "rule_annotations",
        "inputs": {
            "day_pillar": day_pillar,
            "lookup_table": dict(JIANG_XING_BY_DAY_BRANCH),
            "base_visible_line_branches": [
                {
                    "line_id": line["id"],
                    "branch": line["earthly_branch"],
                }
                for line in base_lines
            ],
        },
        "steps": [
            f'读取项目日柱 {day_pillar["gan_zhi"]}，取日支 {day_branch}',
            f"查将星表：{day_branch}日将星在{target_branch}",
            *scan_steps,
            (
                "命中本卦明爻："
                + "、".join(item["position_name"] for item in matches)
                if matches
                else f"本卦六个明爻均无{target_branch}支，结果为已计算未命中"
            ),
            "v1 不扫描伏神与变卦爻，也不读取年支或农历月序将星",
        ],
        "result": result,
        "rule_version": JIANG_XING_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012", "SRC-015"],
    }
    return result, trace


def build_hua_gai(
    base_lines: list[dict[str, Any]],
    day_pillar: dict[str, str],
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Calculate day-branch Hua Gai on visible base-chart lines."""
    day_branch = day_pillar.get("branch", "")
    try:
        target_branch = HUA_GAI_BY_DAY_BRANCH[day_branch]
    except KeyError as error:
        raise ValueError(f"invalid day branch for hua gai: {day_branch!r}") from error

    matches = [
        {
            "line_id": line["id"],
            "position": line["position"],
            "position_name": line["position_name"],
            "gan_zhi": line["gan_zhi"],
            "branch": line["earthly_branch"],
            "relation": line["relation"],
        }
        for line in base_lines
        if line["earthly_branch"] == target_branch
    ]
    status = "computed_match" if matches else "computed_no_match"
    result = {
        "rule_id": "shensha.huagai.day_branch.v1",
        "rule_version": HUA_GAI_PACKAGE_VERSION,
        "display_name": "华盖",
        "canonical_name": "华盖",
        "aliases": ["华盖", "華蓋"],
        "category": "branch_shensha",
        "scope": "base_visible_lines",
        "basis": {
            "type": "day_branch",
            "pillar_gan_zhi": day_pillar["gan_zhi"],
            "value": day_branch,
        },
        "target_branches": [target_branch],
        "status": status,
        "matches": matches,
        "excluded_scopes": ["hidden", "changed"],
    }
    scan_steps = [
        f'{line["position_name"]}{line["gan_zhi"]}：'
        f'爻支{line["earthly_branch"]} '
        f'{"=" if line["earthly_branch"] == target_branch else "≠"} '
        f'华盖支{target_branch} → '
        f'{"命中" if line["earthly_branch"] == target_branch else "未命中"}'
        for line in base_lines
    ]
    trace = {
        "rule_id": result["rule_id"],
        "label": "华盖",
        "scope": "rule_annotations",
        "inputs": {
            "day_pillar": day_pillar,
            "lookup_table": dict(HUA_GAI_BY_DAY_BRANCH),
            "base_visible_line_branches": [
                {
                    "line_id": line["id"],
                    "branch": line["earthly_branch"],
                }
                for line in base_lines
            ],
        },
        "steps": [
            f'读取项目日柱 {day_pillar["gan_zhi"]}，取日支 {day_branch}',
            f"查华盖表：{day_branch}日华盖在{target_branch}",
            *scan_steps,
            (
                "命中本卦明爻："
                + "、".join(item["position_name"] for item in matches)
                if matches
                else f"本卦六个明爻均无{target_branch}支，结果为已计算未命中"
            ),
            "v1 包含本卦动爻，但不扫描伏神、变卦爻、年支或农历月序华盖",
        ],
        "result": result,
        "rule_version": HUA_GAI_PACKAGE_VERSION,
        "source_ids": ["SRC-011", "SRC-012", "SRC-015"],
    }
    return result, trace
