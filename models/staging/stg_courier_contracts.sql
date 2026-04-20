WITH source AS (
    SELECT * FROM {{ source('flinky_raw', 'raw_courier_contracts') }}
),

renamed AS (
    SELECT
        -- Keys
        contract_id,
        courier_id,

        -- Contract details
        LOWER(TRIM(contract_type))                  AS contract_type,
        LOWER(TRIM(employment_rank))                AS employment_rank,
        SAFE_CAST(hourly_rate_eur AS NUMERIC)       AS hourly_rate_eur,

        -- SCD2 validity window
        SAFE_CAST(valid_from AS DATE)               AS valid_from,
        SAFE_CAST(valid_to AS DATE)                 AS valid_to,

        -- Metadata
        SAFE_CAST(updated_at AS TIMESTAMP)          AS updated_at,
        SAFE_CAST(_loaded_at AS TIMESTAMP)          AS _loaded_at

    FROM source
)

SELECT * FROM renamed