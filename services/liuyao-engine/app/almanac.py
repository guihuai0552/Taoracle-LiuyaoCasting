"""Stable almanac contract backed by cnlunar.

The rest of the product must depend on this adapter rather than cnlunar's
Python objects or presentation-oriented strings. This keeps archived cases
reproducible when the upstream library or our display terminology changes.
"""

from __future__ import annotations

from calendar import monthrange
from datetime import date, datetime, time, timedelta
from importlib.metadata import PackageNotFoundError, version
from typing import Any, Literal
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

import arrow
import cnlunar
from cnlunar.config import (
    the60HeavenlyEarth,
    theHalf60HeavenlyEarth5ElementsList,
)

ALMANAC_SCHEMA_VERSION = 1
ALMANAC_ADAPTER_VERSION = "0.1.0"
SUPPORTED_DATE_START = date(1901, 2, 19)
SUPPORTED_DATE_END = date(2100, 2, 8)

YearBoundary = Literal["lunar_new_year", "beginning_of_spring"]


def _provider_version() -> str:
    try:
        return version("cnlunar")
    except PackageNotFoundError:
        return "unknown"


def _split_ganzhi(value: str) -> tuple[str, str]:
    if len(value) != 2:
        raise ValueError(f"invalid ganzhi returned by cnlunar: {value!r}")
    return value[0], value[1]


def _pillar(position: str, ganzhi: str) -> dict[str, str]:
    stem, branch = _split_ganzhi(ganzhi)
    try:
        index = the60HeavenlyEarth.index(ganzhi)
    except ValueError as error:
        raise ValueError(f"unknown ganzhi returned by cnlunar: {ganzhi!r}") from error
    return {
        "position": position,
        "ganzhi": ganzhi,
        "stem": stem,
        "branch": branch,
        "nayin": theHalf60HeavenlyEarth5ElementsList[index // 2],
    }


def _wealth_god_direction(values: list[str]) -> tuple[str, str]:
    for value in values:
        if value.startswith("财神"):
            return value[2:], value
    raise ValueError("cnlunar did not return a 财神 direction")


def _next_solar_term_date(year: int, month_day: tuple[int, int]) -> str:
    month, day = month_day
    return date(year, month, day).isoformat()


def calculate_almanac(
    timestamp_iso: str,
    *,
    timezone_name: str | None = None,
    year_boundary: YearBoundary = "lunar_new_year",
) -> dict[str, Any]:
    """Calculate a versioned almanac snapshot for one instant.

    The input timestamp must carry an explicit UTC offset. If an IANA timezone
    is supplied, the instant is converted to that zone before calendar rules
    are applied. cnlunar receives a naive local wall-clock datetime because it
    does not model timezone semantics itself.
    """

    try:
        parsed_timestamp = datetime.fromisoformat(timestamp_iso.replace("Z", "+00:00"))
    except (TypeError, ValueError) as error:
        raise ValueError("timestamp must be a valid RFC 3339 datetime") from error
    if parsed_timestamp.tzinfo is None or parsed_timestamp.utcoffset() is None:
        raise ValueError("timestamp must include an explicit UTC offset")
    instant = arrow.get(parsed_timestamp)

    timezone_label: str
    if timezone_name:
        try:
            timezone = ZoneInfo(timezone_name)
        except ZoneInfoNotFoundError as error:
            raise ValueError(f"unknown IANA timezone: {timezone_name}") from error
        local_datetime = instant.to(timezone).datetime
        timezone_label = timezone_name
    else:
        local_datetime = instant.datetime
        timezone_label = f"UTC{local_datetime.strftime('%z')[:3]}:{local_datetime.strftime('%z')[3:]}"

    local_date = local_datetime.date()
    if not SUPPORTED_DATE_START <= local_date <= SUPPORTED_DATE_END:
        raise ValueError(
            "cnlunar adapter supports local dates from "
            f"{SUPPORTED_DATE_START.isoformat()} through {SUPPORTED_DATE_END.isoformat()}"
        )

    if year_boundary not in ("lunar_new_year", "beginning_of_spring"):
        raise ValueError("year_boundary must be lunar_new_year or beginning_of_spring")
    upstream_year_boundary = (
        "beginningOfSpring" if year_boundary == "beginning_of_spring" else "year"
    )

    wall_clock = local_datetime.replace(tzinfo=None)
    lunar = cnlunar.Lunar(
        wall_clock,
        godType="8char",
        year8Char=upstream_year_boundary,
    )

    pillar_values = [
        ("year", lunar.year8Char),
        ("month", lunar.month8Char),
        ("day", lunar.day8Char),
        ("hour", lunar.twohour8Char),
    ]
    four_pillars = [_pillar(position, ganzhi) for position, ganzhi in pillar_values]
    two_hour_pillars = [
        {
            "index": index,
            "ganzhi": ganzhi,
            "stem": _split_ganzhi(ganzhi)[0],
            "branch": _split_ganzhi(ganzhi)[1],
            "selected": index == lunar.twohourNum,
        }
        for index, ganzhi in enumerate(lunar.twohour8CharList)
    ]

    lucky_directions = lunar.get_luckyGodsDirection()
    wealth_direction, wealth_raw = _wealth_god_direction(lucky_directions)
    today_solar_term = None if lunar.todaySolarTerms == "无" else lunar.todaySolarTerms

    return {
        "schema_version": ALMANAC_SCHEMA_VERSION,
        "adapter_version": ALMANAC_ADAPTER_VERSION,
        "provider": {
            "name": "cnlunar",
            "version": _provider_version(),
            "supported_local_dates": {
                "start": SUPPORTED_DATE_START.isoformat(),
                "end": SUPPORTED_DATE_END.isoformat(),
            },
        },
        "input": {
            "timestamp": instant.isoformat(),
            "timezone": timezone_label,
            "local_datetime": local_datetime.isoformat(),
            "year_boundary": year_boundary,
        },
        "solar": {
            "date": local_date.isoformat(),
            "weekday": lunar.weekDayCn,
        },
        "lunar": {
            "year": lunar.lunarYear,
            "month": lunar.lunarMonth,
            "day": lunar.lunarDay,
            "is_leap_month": lunar.isLunarLeapMonth,
            "year_cn": lunar.lunarYearCn,
            "month_cn": lunar.lunarMonthCn,
            "day_cn": lunar.lunarDayCn,
            "zodiac": lunar.chineseYearZodiac,
        },
        "four_pillars": four_pillars,
        "two_hour_pillars": two_hour_pillars,
        "current_two_hour_index": lunar.twohourNum,
        "solar_terms": {
            "today": today_solar_term,
            "next": {
                "name": lunar.nextSolarTerm,
                "date": _next_solar_term_date(
                    lunar.nextSolarTermYear,
                    lunar.nextSolarTermDate,
                ),
            },
        },
        "wealth_god": {
            "direction": wealth_direction,
            "raw": wealth_raw,
        },
        "calculation_trace": [
            {
                "rule_id": "almanac.cnlunar.four_pillars.v1",
                "input": wall_clock.isoformat(),
                "options": {
                    "god_type": "8char",
                    "year_boundary": upstream_year_boundary,
                },
                "output": [pillar["ganzhi"] for pillar in four_pillars],
            },
            {
                "rule_id": "almanac.nayin.sixty_jiazi.v1",
                "input": [pillar["ganzhi"] for pillar in four_pillars],
                "output": [pillar["nayin"] for pillar in four_pillars],
            },
            {
                "rule_id": "almanac.cnlunar.wealth_god.v1",
                "input": {"day_stem": four_pillars[2]["stem"]},
                "provider_output": lucky_directions,
                "output": wealth_direction,
            },
        ],
    }


def calculate_month_calendar(
    year: int,
    month: int,
    *,
    timezone_name: str = "Asia/Shanghai",
    year_boundary: YearBoundary = "lunar_new_year",
) -> dict[str, Any]:
    """Return a Monday-first, fixed six-week calendar grid.

    Each supported cell contains only the fields needed by the month view.
    Adjacent dates outside cnlunar's safe range remain in the 42-cell grid but
    are marked unavailable so the UI can render them without inventing data.
    """

    try:
        month_start = date(year, month, 1)
    except ValueError as error:
        raise ValueError("year and month must identify a valid calendar month") from error
    month_end = date(year, month, monthrange(year, month)[1])
    if month_end < SUPPORTED_DATE_START or month_start > SUPPORTED_DATE_END:
        raise ValueError(
            "requested month does not overlap cnlunar adapter support from "
            f"{SUPPORTED_DATE_START.isoformat()} through {SUPPORTED_DATE_END.isoformat()}"
        )
    try:
        timezone = ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError as error:
        raise ValueError(f"unknown IANA timezone: {timezone_name}") from error

    grid_start = month_start - timedelta(days=month_start.weekday())
    cells: list[dict[str, Any]] = []
    for offset in range(42):
        cell_date = grid_start + timedelta(days=offset)
        base_cell: dict[str, Any] = {
            "date": cell_date.isoformat(),
            "solar_day": cell_date.day,
            "weekday": cell_date.isoweekday(),
            "in_current_month": cell_date.month == month,
        }
        if not SUPPORTED_DATE_START <= cell_date <= SUPPORTED_DATE_END:
            cells.append(
                {
                    **base_cell,
                    "available": False,
                    "lunar": None,
                    "day_pillar": None,
                    "solar_term": None,
                }
            )
            continue

        cell_wall_clock = datetime.combine(cell_date, time(hour=12), timezone)
        snapshot = calculate_almanac(
            cell_wall_clock.isoformat(),
            timezone_name=timezone_name,
            year_boundary=year_boundary,
        )
        lunar = snapshot["lunar"]
        cells.append(
            {
                **base_cell,
                "available": True,
                "lunar": {
                    "month": lunar["month"],
                    "day": lunar["day"],
                    "is_leap_month": lunar["is_leap_month"],
                    "month_cn": lunar["month_cn"],
                    "day_cn": lunar["day_cn"],
                },
                "day_pillar": snapshot["four_pillars"][2],
                "solar_term": snapshot["solar_terms"]["today"],
            }
        )

    available_count = sum(1 for cell in cells if cell["available"])
    return {
        "schema_version": ALMANAC_SCHEMA_VERSION,
        "adapter_version": ALMANAC_ADAPTER_VERSION,
        "provider": {
            "name": "cnlunar",
            "version": _provider_version(),
            "supported_local_dates": {
                "start": SUPPORTED_DATE_START.isoformat(),
                "end": SUPPORTED_DATE_END.isoformat(),
            },
        },
        "request": {
            "year": year,
            "month": month,
            "timezone": timezone_name,
            "year_boundary": year_boundary,
        },
        "grid": {
            "week_starts_on": "monday",
            "rows": 6,
            "columns": 7,
            "start": cells[0]["date"],
            "end": cells[-1]["date"],
        },
        "cells": cells,
        "calculation_trace": {
            "rule_id": "almanac.cnlunar.month_grid.v1",
            "cell_calculation_time": "12:00:00",
            "total_cells": len(cells),
            "available_cells": available_count,
        },
    }
