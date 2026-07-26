import unittest

from app.engine import cast_chart


class EngineTest(unittest.TestCase):
    def test_seeded_cast_is_stable_and_keeps_bottom_to_top_lines(self) -> None:
        first = cast_chart("2026-07-26T15:30:00+08:00", seed="golden")
        second = cast_chart("2026-07-26T15:30:00+08:00", seed="golden")

        self.assertEqual(first, second)
        self.assertEqual(first["meta"]["line_order"], "bottom_to_top")
        self.assertEqual(len(first["hexagram"]["base"]["lines"]), 6)

    def test_manual_cast_preserves_line_values_and_changed_yin_yang(self) -> None:
        chart = cast_chart(
            "2026-07-26T15:30:00+08:00",
            line_values=[8, 9, 8, 6, 9, 8],
            casting_method="manual",
        )

        self.assertEqual(chart["meta"]["line_values"], [8, 9, 8, 6, 9, 8])
        self.assertIsNotNone(chart["hexagram"]["changed"])
        self.assertEqual(
            [line["yin_yang"] for line in chart["hexagram"]["changed"]["lines"]],
            ["yin", "yin", "yin", "yang", "yin", "yin"],
        )


if __name__ == "__main__":
    unittest.main()
