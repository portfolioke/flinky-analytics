WITH source AS (
    SELECT * FROM {{ source('flinky_raw', 'raw_order_line_items') }}
),

renamed AS (
    SELECT
        -- Keys
        line_item_id,
        order_id,
        sku_id,

        -- Quantities
        CAST(quantity AS INT64)                 AS quantity,

        -- Pricing
        CAST(price_net AS NUMERIC)              AS price_net_eur,
        CAST(price_gross AS NUMERIC)            AS price_gross_eur,

        -- Tax
        LOWER(TRIM(tax_code))                   AS tax_code,
        CAST(tax_rate AS NUMERIC)               AS tax_rate,

        -- Metadata
        CAST(_loaded_at AS TIMESTAMP)           AS _loaded_at

    FROM source
)

SELECT * FROM renamed