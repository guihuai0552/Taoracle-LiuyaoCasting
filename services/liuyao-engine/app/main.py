"""HTTP boundary for the stateless Liuyao engine."""

from __future__ import annotations

from typing import Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from .engine import ENGINE_VERSION, SCHEMA_VERSION, cast_chart


class CastRequest(BaseModel):
    timestamp: str = Field(description="RFC 3339 timestamp with UTC offset")
    line_values: list[int] | None = Field(default=None, min_length=6, max_length=6)
    seed: str | int | None = None
    casting_method: Literal["three_coins", "manual"] = "three_coins"


app = FastAPI(title="六爻存档排盘引擎", version=ENGINE_VERSION)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "ok": True,
        "name": "六爻存档排盘引擎",
        "engine_version": ENGINE_VERSION,
        "schema_version": SCHEMA_VERSION,
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
