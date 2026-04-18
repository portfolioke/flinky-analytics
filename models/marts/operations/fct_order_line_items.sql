{{
    config(
        materialized = 'table',
        partition_by = none,
        cluster_by = none
    )
}}

WITH line_items AS (
    SELECT * FROM {{ ref('stg_order_line_items') }}
),

orders AS (
    -- Join to get order context — store, country, placed timestamp
    SELECT
        order_id,
        store_id,
        country_code,
        order_placed_at
    FROM {{ ref('int_order_timeline') }}
),

final AS (
    SELECT
        -- Keys
        li.line_item_id,
        li.order_id,
        li.sku_id,
        o.store_id,
        o.country_code,

        -- Quantities and pricing
        li.quantity,
        li.price_net_eur,
        li.price_gross_eur,

        -- Line total derived — not stored in source
        li.quantity * li.price_gross_eur        AS line_total_gross_eur,
        li.quantity * li.price_net_eur          AS line_total_net_eur,

        -- Tax
        li.tax_code,
        li.tax_rate,

        -- Order context
        o.order_placed_at

    FROM line_items li
    LEFT JOIN orders o
        ON li.order_id = o.order_id
)

SELECT * FROM final