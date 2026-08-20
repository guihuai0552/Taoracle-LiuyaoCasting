import unittest

from fastapi.testclient import TestClient

from app.main import app


class CastApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)

    def test_seeded_three_coin_cast_returns_auditable_raw_process(self) -> None:
        response = self.client.post(
            "/v1/cast",
            json={
                "timestamp": "2026-07-26T15:30:00+08:00",
                "casting_method": "three_coins",
                "seed": "golden",
            },
        )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["schema_version"], 13)
        self.assertEqual(
            body["rule_package"]["id"],
            "liuyao.base.najia_2_0_1_compat.v1",
        )
        self.assertEqual(body["hexagram"]["line_order"], "bottom_to_top")
        self.assertTrue(body["diagnostics"]["structural_match"])
        self.assertEqual(body["casting_record"]["line_values"], [8, 7, 6, 8, 8, 7])
        self.assertEqual(body["casting_record"]["lines"][0]["coins"], [2, 3, 3])
        self.assertEqual(
            body["casting_record"]["method_version"],
            "three_coins.sum_2_3.v1",
        )

    def test_three_coin_cast_rejects_manual_line_values(self) -> None:
        response = self.client.post(
            "/v1/cast",
            json={
                "timestamp": "2026-07-26T15:30:00+08:00",
                "casting_method": "three_coins",
                "line_values": [7, 7, 7, 7, 7, 7],
            },
        )

        self.assertEqual(response.status_code, 422)
        self.assertIn("does not accept line_values", response.json()["detail"])


if __name__ == "__main__":
    unittest.main()
