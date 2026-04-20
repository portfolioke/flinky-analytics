# flinky-analytics

A dbt + BigQuery analytics engineering project modelling the core operational
and HR domains of a quick-commerce grocery delivery business.

Built as a technical demonstration for a Senior Analytics Engineer role,
covering the full transformation layer from raw event logs to trusted,
tested, consumer-ready data marts.

---

## Stack

- **dbt Core** 1.11.7
- **Google BigQuery**
- **dbt-utils** 1.3.3
- **GitHub Actions** CI/CD

---

## Project Structure
models/
staging/          # 1:1 with source tables. Cast, rename, mask PII. Views.
intermediate/     # Business logic. Deduplication, pivots, sessionisation.
marts/
operations/     # Order lifecycle, P2D metrics, dark store performance
hr/             # Courier shifts, payroll, SCD2 contract history
snapshots/          # SCD2 snapshot for courier contracts
tests/              # Singular business rule tests
seeds/              # Sample data simulating raw source tables

---

## Domains

### Operations
Models the full order lifecycle from placement to delivery.

Key models:
- `stg_order_events` — raw order status changes, PII masked
- `int_order_timeline` — deduplicates events, pivots into milestone columns
- `fct_orders` — one row per order, all milestones, P2D and picker lag metrics
- `fct_order_line_items` — one row per product per order, line totals
- `dim_dark_stores` — dark store dimension (SCD1)
- `dim_couriers` — courier dimension, joins to current contract via snapshot
- `dim_date` — shared date dimension via dbt_utils.date_spine

Key design decisions:
- `fct_orders` is **incremental** with a 3-day lookback window to catch
  late-arriving courier app events without reprocessing full history
- Partitioned by `order_placed_at` (day), clustered by `store_id` and
  `courier_id` for BigQuery cost optimisation
- P2D computed as `TIMESTAMP_DIFF(delivered_at, order_placed_at, MINUTE)`

### HR
Models courier shift history and payroll calculation.

Key models:
- `stg_courier_contracts` — employment contracts with SAFE_CAST on date fields
- `courier_contracts_snapshot` — SCD2 snapshot tracking rate and rank changes
- `int_courier_shifts` — sessionises courier events into shifts
- `fct_courier_shifts` — gross pay via SCD2 temporal join to contract snapshot

Key design decisions:
- **SCD2 temporal join**: gross pay uses the hourly rate valid *at the time
  of the shift*, not today's rate. Join condition:
  `shift_date BETWEEN dbt_valid_from AND COALESCE(dbt_valid_to, '9999-12-31')`
- Cumulative hours computed via `SUM() OVER` window function

---

## Data Quality

- **76 automated tests** across all layers
- Three levels: technical constraints → business rules → relationships
- Singular tests:
  - `assert_delivered_after_dispatched` — delivery must follow dispatch
  - `assert_p2d_within_sla_range` — P2D between 2 and 120 minutes
  - `assert_gross_pay_not_negative` — payroll sanity check
- Source freshness configured per table in `_sources.yml`

---

## CI/CD

GitHub Actions runs `dbt build` on every PR to main.
All 76 tests must pass before merge is allowed.

---

## Key Patterns Demonstrated

| Pattern | Where |
|---|---|
| Incremental model + 3-day lookback | `fct_orders` |
| Accumulating snapshot (milestone pivot) | `int_order_timeline` |
| SCD2 snapshot | `courier_contracts_snapshot` |
| SCD2 temporal join | `fct_courier_shifts` |
| ROW_NUMBER deduplication | `int_order_timeline`, `int_courier_shifts` |
| Window functions (SUM OVER, ROW_NUMBER) | `fct_courier_shifts`, intermediate layer |
| Date spine | `dim_date` |
| PII masking at staging | `stg_couriers`, `stg_order_events` |
| BigQuery partitioning + clustering | `fct_orders`, `fct_courier_shifts` |

---

## Running the Project

```bash
# Install dependencies
dbt deps

# Load seed data
dbt seed

# Build all models
dbt run

# Run all tests
dbt test

# Build + test in one command
dbt build
```