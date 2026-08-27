from pathlib import Path
import json

from trading_analytics.transform import transform_candles


def test_transform_does_not_need_network():
    fixture = Path(__file__).parents[1] / "fixtures" / "candles-reliance-ns-2026-07.json"
    payload = json.loads(fixture.read_text(encoding="utf-8"))
    result = transform_candles(payload)
    assert len(result["data"]) == 9
