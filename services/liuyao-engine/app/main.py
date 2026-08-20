"""HTTP boundary for the stateless Liuyao engine."""

from __future__ import annotations

from typing import Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .almanac import (
    ALMANAC_ADAPTER_VERSION,
    ALMANAC_SCHEMA_VERSION,
    calculate_almanac,
    calculate_month_calendar,
)
from .engine import ENGINE_VERSION, SCHEMA_VERSION, cast_chart


class CastRequest(BaseModel):
    timestamp: str = Field(description="RFC 3339 timestamp with UTC offset")
    line_values: list[int] | None = Field(default=None, min_length=6, max_length=6)
    seed: str | int | None = None
    casting_method: Literal["three_coins", "manual"] = "three_coins"


class AlmanacRequest(BaseModel):
    timestamp: str = Field(description="RFC 3339 timestamp with UTC offset")
    timezone: str | None = Field(default=None, description="Optional IANA timezone")
    year_boundary: Literal["lunar_new_year", "beginning_of_spring"] = "lunar_new_year"


class AlmanacMonthRequest(BaseModel):
    year: int
    month: int = Field(ge=1, le=12)
    timezone: str = Field(default="Asia/Shanghai", description="IANA timezone")
    year_boundary: Literal["lunar_new_year", "beginning_of_spring"] = "lunar_new_year"


app = FastAPI(title="六爻存档排盘引擎", version=ENGINE_VERSION)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "ok": True,
        "name": "六爻存档排盘引擎",
        "engine_version": ENGINE_VERSION,
        "schema_version": SCHEMA_VERSION,
        "almanac_adapter_version": ALMANAC_ADAPTER_VERSION,
        "almanac_schema_version": ALMANAC_SCHEMA_VERSION,
    }


@app.post("/v1/cast")
def cast(payload: CastRequest) -> dict[str, object]:
    if payload.casting_method == "manual" and payload.line_values is None:
        raise HTTPException(status_code=422, detail="manual casting requires line_values")
    try:
        return cast_chart(
            payload.timestamp,
            line_values=payload.line_values,
            seed=payload.seed,
            casting_method=payload.casting_method,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/v1/almanac")
def almanac(payload: AlmanacRequest) -> dict[str, object]:
    try:
        return calculate_almanac(
            payload.timestamp,
            timezone_name=payload.timezone,
            year_boundary=payload.year_boundary,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/v1/almanac/month")
def almanac_month(payload: AlmanacMonthRequest) -> dict[str, object]:
    try:
        return calculate_month_calendar(
            payload.year,
            payload.month,
            timezone_name=payload.timezone,
            year_boundary=payload.year_boundary,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
