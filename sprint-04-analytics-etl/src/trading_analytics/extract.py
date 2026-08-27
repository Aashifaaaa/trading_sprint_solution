import json
import os
import time
from pathlib import Path
from typing import Any, Iterable

import requests


class FauxnanceError(RuntimeError):
    pass


def _headers() -> dict[str, str]:
    key = os.environ.get("FAUXNANCE_API_KEY")
    if not key or key == "replace-with-your-fauxnance-key":
        raise FauxnanceError("FAUXNANCE_API_KEY is not configured")
    return {"X-Api-Key": key}


def _base_url() -> str:
    return os.environ.get(
        "FAUXNANCE_BASE_URL",
        "https://y4t9nq2bqf.execute-api.eu-west-2.amazonaws.com/v1",
    ).rstrip("/")


def _cache_path(symbol: str, start: str | None, end: str | None) -> Path:
    safe = symbol.replace("/", "_").replace(":", "_")
    cache = Path(__file__).resolve().parents[2] / ".cache"
    cache.mkdir(parents=True, exist_ok=True)
    return cache / f"{safe}_{start or 'start'}_{end or 'end'}.json"


def extract_candles(
    symbols: Iterable[str],
    start: str | None = None,
    end: str | None = None,
    timeout: float = 10.0,
    max_retries: int = 3,
) -> list[dict[str, Any]]:
    """Fetch raw Fauxnance envelopes unchanged, using a disk cache."""
    results = []
    for symbol in symbols:
        path = _cache_path(symbol, start, end)
        if path.exists():
            results.append(json.loads(path.read_text(encoding="utf-8")))
            continue

        url = f"{_base_url()}/candles/{symbol}"
        params = {}
        if start:
            params["from"] = start
        if end:
            params["to"] = end

        for attempt in range(max_retries):
            try:
                response = requests.get(
                    url, headers=_headers(), params=params, timeout=timeout
                )
                if response.status_code == 429:
                    retry_after = response.headers.get("Retry-After", "unknown")
                    raise FauxnanceError(
                        f"RATE_LIMIT 429 for {symbol}; Retry-After={retry_after}"
                    )
                if 400 <= response.status_code < 500:
                    raise FauxnanceError(
                        f"CLIENT_ERROR {response.status_code} for {symbol}: {response.text[:300]}"
                    )
                response.raise_for_status()
                raw = response.json()
                path.write_text(json.dumps(raw, indent=2), encoding="utf-8")
                results.append(raw)
                break
            except FauxnanceError:
                raise
            except (requests.ConnectionError, requests.Timeout) as exc:
                if attempt == max_retries - 1:
                    raise FauxnanceError(
                        f"CONNECTION_ERROR after {max_retries} attempts for {symbol}: {exc}"
                    ) from exc
                delay = 2 ** attempt
                print(f"CONNECTION_RETRY symbol={symbol} attempt={attempt+1} backoff={delay}s")
                time.sleep(delay)
    return results


def check_health() -> dict[str, Any]:
    response = requests.get(f"{_base_url()}/health", timeout=10)
    response.raise_for_status()
    return response.json()


def check_usage() -> dict[str, Any]:
    response = requests.get(f"{_base_url()}/usage", headers=_headers(), timeout=10)
    response.raise_for_status()
    return response.json()
