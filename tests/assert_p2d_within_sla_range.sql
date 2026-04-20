-- Business rule: P2D must be between 2 and 120 minutes
-- Under 2 min = timestamp error, over 120 min = pipeline issue
SELECT
    order_id,
    p2d_minutes
FROM {{ ref('fct_orders') }}
WHERE delivered_at IS NOT NULL
  AND (
      p2d_minutes < 2
      OR p2d_minutes > 120
  )