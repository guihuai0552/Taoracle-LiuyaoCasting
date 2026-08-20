import unittest

from najia.const import GUA64

from app.engine import cast_chart
from app.twenty_eight_mansions import (
    MANSIONS,
    PALACE_ORDER,
    PLACEMENT_POSITIONS,
    build_twenty_eight_mansions,
    rule_package,
)


def _synthetic_base(
    palace_name: str,
    palace_sequence: int,
    shi_position: int,
    *,
    name: str = "测试卦",
) -> dict:
    ying_position = shi_position - 3 if shi_position > 3 else shi_position + 3
    return {
        "code": "000000",
        "name": name,
        "palace_name": palace_name,
        "palace_sequence": palace_sequence,
        "shi_position": shi_position,
        "ying_position": ying_position,
        "lines": [
            {"id": f"base-{position}", "position": position, "position_name": name}
            for position, name in enumerate(
                ["初爻", "二爻", "三爻", "四爻", "五爻", "上爻"],
                start=1,
            )
        ],
    }


def _line_values_for_name(name: str) -> list[int]:
    code = next(code for code, item in GUA64.items() if item == name)
    return [7 if bit == "1" else 8 for bit in code]


class TwentyEightMansionsTest(unittest.TestCase):
    def test_confirmed_rule_package_is_versioned(self) -> None:
        self.assertEqual(
            rule_package(),
            {
                "id": "liuyao.mansions.jingfang_world_line.v1",
                "version": "1.0.0",
                "status": "confirmed_user_rule",
                "source_ids": ["SRC-006"],
                "system": "jingfang_64_hexagrams_world_line",
            },
        )

    def test_all_64_world_mansions_follow_confirmed_palace_order(self) -> None:
        expected_by_palace = {
            "乾": ["参", "井", "鬼", "柳", "星", "张", "翼", "轸"],
            "震": ["角", "亢", "氐", "房", "心", "尾", "箕", "斗"],
            "坎": ["牛", "女", "虚", "危", "室", "壁", "奎", "娄"],
            "艮": ["胃", "昴", "毕", "觜", "参", "井", "鬼", "柳"],
            "坤": ["星", "张", "翼", "轸", "角", "亢", "氐", "房"],
            "巽": ["心", "尾", "箕", "斗", "牛", "女", "虚", "危"],
            "离": ["室", "壁", "奎", "娄", "胃", "昴", "毕", "觜"],
            "兑": ["参", "井", "鬼", "柳", "星", "张", "翼", "轸"],
        }
        self.assertEqual(tuple(expected_by_palace), PALACE_ORDER)
        for palace_index, palace_name in enumerate(PALACE_ORDER):
            for sequence in range(1, 9):
                with self.subTest(palace=palace_name, sequence=sequence):
                    shi_position = (6, 1, 2, 3, 4, 5, 4, 3)[sequence - 1]
                    result, _ = build_twenty_eight_mansions(
                        _synthetic_base(palace_name, sequence, shi_position)
                    )
                    self.assertEqual(
                        result["hexagram"]["global_index"],
                        palace_index * 8 + sequence - 1,
                    )
                    self.assertEqual(
                        result["world_line"]["mansion"],
                        expected_by_palace[palace_name][sequence - 1],
                    )

    def test_all_six_world_line_positions_have_fixed_placement_order(self) -> None:
        for shi_position, expected_positions in PLACEMENT_POSITIONS.items():
            with self.subTest(shi_position=shi_position):
                result, _ = build_twenty_eight_mansions(
                    _synthetic_base("乾", 1, shi_position)
                )
                self.assertEqual(
                    result["placement_position_order"], list(expected_positions)
                )
                self.assertEqual(
                    [item["placement_role"] for item in result["line_placements"]],
                    ["世", "应", "世卦", "应卦", "世卦", "应卦"],
                )

    def test_qian_places_can_through_zhang_on_all_six_lines(self) -> None:
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=[7, 7, 7, 7, 7, 7],
            casting_method="manual",
        )
        result = chart["annotations"]["twenty_eight_mansions"]
        self.assertEqual(result["world_line"]["mansion"], "参")
        self.assertEqual(result["placement_position_order"], [6, 3, 5, 1, 4, 2])
        self.assertEqual(
            [(item["position"], item["mansion"]) for item in result["line_placements"]],
            [(6, "参"), (3, "井"), (5, "鬼"), (1, "柳"), (4, "星"), (2, "张")],
        )

    def test_shuileitun_matches_the_confirmed_world_xu_example(self) -> None:
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=_line_values_for_name("水雷屯"),
            casting_method="manual",
        )
        result = chart["annotations"]["twenty_eight_mansions"]
        self.assertEqual(result["world_line"], {
            "position": 2,
            "position_name": "二爻",
            "mansion_index": MANSIONS.index("虚"),
            "mansion": "虚",
        })
        self.assertEqual(
            [(item["position"], item["mansion"]) for item in result["line_placements"]],
            [(2, "虚"), (5, "危"), (1, "室"), (6, "壁"), (3, "奎"), (4, "娄")],
        )

    def test_three_confirmed_corrections_are_frozen(self) -> None:
        dun = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=_line_values_for_name("天山遁"),
            casting_method="manual",
        )
        li = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=_line_values_for_name("离为火"),
            casting_method="manual",
        )
        qian = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=_line_values_for_name("乾为天"),
            casting_method="manual",
        )
        self.assertEqual(dun["hexagram"]["base"]["name"], "天山遁")
        self.assertEqual(
            dun["annotations"]["twenty_eight_mansions"]["world_line"]["mansion"],
            "鬼",
        )
        self.assertEqual(
            li["annotations"]["twenty_eight_mansions"]["world_line"]["mansion"],
            "室",
        )
        qian_by_position = {
            item["position"]: item["mansion"]
            for item in qian["annotations"]["twenty_eight_mansions"]["line_placements"]
        }
        self.assertEqual(qian_by_position[2], "张")

    def test_zheng_to_jiao_wrap_is_explicit_in_trace(self) -> None:
        result, trace = build_twenty_eight_mansions(
            _synthetic_base("乾", 8, 3, name="火天大有")
        )
        self.assertEqual(
            [item["mansion"] for item in result["line_placements"]],
            ["轸", "角", "亢", "氐", "房", "心"],
        )
        self.assertEqual(trace["source_ids"], ["SRC-006"])
        self.assertEqual(len(trace["steps"]), 10)


if __name__ == "__main__":
    unittest.main()
