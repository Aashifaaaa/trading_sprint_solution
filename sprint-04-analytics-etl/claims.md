# Claims

| # | Claim | Chart artefact |
|---|---|---|
| 1 | In the supplied July 2026 sample, Reliance Industries closed at a higher average price per share than Infosys and Tata Steel. | artefacts/average-closing-price.png |
| 2 | In the valid supplied July 2026 sample, Reliance Industries recorded the highest total reported trading volume among the selected instruments. | artefacts/volume-by-instrument.png |
| 3 | Infosys' closing price rose from INR 1,598.70 on 1 July 2026 to INR 1,615.20 on 10 July 2026, an increase of INR 16.50 (1.03%) over the observed endpoints. | artefacts/closing-prices.png |

## Notes

- Scope: INFY.NS, RELIANCE.NS and TATASTEEL.BO, July 2026 fixture period.
- The fixture values are synthetic educational data, so the claims describe the supplied dataset, not real investment conclusions.
- Invalid rows are dropped/quarantined by the transform.
- Null volume is allowed and remains null; it is not converted to zero.
- Synthetic candles are retained and flagged.
- The pipeline entry point is `trading-etl`.
