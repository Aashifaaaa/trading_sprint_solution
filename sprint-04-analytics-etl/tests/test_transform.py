import json
from pathlib import Path

from trading_analytics.transform import transform_candles


FIXTURES = Path(__file__).parents[1] / "fixtures"


def load(name):
    return json.loads((FIXTURES / name).read_text(encoding="utf-8"))


def test_valid_input_transforms_to_expected_output():
    result = transform_candles(load("candles-infy-ns-2026-07.json"))
    assert len(result["data"]) == 8
    assert result["rejected"] == []
    assert result["data"].iloc[0]["symbol"] == "INFY.NS"


def test_missing_required_field_is_rejected():
    result = transform_candles(load("candles-malformed.json"))
    reasons = [x["reason"] for x in result["rejected"]]
    assert any("non-numeric field: open" in r for r in reasons)


def test_out_of_range_value_is_flagged():
    result = transform_candles(load("candles-malformed.json"))
    assert any("negative volume" in x["reason"] for x in result["rejected"])


def test_rejects_a_high_below_a_low():
    result = transform_candles(load("candles-malformed.json"))
    assert any("high below low" in x["reason"] for x in result["rejected"])


def test_duplicate_date_is_rejected():
    result = transform_candles(load("candles-malformed.json"))
    assert any("duplicate date" in x["reason"] for x in result["rejected"])


def test_missing_close_is_rejected():
    payload = load("candles-malformed.json")
    # Add a focused missing-close defect.
    payload["data"]["candles"][2].pop("close")
    result = transform_candles(payload)
    assert any("missing required field: close" in x["reason"] for x in result["rejected"])


def test_invalid_date_is_rejected():
    result = transform_candles(load("candles-malformed.json"))
    assert any("does not match format" in x["reason"] for x in result["rejected"])


def test_empty_dataset_is_handled():
    payload = load("candles-infy-ns-2026-07.json")
    payload["data"]["candles"] = []
    result = transform_candles(payload)
    assert result["data"].empty
    assert result["rejected"] == []
