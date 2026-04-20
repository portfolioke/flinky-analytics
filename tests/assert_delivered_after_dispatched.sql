-- Business rule: delivery must always happen after dispatch
-- Any row returned = data quality failure
SELECT
    order_id,
    dispatched_at,
    delivered_at
FROM {{ ref('fct_orders') }}
WHERE delivered_at IS NOT NULL
  AND dispatched_at IS NOT NULL
  AND delivered_at < dispatched_at