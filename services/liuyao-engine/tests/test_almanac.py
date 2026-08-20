import unittest

from app.almanac import calculate_almanac


class AlmanacTest(unittest.TestCase):
    def test_reference_screenshot_datetime_is_stable(self) -> None:
        result = calculate_almanac(
            "2026-08-05T15:25:00+08:00",
            timezone_name="Asia/Shanghai",
        )

        self.assertEqual(result["provider"]["name"], "cnlunar")
        self.assertEqual(result["provider"]["version"], "0.2.0")
        self.assertEqual(result["solar"], {"date": "2026-08-05", "weekday": "星期三"})
        self.assertEqual(
            (
                result["lunar"]["year"],
                result["lunar"]["month"],
                result["lunar"]["day"],
            ),
            (2026, 6, 23),
        )
        self.assertEqual(
            [pillar["ganzhi"] for pillar in result["four_pillars"]],
            ["丙午", "乙未", "辛亥", "丙申"],
        )
        self.assertEqual(
            [pillar["nayin"] for pillar in result["four_pillars"]],
            ["天河水", "砂中金", "钗钏金", "山下火"],
        )
        self.assertEqual(result["current_two_hour_index"], 8)
        self.assertEqual(result["two_hour_pillars"][8]["ganzhi"], "丙申")
        self.assertTrue(result["two_hour_pillars"][8]["selected"])
        self.assertEqual(result["wealth_god"]["direction"], "正东")
        self.assertEqual(result["solar_terms"]["next"], {"name": "立秋", "date": "2026-08-07"})

    def test_iana_timezone_converts_the_instant_before_calendar_calculation(self) -> None:
        local = calculate_almanac(
            "2026-08-05T15:25:00+08:00",
            timezone_name="Asia/Shanghai",
        )
        utc = calculate_almanac(
            "2026-08-05T07:25:00Z",
            timezone_name="Asia/Shanghai",
        )

        self.assertEqual(local["lunar"], utc["lunar"])
        self.assertEqual(local["four_pillars"], utc["four_pillars"])
        self.assertEqual(utc["input"]["local_datetime"], "2026-08-05T15:25:00+08:00")

    def test_safe_supported_date_boundaries_are_explicit(self) -> None:
        first = calculate_almanac("1901-02-19T12:00:00+08:00")
        last = calculate_almanac("2100-02-08T12:00:00+08:00")

        self.assertEqual(first["solar"]["date"], "1901-02-19")
        self.assertEqual(last["solar"]["date"], "2100-02-08")
        self.assertEqual(first["provider"]["supported_local_dates"]["start"], "1901-02-19")
        self.assertEqual(last["provider"]["supported_local_dates"]["end"], "2100-02-08")

        for timestamp in ("1901-02-18T12:00:00+08:00", "2100-02-09T12:00:00+08:00"):
            with self.subTest(timestamp=timestamp):
                with self.assertRaisesRegex(ValueError, "supports local dates"):
                    calculate_almanac(timestamp)

    def test_timestamp_must_be_aware_and_timezone_must_exist(self) -> None:
        with self.assertRaisesRegex(ValueError, "explicit UTC offset"):
            calculate_almanac("2026-08-05T15:25:00")
        with self.assertRaisesRegex(ValueError, "unknown IANA timezone"):
            calculate_almanac(
                "2026-08-05T15:25:00+08:00",
                timezone_name="Not/A_Timezone",
            )


if __name__ == "__main__":
    unittest.main()
