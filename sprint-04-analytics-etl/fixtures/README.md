# Fixtures

The malformed fixture deliberately contains six defects:

1. duplicate date with different close
2. missing close
3. non-numeric price (`n/a`)
4. high below low
5. negative volume
6. non-ISO date

The transform policy in this solution is **quarantine/drop invalid rows** while retaining valid rows.
For duplicate dates, the first valid occurrence wins and the duplicate is quarantined.
A missing required price, non-numeric price, high < low, negative volume, or invalid date is quarantined.
Null volume is allowed and retained as NULL.
Synthetic candles are retained and marked in the transformed output.
