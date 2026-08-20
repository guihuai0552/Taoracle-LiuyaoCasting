import unittest

from najia.const import GUA64

from app.base_chart import OPPOSITE_TRIGRAMS, SIX_GOD_START, day_void
from app.engine import cast_chart


class BaseChartTest(unittest.TestCase):
    def test_fixed_multi_moving_chart_has_split_fields_hidden_and_trace(self) -> None:
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=[9, 7, 7, 7, 7, 6],
            casting_method="manual",
        )

        self.assertEqual(chart["schema_version"], 13)
        self.assertEqual(chart["engine_version"], "0.13.0+najia-2.0.1")
        self.assertEqual(chart["rule_package"]["version"], "1.3.0")
        self.assertIn("SRC-019", chart["rule_package"]["source_ids"])
        self.assertEqual(
            chart["rule_package"]["upstream"]["audited_commit"],
            "c67a5398632a80f368a17a884c1c71b203aab719",
        )
        self.assertEqual(
            chart["time"]["pillars"]["day"],
            {"gan_zhi": "辛亥", "stem": "辛", "branch": "亥"},
        )
        self.assertEqual(chart["time"]["day_void_branches"], ["寅", "卯"])
        self.assertEqual(
            {key: item["void"] for key, item in chart["time"]["pillar_voids"].items()},
            {"year": "寅卯", "month": "辰巳", "day": "寅卯", "hour": "辰巳"},
        )

        base = chart["hexagram"]["base"]
        self.assertEqual(base["code"], "111110")
        self.assertEqual(base["name"], "泽天夬")
        self.assertEqual(base["lower_trigram"]["name"], "乾")
        self.assertEqual(base["upper_trigram"]["name"], "兑")
        self.assertEqual(base["palace"], {"code": "000", "name": "坤", "element": "土"})
        self.assertEqual((base["shi_position"], base["ying_position"]), (5, 2))
        self.assertEqual(base["moving_positions"], [1, 6])

        first = base["lines"][0]
        self.assertEqual(first["id"], "base-1")
        self.assertEqual(first["heavenly_stem"], "甲")
        self.assertEqual(first["earthly_branch"], "子")
        self.assertEqual(first["branch"], "子")
        self.assertEqual(first["gan_zhi"], "甲子")
        self.assertEqual(first["element"], "水")
        self.assertEqual(first["relation"], "妻财")
        self.assertEqual(first["six_god"], "白虎")

        self.assertEqual(
            [line["hidden"]["gan_zhi"] for line in base["lines"]],
            ["乙未", "乙巳", "乙卯", "癸丑", "癸亥", "癸酉"],
        )
        self.assertEqual(
            [line["hidden"]["relation"] for line in base["lines"]],
            ["兄弟", "父母", "官鬼", "兄弟", "妻财", "子孙"],
        )

        hidden = base["lines"][1]["hidden"]
        self.assertEqual(hidden["id"], "hidden-2-父母")
        self.assertEqual(hidden["gan_zhi"], "乙巳")
        self.assertEqual(hidden["earthly_branch"], "巳")
        self.assertEqual(hidden["source_hexagram"]["name"], "坤为地")
        self.assertEqual(hidden["flying_line_id"], "base-2")

        changed = chart["hexagram"]["changed"]
        self.assertEqual(changed["code"], "011111")
        self.assertEqual(changed["name"], "天风姤")
        self.assertEqual(changed["palace_sequence"], 2)
        self.assertEqual(changed["hexagram_kind"], "regular")
        self.assertEqual(changed["relative_basis"], "base_palace")
        self.assertEqual(changed["relative_basis_element"], "土")
        self.assertEqual(changed["lines"][0]["relation"], "兄弟")
        self.assertTrue(changed["lines"][0]["changed_from_base"])
        self.assertFalse(changed["lines"][1]["changed_from_base"])

        self.assertEqual(
            [trace["rule_id"] for trace in chart["calculation_trace"]],
            [
                "casting.manual.normalize.v1",
                "chart.time_context.cnlunar.v1",
                "chart.hexagram.identify.v1",
                "chart.trigrams.split.v1",
                "chart.palace.shi_ying.v1",
                "chart.najia.table.v1",
                "chart.six_relatives.five_elements.v1",
                "chart.six_gods.day_stem.v1",
                "chart.hidden_hexagram.trigram_match.v3",
                "chart.changed.relatives.v1",
                "annotation.wuxing_twelve_stages.forward.v1",
                "shensha.lushen.day_stem.v1",
                "shensha.tianyi.day_stem.v1",
                "shensha.yima.day_branch.v1",
                "shensha.taohua.day_branch.v1",
                "shensha.jiangxing.day_branch.v1",
                "shensha.huagai.day_branch.v1",
                "mansion.jingfang.world_line_and_six_lines.v1",
            ],
        )

        twelve_stages = chart["annotations"]["five_element_twelve_stages"]
        self.assertEqual(twelve_stages["scope"], "base_lines")
        self.assertEqual(twelve_stages["start_branches"]["土"], "申")
        self.assertEqual(
            [
                item["stage"]
                for item in twelve_stages["line_results"][0]["pillar_results"]
            ],
            ["胎", "养", "临官", "长生"],
        )
        lu_shen = chart["annotations"]["shensha"]["results"][0]
        self.assertEqual(lu_shen["display_name"], "禄神")
        self.assertEqual(lu_shen["basis"]["value"], "辛")
        self.assertEqual(lu_shen["target_branches"], ["酉"])
        self.assertEqual(lu_shen["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in lu_shen["matches"]],
            ["base-5"],
        )
        tian_yi = chart["annotations"]["shensha"]["results"][1]
        self.assertEqual(tian_yi["display_name"], "天乙")
        self.assertEqual(tian_yi["target_branches"], ["午", "寅"])
        self.assertEqual(tian_yi["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in tian_yi["matches"]],
            ["base-2"],
        )
        yi_ma = chart["annotations"]["shensha"]["results"][2]
        self.assertEqual(yi_ma["display_name"], "驿马")
        self.assertEqual(yi_ma["basis"]["type"], "day_branch")
        self.assertEqual(yi_ma["basis"]["value"], "亥")
        self.assertEqual(yi_ma["target_branches"], ["巳"])
        self.assertEqual(yi_ma["status"], "computed_no_match")
        self.assertEqual(yi_ma["matches"], [])
        self.assertEqual(yi_ma["excluded_scopes"], ["hidden", "changed"])
        tao_hua = chart["annotations"]["shensha"]["results"][3]
        self.assertEqual(tao_hua["display_name"], "桃花")
        self.assertEqual(tao_hua["canonical_name"], "咸池")
        self.assertEqual(tao_hua["basis"]["type"], "day_branch")
        self.assertEqual(tao_hua["basis"]["value"], "亥")
        self.assertEqual(tao_hua["target_branches"], ["子"])
        self.assertEqual(tao_hua["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in tao_hua["matches"]],
            ["base-1"],
        )
        self.assertEqual(tao_hua["excluded_scopes"], ["hidden", "changed"])
        jiang_xing = chart["annotations"]["shensha"]["results"][4]
        self.assertEqual(jiang_xing["display_name"], "将星")
        self.assertEqual(jiang_xing["basis"]["type"], "day_branch")
        self.assertEqual(jiang_xing["basis"]["value"], "亥")
        self.assertEqual(jiang_xing["target_branches"], ["卯"])
        self.assertEqual(jiang_xing["status"], "computed_no_match")
        self.assertEqual(jiang_xing["matches"], [])
        self.assertEqual(jiang_xing["excluded_scopes"], ["hidden", "changed"])
        hua_gai = chart["annotations"]["shensha"]["results"][5]
        self.assertEqual(hua_gai["display_name"], "华盖")
        self.assertEqual(hua_gai["basis"]["type"], "day_branch")
        self.assertEqual(hua_gai["basis"]["value"], "亥")
        self.assertEqual(hua_gai["target_branches"], ["未"])
        self.assertEqual(hua_gai["status"], "computed_match")
        self.assertEqual(
            [item["line_id"] for item in hua_gai["matches"]],
            ["base-6"],
        )
        self.assertTrue(base["lines"][5]["changing"])
        self.assertEqual(hua_gai["excluded_scopes"], ["hidden", "changed"])
        mansions = chart["annotations"]["twenty_eight_mansions"]
        self.assertEqual(mansions["world_line"]["mansion"], "亢")
        self.assertEqual(len(mansions["line_placements"]), 6)
        self.assertTrue(chart["diagnostics"]["structural_match"])

    def test_dachu_to_sun_exposes_both_palaces_and_sequences(self) -> None:
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=[7, 7, 9, 8, 8, 7],
            casting_method="manual",
        )

        base = chart["hexagram"]["base"]
        changed = chart["hexagram"]["changed"]
        self.assertEqual(
            (base["name"], base["palace_name"], base["palace_sequence"]),
            ("山天大畜", "艮", 3),
        )
        self.assertEqual(
            (
                changed["name"],
                changed["palace_name"],
                changed["palace_sequence"],
            ),
            ("山泽损", "艮", 4),
        )
        self.assertTrue(base["lines"][2]["changing"])
        self.assertTrue(changed["lines"][2]["changed_from_base"])
        self.assertEqual(
            [line["hidden"]["gan_zhi"] for line in base["lines"]],
            ["丙辰", "丙午", "丙申", "丁亥", "丁酉", "丁未"],
        )
        self.assertEqual(base["hidden_hexagram"]["name"], "泽山咸")
        self.assertEqual(base["hidden_hexagram"]["code"], "001110")
        self.assertFalse(
            base["hidden_hexagram"]["inner_rule"]["matches_palace_trigram"]
        )
        self.assertTrue(
            base["hidden_hexagram"]["outer_rule"]["matches_palace_trigram"]
        )
        self.assertTrue(all(line["hidden"] is not None for line in base["lines"]))

    def test_wuwang_uses_xun_for_both_hidden_trigrams(self) -> None:
        code = next(code for code, name in GUA64.items() if name == "天雷无妄")
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=[7 if bit == "1" else 8 for bit in code],
            casting_method="manual",
        )

        base = chart["hexagram"]["base"]
        self.assertEqual(base["palace_name"], "巽")
        self.assertEqual(base["hidden_hexagram"]["name"], "巽为风")
        self.assertEqual(base["hidden_hexagram"]["code"], "011011")
        self.assertFalse(
            base["hidden_hexagram"]["inner_rule"]["matches_palace_trigram"]
        )
        self.assertFalse(
            base["hidden_hexagram"]["outer_rule"]["matches_palace_trigram"]
        )

    def test_four_pillars_each_expose_their_own_void_branches(self) -> None:
        chart = cast_chart(
            "2026-08-04T22:22:29+08:00",
            line_values=[7, 7, 7, 7, 7, 7],
            casting_method="manual",
        )

        self.assertEqual(
            [chart["time"][key] for key in ("year", "month", "day", "hour")],
            ["丙午", "乙未", "庚戌", "丁亥"],
        )
        self.assertEqual(
            [
                chart["time"]["pillar_voids"][key]["void"]
                for key in ("year", "month", "day", "hour")
            ],
            ["寅卯", "辰巳", "寅卯", "午未"],
        )

    def test_jiang_xing_day_branch_rule_isolated_from_lunar_month_rule(self) -> None:
        chart = cast_chart(
            "2026-08-06T15:26:00+08:00",
            line_values=[8, 8, 8, 8, 8, 7],
            casting_method="manual",
        )

        self.assertEqual(chart["time"]["day"], "壬子")
        self.assertEqual(chart["hexagram"]["base"]["name"], "山地剥")
        self.assertEqual(
            [line["earthly_branch"] for line in chart["hexagram"]["base"]["lines"]],
            ["未", "巳", "卯", "戌", "子", "寅"],
        )
        jiang_xing = chart["annotations"]["shensha"]["results"][4]
        self.assertEqual(jiang_xing["basis"]["value"], "子")
        self.assertEqual(jiang_xing["target_branches"], ["子"])
        self.assertEqual(
            [item["line_id"] for item in jiang_xing["matches"]],
            ["base-5"],
        )
        self.assertNotIn("base-3", [item["line_id"] for item in jiang_xing["matches"]])

    def test_hua_gai_day_branch_rule_isolated_from_lunar_month_rule(self) -> None:
        chart = cast_chart(
            "2026-08-06T15:26:00+08:00",
            line_values=[7, 7, 7, 7, 8, 7],
            casting_method="manual",
        )

        self.assertEqual(chart["time"]["day"], "壬子")
        self.assertEqual(chart["hexagram"]["base"]["name"], "火天大有")
        self.assertEqual(
            [line["earthly_branch"] for line in chart["hexagram"]["base"]["lines"]],
            ["子", "寅", "辰", "酉", "未", "巳"],
        )
        hua_gai = chart["annotations"]["shensha"]["results"][5]
        self.assertEqual(hua_gai["basis"]["value"], "子")
        self.assertEqual(hua_gai["target_branches"], ["辰"])
        self.assertEqual(
            [item["line_id"] for item in hua_gai["matches"]],
            ["base-3"],
        )
        self.assertNotIn("base-5", [item["line_id"] for item in hua_gai["matches"]])

    def test_pure_qian_uses_kun_as_both_hidden_trigrams(self) -> None:
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=[7, 7, 7, 7, 7, 7],
            casting_method="manual",
        )
        base = chart["hexagram"]["base"]
        self.assertEqual(base["name"], "乾为天")
        self.assertEqual(base["hexagram_kind"], "pure")
        self.assertEqual((base["shi_position"], base["ying_position"]), (6, 3))
        self.assertIsNone(chart["hexagram"]["changed"])
        self.assertTrue(all(line["hidden"] is not None for line in base["lines"]))
        self.assertEqual(base["hidden_hexagram"]["name"], "坤为地")
        self.assertEqual(
            [line["hidden"]["gan_zhi"] for line in base["lines"]],
            ["乙未", "乙巳", "乙卯", "癸丑", "癸亥", "癸酉"],
        )
        hidden_trace = next(
            item
            for item in chart["calculation_trace"]
            if item["rule_id"] == "chart.hidden_hexagram.trigram_match.v3"
        )
        self.assertEqual(
            hidden_trace["inputs"]["display_mode"],
            "full_hidden_hexagram_six_lines",
        )
        self.assertEqual(hidden_trace["source_ids"], ["SRC-009", "SRC-019"])
        self.assertEqual(len(hidden_trace["steps"]), 9)

    def test_user_supplied_eight_palace_order_is_frozen(self) -> None:
        palace_hexagrams = {
            "乾": ["乾为天", "天风姤", "天山遁", "天地否", "风地观", "山地剥", "火地晋", "火天大有"],
            "坎": ["坎为水", "水泽节", "水雷屯", "水火既济", "泽火革", "雷火丰", "地火明夷", "地水师"],
            "艮": ["艮为山", "山火贲", "山天大畜", "山泽损", "火泽睽", "天泽履", "风泽中孚", "风山渐"],
            "震": ["震为雷", "雷地豫", "雷水解", "雷风恒", "地风升", "水风井", "泽风大过", "泽雷随"],
            "巽": ["巽为风", "风天小畜", "风火家人", "风雷益", "天雷无妄", "火雷噬嗑", "山雷颐", "山风蛊"],
            "离": ["离为火", "火山旅", "火风鼎", "火水未济", "山水蒙", "风水涣", "天水讼", "天火同人"],
            "坤": ["坤为地", "地雷复", "地泽临", "地天泰", "雷天大壮", "泽天夬", "水天需", "水地比"],
            "兑": ["兑为泽", "泽水困", "泽地萃", "泽山咸", "水山蹇", "地山谦", "雷山小过", "雷泽归妹"],
        }
        code_by_name = {name: code for code, name in GUA64.items()}

        for palace_name, names in palace_hexagrams.items():
            for sequence, name in enumerate(names, start=1):
                with self.subTest(palace=palace_name, sequence=sequence, name=name):
                    code = code_by_name[name]
                    chart = cast_chart(
                        "2026-08-05T15:26:00+08:00",
                        line_values=[7 if bit == "1" else 8 for bit in code],
                        casting_method="manual",
                    )
                    base = chart["hexagram"]["base"]
                    self.assertEqual(base["palace_name"], palace_name)
                    self.assertEqual(base["palace_sequence"], sequence)
                    palace_code = base["palace"]["code"]
                    hidden = base["hidden_hexagram"]
                    self.assertEqual(
                        hidden["lower_trigram"]["code"],
                        OPPOSITE_TRIGRAMS[palace_code]
                        if code[:3] == palace_code
                        else palace_code,
                    )
                    self.assertEqual(
                        hidden["upper_trigram"]["code"],
                        OPPOSITE_TRIGRAMS[palace_code]
                        if code[3:] == palace_code
                        else palace_code,
                    )

    def test_project_time_context_wins_at_known_provider_boundary(self) -> None:
        chart = cast_chart(
            "2026-02-04T23:30:00+08:00",
            line_values=[7, 7, 7, 7, 7, 7],
            casting_method="manual",
        )
        self.assertEqual(chart["time"]["day"], "庚戌")
        self.assertEqual(chart["time"]["pillars"]["day"]["stem"], "庚")
        self.assertEqual(chart["hexagram"]["base"]["lines"][0]["six_god"], "白虎")
        self.assertFalse(chart["diagnostics"]["provider_time_match"])
        self.assertTrue(chart["diagnostics"]["structural_match"])

    def test_all_64_hexagrams_have_stable_ids_roles_and_atomic_najia_fields(self) -> None:
        for code, name in GUA64.items():
            with self.subTest(code=code, name=name):
                values = [7 if bit == "1" else 8 for bit in code]
                chart = cast_chart(
                    "2026-08-05T15:26:00+08:00",
                    line_values=values,
                    casting_method="manual",
                )
                base = chart["hexagram"]["base"]
                self.assertEqual(base["code"], code)
                self.assertEqual(base["name"], name)
                self.assertEqual(len(base["lines"]), 6)
                self.assertEqual([line["id"] for line in base["lines"]], [f"base-{i}" for i in range(1, 7)])
                self.assertEqual(sum(line["role"] == "世" for line in base["lines"]), 1)
                self.assertEqual(sum(line["role"] == "应" for line in base["lines"]), 1)
                for line in base["lines"]:
                    self.assertEqual(len(line["heavenly_stem"]), 1)
                    self.assertEqual(len(line["earthly_branch"]), 1)
                    self.assertEqual(line["branch"], line["earthly_branch"])
                    self.assertEqual(len(line["gan_zhi"]), 2)
                    self.assertEqual(len(line["element"]), 1)
                    self.assertIsNotNone(line["hidden"])
                    self.assertEqual(line["hidden"]["position"], line["position"])
                    self.assertEqual(
                        line["hidden"]["flying_line_id"],
                        line["id"],
                    )
                self.assertTrue(chart["diagnostics"]["structural_match"])

    def test_six_god_starts_and_day_void_table_are_explicit(self) -> None:
        self.assertEqual(
            SIX_GOD_START,
            {
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
            },
        )
        self.assertEqual(day_void("甲子"), ("戌亥", ["戌", "亥"]))
        self.assertEqual(day_void("辛亥"), ("寅卯", ["寅", "卯"]))


if __name__ == "__main__":
    unittest.main()
