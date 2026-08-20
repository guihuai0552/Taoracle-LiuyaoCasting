import unittest

from app.almanac import calculate_month_calendar


class AlmanacMonthTest(unittest.TestCase):
    def test_august_2026_returns_a_fixed_six_week_grid(self) -> None:
        result = calculate_month_calendar(2026, 8)

        self.assertEqual(result["grid"]["week_starts_on"], "monday")
        self.assertEqual(result["grid"]["start"], "2026-07-27")
        self.assertEqual(result["grid"]["end"], "2026-09-06")
        self.assertEqual(len(result["cells"]), 42)

        august_fifth = next(cell for cell in result["cells"] if cell["date"] == "2026-08-05")
        self.assertTrue(august_fifth["in_current_month"])
        self.assertEqual(august_fifth["lunar"]["day_cn"], "廿三")
        self.assertEqual(august_fifth["day_pillar"]["ganzhi"], "辛亥")

        beginning_of_autumn = next(
            cell for cell in result["cells"] if cell["date"] == "2026-08-07"
        )
        self.assertEqual(beginning_of_autumn["solar_term"], "立秋")

    def test_boundary_months_keep_unavailable_adjacent_cells(self) -> None:
        first_month = calculate_month_calendar(1901, 2)
        self.assertFalse(
            next(cell for cell in first_month["cells"] if cell["date"] == "1901-02-18")[
                "available"
            ]
        )
        self.assertTrue(
            next(cell for cell in first_month["cells"] if cell["date"] == "1901-02-19")[
                "available"
            ]
        )

        last_month = calculate_month_calendar(2100, 2)
        self.assertTrue(
            next(cell for cell in last_month["cells"] if cell["date"] == "2100-02-08")[
                "available"
            ]
        )
        self.assertFalse(
            next(cell for cell in last_month["cells"] if cell["date"] == "2100-02-09")[
                "available"
            ]
        )

    def test_month_without_any_supported_date_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "does not overlap"):
            calculate_month_calendar(2100, 3)


if __name__ == "__main__":
    unittest.main()
