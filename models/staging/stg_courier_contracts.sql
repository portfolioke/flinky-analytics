WITH source AS (
    SELECT * FROM {{ source('flinky_raw', 'raw_courier_contracts') }}
),

renamed AS (
    SELECT
        -- Keys
        contract_id,
        courier_id,

        -- Contract details
        LOWER(TRIM(contract_type))              AS contract_type,
        LOWER(TRIM(employment_rank))            AS employment_rank,
        CAST(hourly_rate_eur AS NUMERIC)        AS hourly_rate_eur,

        -- SCD2 validity window
        CAST(valid_from AS DATE)                AS valid_from,
        CASE 
            WHEN valid_to = '' OR valid_to IS NULL THEN NULL
            ELSE CAST(valid_to AS DATE)
        END                                     AS valid_to,

        -- Metadata
        CAST(updated_at AS TIMESTAMP)           AS updated_at,
        CAST(_loaded_at AS TIMESTAMP)           AS _loaded_at

    FROM source
)

SELECT * FROM renamed