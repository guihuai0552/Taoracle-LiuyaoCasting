import unittest

from fastapi.testclient import TestClient

from app.main import app


class AlmanacApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)

    def test_almanac_endpoint_returns_the_versioned_contract(self) -> None:
        response = self.client.post(
            "/v1/almanac",
            json={
                "timestamp": "2026-08-05T07:25:00Z",
                "timezone": "Asia/Shanghai",
                "year_boundary": "lunar_new_year",
            },
        )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["schema_version"], 1)
        self.assertEqual(body["input"]["local_datetime"], "2026-08-05T15:25:00+08:00")
        self.assertEqual(body["four_pillars"][2]["ganzhi"], "辛亥")
        self.assertEqual(body["wealth_god"]["direction"], "正东")

    def test_almanac_endpoint_reports_contract_errors_as_422(self) -> None:
        response = self.client.post(
            "/v1/almanac",
            json={"timestamp": "2100-02-09T12:00:00+08:00"},
        )

        self.assertEqual(response.status_code, 422)
        self.assertIn("supports local dates", response.json()["detail"])

    def test_health_advertises_the_almanac_contract(self) -> None:
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["almanac_adapter_version"], "0.1.0")
        self.assertEqual(response.json()["almanac_schema_version"], 1)

    def test_month_endpoint_returns_42_calendar_cells(self) -> None:
        response = self.client.post(
            "/v1/almanac/month",
            json={"year": 2026, "month": 8, "timezone": "Asia/Shanghai"},
        )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["grid"]["start"], "2026-07-27")
        self.assertEqual(body["grid"]["end"], "2026-09-06")
        self.assertEqual(len(body["cells"]), 42)

    def test_month_endpoint_rejects_invalid_month(self) -> None:
        response = self.client.post(
            "/v1/almanac/month",
            json={"year": 2026, "month": 13},
        )

        self.assertEqual(response.status_code, 422)


if __name__ == "__main__":
    unittest.main()
