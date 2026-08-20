import unittest

from app.rule_annotations import (
    BRANCH_ORDER,
    FIVE_ELEMENT_START_BRANCHES,
    HUA_GAI_BY_DAY_BRANCH,
    JIANG_XING_BY_DAY_BRANCH,
    LU_SHEN_BY_DAY_STEM,
    TAO_HUA_BY_DAY_BRANCH,
    TIAN_YI_BY_DAY_STEM,
    TWELVE_STAGES,
    YI_MA_BY_DAY_BRANCH,
    build_five_element_twelve_stages,
    build_hua_gai,
    build_jiang_xing,
    build_lu_shen,
    build_tao_hua,
    build_tian_yi,
    build_yi_ma,
    twelve_stage,
)


class FiveElementTwelveStagesTest(unittest.TestCase):
    def test_complete_five_by_twelve_table_is_forward_and_bijective(self) -> None:
        self.assertEqual(
            FIVE_ELEMENT_START_BRANCHES,
            {"木": "亥", "火": "寅", "土": "申", "金": "巳", "水": "申"},
        )
        for element in FIVE_ELEMENT_START_BRANCHES:
            with self.subTest(element=element):
                values = [twelve_stage(element, branch) for branch in BRANCH_ORDER]
                self.assertEqual(set(values), set(TWELVE_STAGES))
                self.assertEqual(
                    twelve_stage(element, FIVE_ELEMENT_START_BRANCHES[element]),
                    "长生",
                )

    def test_fixed_line_and_four_pillars_have_auditable_results(self) -> None:
        result, trace = build_five_element_twelve_stages(
            [
                {
                    "id": "base-1",
                    "position": 1,
                    "position_name": "初爻",
                    "element": "水",
                }
            ],
            {
                "year": {"gan_zhi": "丙午", "stem": "丙", "branch": "午"},
                "month": {"gan_zhi": "乙未", "stem": "乙", "branch": "未"},
                "day": {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
                "hour": {"gan_zhi": "丙申", "stem": "丙", "branch": "申"},
            },
        )

        self.assertEqual(result["system"], "five_elements_forward")
        self.assertEqual(result["scope"], "base_lines")
        self.assertEqual(
            [item["stage"] for item in result["line_results"][0]["pillar_results"]],
            ["胎", "养", "临官", "长生"],
        )
        self.assertEqual(trace["source_ids"], ["SRC-011", "SRC-012"])
        self.assertIn("初爻水：日支亥 → 临官", trace["steps"])

    def test_invalid_element_and_branch_fail_loudly(self) -> None:
        with self.assertRaisesRegex(ValueError, "invalid five-element"):
            twelve_stage("风", "子")
        with self.assertRaisesRegex(ValueError, "invalid earthly branch"):
            twelve_stage("木", "甲")


class LuShenTest(unittest.TestCase):
    def test_complete_day_stem_table_is_explicit(self) -> None:
        self.assertEqual(
            LU_SHEN_BY_DAY_STEM,
            {
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
            },
        )

    def test_fixed_xin_day_matches_visible_you_line(self) -> None:
        lines = [
            {
                "id": "base-1",
                "position": 1,
                "position_name": "初爻",
                "gan_zhi": "甲子",
                "earthly_branch": "子",
                "relation": "妻财",
            },
            {
                "id": "base-5",
                "position": 5,
                "position_name": "五爻",
                "gan_zhi": "丁酉",
                "earthly_branch": "酉",
                "relation": "子孙",
            },
        ]
        result, trace = build_lu_shen(
            lines,
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )

        self.assertEqual(result["status"], "computed_match")
        self.assertEqual(result["target_branches"], ["酉"])
        self.assertEqual(result["matches"][0]["line_id"], "base-5")
        self.assertEqual(result["excluded_scopes"], ["hidden", "changed"])
        self.assertIn("五爻丁酉：爻支酉 = 禄支酉 → 命中", trace["steps"])

    def test_calculated_no_match_is_not_omitted(self) -> None:
        result, trace = build_lu_shen(
            [
                {
                    "id": "base-1",
                    "position": 1,
                    "position_name": "初爻",
                    "gan_zhi": "甲子",
                    "earthly_branch": "子",
                    "relation": "妻财",
                }
            ],
            {"gan_zhi": "甲辰", "stem": "甲", "branch": "辰"},
        )
        self.assertEqual(result["status"], "computed_no_match")
        self.assertEqual(result["matches"], [])
        self.assertIn("结果为已计算未命中", trace["steps"][-2])


class TianYiTest(unittest.TestCase):
    def test_complete_day_stem_table_preserves_two_target_order(self) -> None:
        self.assertEqual(
            TIAN_YI_BY_DAY_STEM,
            {
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
            },
        )

    def test_fixed_xin_day_keeps_both_targets_and_matches_yin(self) -> None:
        lines = [
            {
                "id": "base-2",
                "position": 2,
                "position_name": "二爻",
                "gan_zhi": "甲寅",
                "earthly_branch": "寅",
                "relation": "官鬼",
            },
            {
                "id": "base-6",
                "position": 6,
                "position_name": "上爻",
                "gan_zhi": "丁未",
                "earthly_branch": "未",
                "relation": "兄弟",
            },
        ]
        result, trace = build_tian_yi(
            lines,
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(result["target_branches"], ["午", "寅"])
        self.assertEqual(result["status"], "computed_match")
        self.assertEqual(
            [(item["line_id"], item["target_index"]) for item in result["matches"]],
            [("base-2", 1)],
        )
        self.assertIn("二爻甲寅：爻支寅 ∈ 天乙支午、寅 → 命中", trace["steps"])

    def test_multiple_targets_and_multiple_lines_are_all_returned_in_target_order(self) -> None:
        lines = [
            {
                "id": "base-1",
                "position": 1,
                "position_name": "初爻",
                "gan_zhi": "乙未",
                "earthly_branch": "未",
                "relation": "兄弟",
            },
            {
                "id": "base-2",
                "position": 2,
                "position_name": "二爻",
                "gan_zhi": "乙丑",
                "earthly_branch": "丑",
                "relation": "父母",
            },
            {
                "id": "base-3",
                "position": 3,
                "position_name": "三爻",
                "gan_zhi": "丁丑",
                "earthly_branch": "丑",
                "relation": "父母",
            },
        ]
        result, _ = build_tian_yi(
            lines,
            {"gan_zhi": "甲辰", "stem": "甲", "branch": "辰"},
        )
        self.assertEqual(
            [item["line_id"] for item in result["matches"]],
            ["base-2", "base-3", "base-1"],
        )

    def test_calculated_no_match_retains_both_targets(self) -> None:
        result, trace = build_tian_yi(
            [
                {
                    "id": "base-1",
                    "position": 1,
                    "position_name": "初爻",
                    "gan_zhi": "甲子",
                    "earthly_branch": "子",
                    "relation": "妻财",
                }
            ],
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(result["target_branches"], ["午", "寅"])
        self.assertEqual(result["status"], "computed_no_match")
        self.assertEqual(result["matches"], [])
        self.assertIn("结果为已计算未命中", trace["steps"][-2])


class YiMaTest(unittest.TestCase):
    def test_complete_day_branch_table_is_explicit(self) -> None:
        self.assertEqual(
            YI_MA_BY_DAY_BRANCH,
            {
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
            },
        )

    def test_fixed_hai_day_matches_all_visible_si_lines(self) -> None:
        lines = [
            {
                "id": "base-1",
                "position": 1,
                "position_name": "初爻",
                "gan_zhi": "乙巳",
                "earthly_branch": "巳",
                "relation": "父母",
            },
            {
                "id": "base-4",
                "position": 4,
                "position_name": "四爻",
                "gan_zhi": "癸巳",
                "earthly_branch": "巳",
                "relation": "妻财",
            },
        ]
        result, trace = build_yi_ma(
            lines,
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )

        self.assertEqual(result["basis"]["type"], "day_branch")
        self.assertEqual(result["target_branches"], ["巳"])
        self.assertEqual(result["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in result["matches"]],
            ["base-1", "base-4"],
        )
        self.assertEqual(
            trace["source_ids"],
            ["SRC-011", "SRC-012", "SRC-016"],
        )
        self.assertIn("四爻癸巳：爻支巳 = 驿马支巳 → 命中", trace["steps"])

    def test_calculated_no_match_does_not_treat_hidden_line_as_visible(self) -> None:
        result, trace = build_yi_ma(
            [
                {
                    "id": "base-2",
                    "position": 2,
                    "position_name": "二爻",
                    "gan_zhi": "甲寅",
                    "earthly_branch": "寅",
                    "relation": "官鬼",
                    "hidden": {"earthly_branch": "巳"},
                }
            ],
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(result["status"], "computed_no_match")
        self.assertEqual(result["matches"], [])
        self.assertEqual(result["excluded_scopes"], ["hidden", "changed"])
        self.assertIn("结果为已计算未命中", trace["steps"][-2])

    def test_invalid_day_branch_fails_loudly(self) -> None:
        with self.assertRaisesRegex(ValueError, "invalid day branch for yi ma"):
            build_yi_ma([], {"gan_zhi": "辛亥", "stem": "辛", "branch": ""})


class TaoHuaTest(unittest.TestCase):
    def test_complete_day_branch_table_is_explicit(self) -> None:
        self.assertEqual(
            TAO_HUA_BY_DAY_BRANCH,
            {
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
            },
        )

    def test_fixed_hai_day_matches_all_visible_zi_lines(self) -> None:
        lines = [
            {
                "id": "base-1",
                "position": 1,
                "position_name": "初爻",
                "gan_zhi": "甲子",
                "earthly_branch": "子",
                "relation": "妻财",
            },
            {
                "id": "base-5",
                "position": 5,
                "position_name": "五爻",
                "gan_zhi": "戊子",
                "earthly_branch": "子",
                "relation": "子孙",
            },
        ]
        result, trace = build_tao_hua(
            lines,
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )

        self.assertEqual(result["display_name"], "桃花")
        self.assertEqual(result["canonical_name"], "咸池")
        self.assertEqual(result["aliases"], ["桃花", "桃花煞", "咸池", "咸池杀"])
        self.assertEqual(result["basis"]["type"], "day_branch")
        self.assertEqual(result["target_branches"], ["子"])
        self.assertEqual(result["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in result["matches"]],
            ["base-1", "base-5"],
        )
        self.assertEqual(
            trace["source_ids"],
            ["SRC-011", "SRC-012", "SRC-015", "SRC-017"],
        )
        self.assertIn("五爻戊子：爻支子 = 桃花支子 → 命中", trace["steps"])

    def test_calculated_no_match_does_not_treat_hidden_line_as_visible(self) -> None:
        result, trace = build_tao_hua(
            [
                {
                    "id": "base-2",
                    "position": 2,
                    "position_name": "二爻",
                    "gan_zhi": "甲寅",
                    "earthly_branch": "寅",
                    "relation": "官鬼",
                    "hidden": {"earthly_branch": "子"},
                }
            ],
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(result["status"], "computed_no_match")
        self.assertEqual(result["matches"], [])
        self.assertEqual(result["excluded_scopes"], ["hidden", "changed"])
        self.assertIn("结果为已计算未命中", trace["steps"][-2])

    def test_invalid_day_branch_fails_loudly(self) -> None:
        with self.assertRaisesRegex(ValueError, "invalid day branch for tao hua"):
            build_tao_hua([], {"gan_zhi": "辛亥", "stem": "辛", "branch": ""})


class JiangXingTest(unittest.TestCase):
    def test_complete_day_branch_table_is_explicit(self) -> None:
        self.assertEqual(
            JIANG_XING_BY_DAY_BRANCH,
            {
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
            },
        )

    def test_fixed_hai_day_matches_all_visible_mao_lines(self) -> None:
        lines = [
            {
                "id": "base-1",
                "position": 1,
                "position_name": "初爻",
                "gan_zhi": "乙卯",
                "earthly_branch": "卯",
                "relation": "妻财",
            },
            {
                "id": "base-5",
                "position": 5,
                "position_name": "五爻",
                "gan_zhi": "丁卯",
                "earthly_branch": "卯",
                "relation": "子孙",
            },
        ]
        result, trace = build_jiang_xing(
            lines,
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )

        self.assertEqual(result["aliases"], ["将星", "將星", "将曜", "將曜"])
        self.assertEqual(result["basis"]["type"], "day_branch")
        self.assertEqual(result["target_branches"], ["卯"])
        self.assertEqual(result["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in result["matches"]],
            ["base-1", "base-5"],
        )
        self.assertEqual(
            trace["source_ids"],
            ["SRC-011", "SRC-012", "SRC-015"],
        )
        self.assertIn("五爻丁卯：爻支卯 = 将星支卯 → 命中", trace["steps"])

    def test_calculated_no_match_does_not_treat_hidden_line_as_visible(self) -> None:
        result, trace = build_jiang_xing(
            [
                {
                    "id": "base-2",
                    "position": 2,
                    "position_name": "二爻",
                    "gan_zhi": "甲寅",
                    "earthly_branch": "寅",
                    "relation": "官鬼",
                    "hidden": {"earthly_branch": "卯"},
                }
            ],
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(result["status"], "computed_no_match")
        self.assertEqual(result["matches"], [])
        self.assertEqual(result["excluded_scopes"], ["hidden", "changed"])
        self.assertIn("结果为已计算未命中", trace["steps"][-2])
        self.assertIn("农历月序将星", trace["steps"][-1])

    def test_invalid_day_branch_fails_loudly(self) -> None:
        with self.assertRaisesRegex(ValueError, "invalid day branch for jiang xing"):
            build_jiang_xing([], {"gan_zhi": "辛亥", "stem": "辛", "branch": ""})


class HuaGaiTest(unittest.TestCase):
    def test_complete_day_branch_table_is_explicit(self) -> None:
        self.assertEqual(
            HUA_GAI_BY_DAY_BRANCH,
            {
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
            },
        )

    def test_fixed_hai_day_matches_all_visible_wei_lines(self) -> None:
        lines = [
            {
                "id": "base-1",
                "position": 1,
                "position_name": "初爻",
                "gan_zhi": "乙未",
                "earthly_branch": "未",
                "relation": "妻财",
            },
            {
                "id": "base-6",
                "position": 6,
                "position_name": "上爻",
                "gan_zhi": "丁未",
                "earthly_branch": "未",
                "relation": "兄弟",
                "changing": True,
            },
        ]
        result, trace = build_hua_gai(
            lines,
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )

        self.assertEqual(result["aliases"], ["华盖", "華蓋"])
        self.assertEqual(result["basis"]["type"], "day_branch")
        self.assertEqual(result["target_branches"], ["未"])
        self.assertEqual(result["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in result["matches"]],
            ["base-1", "base-6"],
        )
        self.assertEqual(
            trace["source_ids"],
            ["SRC-011", "SRC-012", "SRC-015"],
        )
        self.assertIn("上爻丁未：爻支未 = 华盖支未 → 命中", trace["steps"])
        self.assertIn("v1 包含本卦动爻", trace["steps"][-1])

    def test_calculated_no_match_does_not_treat_hidden_line_as_visible(self) -> None:
        result, trace = build_hua_gai(
            [
                {
                    "id": "base-2",
                    "position": 2,
                    "position_name": "二爻",
                    "gan_zhi": "甲寅",
                    "earthly_branch": "寅",
                    "relation": "官鬼",
                    "hidden": {"earthly_branch": "未"},
                }
            ],
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(result["status"], "computed_no_match")
        self.assertEqual(result["matches"], [])
        self.assertEqual(result["excluded_scopes"], ["hidden", "changed"])
        self.assertIn("结果为已计算未命中", trace["steps"][-2])
        self.assertIn("农历月序华盖", trace["steps"][-1])

    def test_invalid_day_branch_fails_loudly(self) -> None:
        with self.assertRaisesRegex(ValueError, "invalid day branch for hua gai"):
            build_hua_gai([], {"gan_zhi": "辛亥", "stem": "辛", "branch": ""})


if __name__ == "__main__":
    unittest.main()
