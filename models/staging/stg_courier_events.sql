WITH source AS (
    SELECT * FROM {{ source('flinky_raw', 'raw_courier_events') }}
),

renamed AS (
    SELECT
        -- Keys
        courier_event_id,
        order_id,
        courier_id,
        store_id,

        -- Event type — normalised
        LOWER(TRIM(event_type))                 AS event_type,

        -- Timestamps
        CAST(event_timestamp AS TIMESTAMP)      AS event_timestamp,
        CAST(_loaded_at AS TIMESTAMP)           AS _loaded_at

    FROM source
)

SELECT * FROM renamed