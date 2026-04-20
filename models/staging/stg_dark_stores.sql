WITH source AS (
    SELECT * FROM {{ source('flinky_raw', 'raw_dark_stores') }}
),

renamed AS (
    SELECT
        -- Keys
        store_id,

        -- Store details
        store_name,
        street,
        house_number,
        city,
        zip_code,
        LOWER(TRIM(country_code))               AS country_code,

        -- Capacity
        CAST(shelf_capacity AS INT64)           AS shelf_capacity,

        -- Status
        CAST(is_active AS BOOL)                 AS is_active,

        -- Dates
        CAST(opened_at AS DATE)                 AS opened_at,

        -- Metadata
        CAST(_loaded_at AS TIMESTAMP)           AS _loaded_at

    FROM source
)

SELECT * FROM renamed