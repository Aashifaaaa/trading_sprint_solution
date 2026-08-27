from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

from .extract import extract_candles
from .transform import transform_candles


DEFAULT_SYMBOLS = ["INFY.NS", "RELIANCE.NS", "TATASTEEL.BO"]


def _chart_outputs(transformed, artefacts: Path) -> None:
    artefacts.mkdir(parents=True, exist_ok=True)
    valid = [x for x in transformed if not x["data"].empty]
    combined = pd.concat([x["data"] for x in valid], ignore_index=True)

    # Claim 1: closing-price movement
    fig, ax = plt.subplots(figsize=(10, 5))
    for symbol, group in combined.groupby("symbol"):
        ax.plot(group["date"], group["close"], marker="o", label=symbol)
    ax.set_title("Closing prices varied across the selected Indian instruments in July 2026")
    ax.set_xlabel("Trading date")
    ax.set_ylabel("Closing price (INR per share)")
    ax.legend()
    fig.tight_layout()
    fig.savefig(artefacts / "closing-prices.png", dpi=160)
    plt.close(fig)

    # Claim 2: volume
    volume = combined.groupby("symbol", as_index=False)["volume"].sum(min_count=1)
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(volume["symbol"], volume["volume"])
    ax.set_title("Reliance Industries had the highest recorded traded volume in the valid sample")
    ax.set_xlabel("Instrument symbol")
    ax.set_ylabel("Recorded volume (shares)")
    fig.tight_layout()
    fig.savefig(artefacts / "volume-by-instrument.png", dpi=160)
    plt.close(fig)

    # Claim 3: average close
    avg = combined.groupby("symbol", as_index=False)["close"].mean()
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(avg["symbol"], avg["close"])
    ax.set_title("Average closing price differed materially across the selected instruments")
    ax.set_xlabel("Instrument symbol")
    ax.set_ylabel("Average closing price (INR per share)")
    fig.tight_layout()
    fig.savefig(artefacts / "average-closing-price.png", dpi=160)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the Sprint 4 Fauxnance analytics pipeline.")
    parser.add_argument("--symbols", nargs="+", default=DEFAULT_SYMBOLS)
    parser.add_argument("--start", default="2026-07-01")
    parser.add_argument("--end", default="2026-07-31")
    args = parser.parse_args()

    raw = extract_candles(args.symbols, args.start, args.end)
    transformed = []
    for response in raw:
        result = transform_candles(response)
        print(
            f"TRANSFORM symbol={result['symbol']} valid={len(result['data'])} "
            f"rejected={len(result['rejected'])}"
        )
        for bad in result["rejected"]:
            print(f"REJECTED symbol={result['symbol']} row={bad['row_index']} reason={bad['reason']}")
        transformed.append(result)

    _chart_outputs(
        transformed,
        Path(__file__).resolve().parents[2] / "artefacts",
    )
    print("Charts written to artefacts/. Raw API responses are cached in .cache/.")


if __name__ == "__main__":
    main()
