import unittest

from app.engine import cast_chart


class EngineTest(unittest.TestCase):
    def test_seeded_cast_is_stable_and_keeps_bottom_to_top_lines(self) -> None:
        first = cast_chart("2026-07-26T15:30:00+08:00", seed="golden")
        second = cast_chart("2026-07-26T15:30:00+08:00", seed="golden")

        self.assertEqual(first, second)
        self.assertEqual(first["schema_version"], 13)
        self.assertEqual(first["meta"]["line_order"], "bottom_to_top")
        self.assertEqual(len(first["hexagram"]["base"]["lines"]), 6)
        self.assertEqual(
            [line["coins"] for line in first["casting_record"]["lines"]],
            [
                [2, 3, 3],
                [2, 3, 2],
                [2, 2, 2],
                [3, 3, 2],
                [3, 2, 3],
                [3, 2, 2],
            ],
        )
        self.assertEqual(first["casting_record"]["line_values"], [8, 7, 6, 8, 8, 7])
        self.assertEqual(
            first["casting_record"]["random_source"],
            {"kind": "seeded_test", "generator": "python.Random", "seed": "golden"},
        )
        self.assertEqual(
            first["calculation_trace"][0]["steps"][0],
            "初爻：2 + 3 + 3 = 8 → 少阴",
        )

    def test_manual_cast_preserves_line_values_and_changed_yin_yang(self) -> None:
        chart = cast_chart(
            "2026-07-26T15:30:00+08:00",
            line_values=[8, 9, 8, 6, 9, 8],
            casting_method="manual",
        )

        self.assertEqual(chart["meta"]["line_values"], [8, 9, 8, 6, 9, 8])
        self.assertIsNone(chart["casting_record"]["random_source"])
        self.assertEqual(
            [line["coins"] for line in chart["casting_record"]["lines"]],
            [[], [], [], [], [], []],
        )
        self.assertIsNotNone(chart["hexagram"]["changed"])
        self.assertEqual(
            [line["yin_yang"] for line in chart["hexagram"]["changed"]["lines"]],
            ["yin", "yin", "yin", "yang", "yin", "yin"],
        )

    def test_manual_ui_top_down_edits_keep_bottom_to_top_contract(self) -> None:
        chart = cast_chart(
            "2026-08-05T15:26:00+08:00",
            line_values=[9, 7, 7, 7, 7, 6],
            casting_method="manual",
        )

        self.assertEqual(chart["meta"]["line_order"], "bottom_to_top")
        self.assertEqual(chart["meta"]["line_values"], [9, 7, 7, 7, 7, 6])
        self.assertEqual(chart["hexagram"]["base"]["name"], "泽天夬")
        self.assertEqual(chart["hexagram"]["changed"]["name"], "天风姤")
        self.assertEqual(
            [line["changing"] for line in chart["hexagram"]["base"]["lines"]],
            [True, False, False, False, False, True],
        )

    def test_casting_methods_reject_conflicting_inputs(self) -> None:
        with self.assertRaisesRegex(ValueError, "does not accept line_values"):
            cast_chart(
                "2026-08-05T15:26:00+08:00",
                line_values=[7, 7, 7, 7, 7, 7],
                casting_method="three_coins",
            )
        with self.assertRaisesRegex(ValueError, "requires line_values"):
            cast_chart(
                "2026-08-05T15:26:00+08:00",
                casting_method="manual",
            )
        with self.assertRaisesRegex(ValueError, "does not accept seed"):
            cast_chart(
                "2026-08-05T15:26:00+08:00",
                line_values=[7, 7, 7, 7, 7, 7],
                seed="invalid",
                casting_method="manual",
            )


if __name__ == "__main__":
    unittest.main()
