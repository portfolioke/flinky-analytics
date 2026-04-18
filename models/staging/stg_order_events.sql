WITH source AS (
    SELECT * FROM {{source('flinky_raw', 'raw_order_events')}}
),

renamed AS (
    SELECT
        -- Keys
        order_id,
        store_id,
        courier_id,
        customer_id,

        -- Status — normalised to lowercase, trimmed
        LOWER(TRIM(status))                     AS order_status,

        -- Timestamps
        CAST(event_timestamp AS TIMESTAMP)      AS event_timestamp,
        CAST(_loaded_at AS TIMESTAMP)           AS _loaded_at,

        -- Geography
        LOWER(TRIM(country_code))               AS country_code

    FROM source
)

SELECT * FROM renamed