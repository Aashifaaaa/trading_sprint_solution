# Historical trade data design

## What is retained

The historical analytical grain is one executed order/trade event at the level required by the platform's analytical contract. The Sprint 3 operational database stores the order itself and its terminal execution price; the richer execution-history model (`Trade`) shown in the team's conceptual ERD is deliberately documented rather than built in Sprint 3.

For a future execution-history table, retain: order identifier, account identifier, instrument identifier, executed quantity, executed price, execution timestamp and a stable event/trade identifier. This preserves what actually happened beyond the requested order price/quantity.

## Population

Sprint 6 creates accepted orders. Sprint 7's execution/event component is the natural producer of execution records. The analytical ETL consumes the prepared trade/order data and loads the star schema.

## Incremental extraction

The incremental boundary is the order/trade creation or execution timestamp plus a stable ID as a tie-breaker. A batch records its last successful `(timestamp, id)` watermark. The next batch requests rows greater than that watermark rather than scanning all history. A small overlap/reconciliation window can be used operationally, with the target enforcing a unique source identifier so replays do not duplicate facts.

## Growth

At 100x current volume, the operational tables remain normalized and the order timestamp/account indexes continue to support the named access paths. Analytical workloads should not compete with transactional queries; the ETL extracts incrementally into the analytical store.

## Partitioning and archival decision

Do not partition the Sprint 3 operational tables yet. The supplied fixture is tiny, and premature partitioning adds operational complexity without improving the required access paths. If order/execution history reaches a scale where time-based maintenance dominates, partition the historical/event table by execution month and archive old partitions according to a documented retention policy.

## Cost and operational complexity

Retaining execution history increases storage and write volume and requires a stable event identifier, indexes and a watermark. The benefit is auditability and incremental analytics. The current design keeps the core transactional model small while leaving a clear extension point for the later event/analytics sprint.
