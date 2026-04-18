{{
    config(
        materialized = 'table',
        partition_by = {
            "field": "order_placed_at",
            "data_type": "timestamp",
            "granularity": "day"
        },
        cluster_by = ['store_id', 'courier_id']
    )
}}

WITH orders AS (
    SELECT * FROM {{ ref('int_order_timeline') }}
),

dark_stores AS (
    SELECT * FROM {{ ref('dim_dark_stores') }}
),

couriers AS (
    SELECT * FROM {{ ref('dim_couriers') }}
),

final AS (
    SELECT
        -- Keys
        o.order_id,
        o.store_id,
        o.courier_id,
        o.customer_id,
        o.country_code,

        -- Milestone timestamps
        o.order_placed_at,
        o.picking_started_at,
        o.packed_at,
        o.dispatched_at,
        o.delivered_at,
        o.cancelled_at,

        -- P2D: core Flinky SLA metric
        TIMESTAMP_DIFF(
            o.delivered_at,
            o.order_placed_at,
            MINUTE
        )                                       AS p2d_minutes,

        -- Time from order placed to picker starting
        TIMESTAMP_DIFF(
            o.picking_started_at,
            o.order_placed_at,
            MINUTE
        )                                       AS picker_lag_minutes,

        -- Time from dispatch to delivery (last mile)
        TIMESTAMP_DIFF(
            o.delivered_at,
            o.dispatched_at,
            MINUTE
        )                                       AS last_mile_minutes,

        -- Derived order status based on which milestones are populated
        CASE
            WHEN o.delivered_at IS NOT NULL     THEN 'delivered'
            WHEN o.cancelled_at IS NOT NULL     THEN 'cancelled'
            WHEN o.dispatched_at IS NOT NULL    THEN 'in_transit'
            WHEN o.packed_at IS NOT NULL        THEN 'packed'
            WHEN o.picking_started_at IS NOT NULL THEN 'picking'
            ELSE 'placed'
        END                                     AS current_status,

        -- Dimensional context from dark store
        ds.city,
        ds.country_code                         AS store_country_code,

        -- Dimensional context from courier
        c.courier_zone,
        c.employment_rank                       AS courier_rank,

        -- Date key for joining to dim_date
        DATE(o.order_placed_at)                 AS order_date

    FROM orders o
    LEFT JOIN dark_stores ds
        ON o.store_id = ds.store_id
    LEFT JOIN couriers c
        ON o.courier_id = c.courier_id
)

SELECT * FROM final