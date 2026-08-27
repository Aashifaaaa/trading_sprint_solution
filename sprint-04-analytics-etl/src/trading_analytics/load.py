from __future__ import annotations

import datetime as dt
from pathlib import Path
from typing import Iterable

import duckdb
import pandas as pd


def _read_schema(schema_path: Path) -> str:
    return schema_path.read_text(encoding="utf-8")


def _date_dimension(frame: pd.DataFrame) -> pd.DataFrame:
    dates = pd.to_datetime(frame["date"]).dt.date.unique()
    out = []
    for d in sorted(dates):
        out.append({
            "date_key": int(d.strftime("%Y%m%d")),
            "full_date": d,
            "day": d.day,
            "month": d.month,
            "year": d.year,
            "quarter": (d.month - 1) // 3 + 1,
            "day_of_week": d.isoweekday(),
            "day_name": d.strftime("%A"),
            "month_name": d.strftime("%B"),
            "is_weekday": d.weekday() < 5,
        })
    return pd.DataFrame(out)


def load_candle_report(
    transformed: Iterable[dict],
    db_path: str | Path,
) -> Path:
    """Load market candles into a small reporting table used for Sprint 4 charts.

    The binding FACT_TRADES schema is created separately by load_star_schema().
    """
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(db_path))
    con.execute("""
        CREATE TABLE IF NOT EXISTS candle_facts (
            symbol VARCHAR,
            trade_date DATE,
            close DECIMAL(18,2),
            volume BIGINT,
            synthetic BOOLEAN
        )
    """)
    for item in transformed:
        frame = item["data"].copy()
        if frame.empty:
            continue
        con.register("frame", frame)
        con.execute("""
            INSERT INTO candle_facts
            SELECT symbol, CAST(date AS DATE), close, volume, synthetic
            FROM frame
        """)
        con.unregister("frame")
    con.close()
    return db_path


def load_star_schema(
    db_path: str | Path,
    schema_path: str | Path,
    accounts: pd.DataFrame,
    instruments: pd.DataFrame,
    orders: pd.DataFrame,
) -> Path:
    """Create/load the supplied four-table star schema.

    Dimensions are loaded first; facts resolve surrogate keys before insertion.
    Re-running with the same source order IDs is idempotent.
    """
    db_path = Path(db_path)
    con = duckdb.connect(str(db_path))
    con.execute(_read_schema(Path(schema_path)))

    now = dt.datetime.utcnow()

    # Date dimension
    order_dates = pd.to_datetime(orders["created_on"]).dt.date
    date_frame = _date_dimension(pd.DataFrame({"date": order_dates}))
    if not date_frame.empty:
        con.register("date_frame", date_frame)
        con.execute("INSERT OR IGNORE INTO dim_date SELECT * FROM date_frame")
        con.unregister("date_frame")

    # Instrument dimension
    inst = instruments.copy()
    if not inst.empty:
        inst["instrument_key"] = inst["id"].astype("int64")
        inst["symbol"] = inst["symbol"].astype(str)
        inst["name"] = inst["instrument_name"]
        inst["exchange"] = inst["exchange"]
        inst["loaded_at"] = now
        inst = inst[[
            "instrument_key","symbol","name","asset_class","currency",
            "exchange","tradable","loaded_at"
        ]]
        con.register("inst", inst)
        con.execute("""
            INSERT OR REPLACE INTO dim_instrument
            SELECT * FROM inst
        """)
        con.unregister("inst")

    # Account dimension as a Type 2 snapshot.
    acc = accounts.copy()
    if not acc.empty:
        acc["account_key"] = acc["id"].astype("int64")
        acc["effective_date"] = pd.to_datetime(acc["updated_on"]).dt.date
        acc["end_date"] = None
        acc["is_current"] = True
        acc["source_id"] = acc["id"].astype("int64")
        acc["loaded_at"] = now
        acc = acc[[
            "account_key","account_id","holder_name","status","effective_date",
            "end_date","is_current","source_id","loaded_at"
        ]]
        con.register("acc", acc)
        con.execute("DELETE FROM dim_account WHERE is_current = TRUE")
        con.execute("INSERT INTO dim_account SELECT * FROM acc")
        con.unregister("acc")

    # Fact load
    if not orders.empty:
        o = orders.copy()
        o["created_at"] = pd.to_datetime(o["created_on"]).dt.tz_localize(None)
        o["date_key"] = o["created_at"].dt.strftime("%Y%m%d").astype(int)
        o["account_key"] = o["account_id"].astype(int)
        o["instrument_key"] = o["instrument_id"].astype(int)
        o["trade_key"] = o["id"].apply(lambda x: abs(hash(str(x))) % (2**63 - 1)).astype("int64")
        o["source_order_id"] = o["id"].astype(str)
        o["price"] = o["price"].astype(float)
        o["executed_price"] = pd.to_numeric(o["executed_price"], errors="coerce")
        o["trade_value"] = (
            o["quantity"] * o["executed_price"].fillna(o["price"])
        ).round(2)
        o["loaded_at"] = now
        o = o[[
            "trade_key","account_key","instrument_key","date_key","side",
            "quantity","price","status","executed_price","trade_value",
            "source_order_id","created_at","loaded_at"
        ]]
        con.register("ord", o)
        con.execute("""
            INSERT OR IGNORE INTO fact_trades
            SELECT * FROM ord
        """)
        con.unregister("ord")

    con.close()
    return db_path
