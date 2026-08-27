from __future__ import annotations

from datetime import datetime
from typing import Any

import pandas as pd


REQUIRED_NUMERIC = ["open", "high", "low", "close", "adjclose"]


def transform_candles(raw_response: dict[str, Any]) -> dict[str, Any]:
    """Pure transform: no network, environment access, file writes or database access."""
    data = raw_response.get("data", {})
    symbol = data.get("symbol")
    candles = data.get("candles", [])
    if not symbol or not isinstance(candles, list):
        raise ValueError("Malformed response envelope")

    rows: list[dict[str, Any]] = []
    rejected: list[dict[str, Any]] = []
    seen_dates: set[str] = set()

    for idx, candle in enumerate(candles):
        try:
            date_text = candle.get("date")
            if not isinstance(date_text, str):
                raise ValueError("missing/invalid date")
            date = datetime.strptime(date_text, "%Y-%m-%d").date()

            if date.isoformat() in seen_dates:
                raise ValueError("duplicate date")

            for field in REQUIRED_NUMERIC:
                if field not in candle or candle[field] is None:
                    raise ValueError(f"missing required field: {field}")
                if not isinstance(candle[field], (int, float)) or isinstance(candle[field], bool):
                    raise ValueError(f"non-numeric field: {field}")

            if candle["high"] < candle["low"]:
                raise ValueError("high below low")

            volume = candle.get("volume")
            if volume is not None:
                if not isinstance(volume, (int, float)) or isinstance(volume, bool):
                    raise ValueError("non-numeric volume")
                if volume < 0:
                    raise ValueError("negative volume")

            seen_dates.add(date.isoformat())
            rows.append({
                "symbol": symbol,
                "date": date.isoformat(),
                "open": float(candle["open"]),
                "high": float(candle["high"]),
                "low": float(candle["low"]),
                "close": float(candle["close"]),
                "adjclose": float(candle["adjclose"]),
                "volume": None if volume is None else int(volume),
                "synthetic": bool(candle.get("synthetic", False)),
            })
        except (TypeError, ValueError) as exc:
            rejected.append({"row_index": idx, "reason": str(exc), "row": candle})

    frame = pd.DataFrame(rows, columns=[
        "symbol", "date", "open", "high", "low", "close", "adjclose",
        "volume", "synthetic"
    ])
    if not frame.empty:
        frame["date"] = pd.to_datetime(frame["date"])
        frame = frame.sort_values("date").reset_index(drop=True)

    return {"symbol": symbol, "data": frame, "rejected": rejected}
