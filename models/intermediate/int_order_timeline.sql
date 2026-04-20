WITH order_events AS (
    SELECT * FROM {{ ref('stg_order_events') }}
),

-- Remove duplicate events: courier app sometimes sends the same
-- status change twice on network retry. Keep the latest _loaded_at.
deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id, order_status
            ORDER BY _loaded_at DESC
        ) AS row_num
    FROM order_events
),

cleaned AS (
    SELECT * FROM deduped
    WHERE row_num = 1
),

-- Pivot: turn one row per status change into one row per order
-- with a timestamp column for each milestone
-- Group only by order_id — use MAX for dimensional columns
-- to avoid duplicate rows if store/courier differs across events
pivoted AS (
    SELECT
        order_id,

        MAX(store_id)                           AS store_id,
        MAX(courier_id)                         AS courier_id,
        MAX(customer_id)                        AS customer_id,
        MAX(country_code)                       AS country_code,

        MAX(CASE WHEN order_status = 'placed'
            THEN event_timestamp END)           AS order_placed_at,

        MAX(CASE WHEN order_status = 'picking'
            THEN event_timestamp END)           AS picking_started_at,

        MAX(CASE WHEN order_status = 'packed'
            THEN event_timestamp END)           AS packed_at,

        MAX(CASE WHEN order_status = 'dispatched'
            THEN event_timestamp END)           AS dispatched_at,

        MAX(CASE WHEN order_status = 'delivered'
            THEN event_timestamp END)           AS delivered_at,

        MAX(CASE WHEN order_status = 'cancelled'
            THEN event_timestamp END)           AS cancelled_at

    FROM cleaned
    GROUP BY 1
)

SELECT * FROM pivoted