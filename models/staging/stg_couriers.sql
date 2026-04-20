WITH source AS (
    SELECT * FROM {{ source('flinky_raw', 'raw_couriers') }}
),

renamed AS (
    SELECT
        -- Keys
        courier_id,

        -- PII — hashed for internal joins, raw values never leave staging
        TO_HEX(MD5(CAST(first_name AS STRING)))     AS first_name_hashed,
        TO_HEX(MD5(CAST(last_name AS STRING)))      AS last_name_hashed,

        -- PII — generalised
        CASE
            WHEN CAST(SUBSTR(CAST(birthdate AS STRING), 1, 4) AS INT64)
                <= EXTRACT(YEAR FROM CURRENT_DATE()) - 35 THEN '35_plus'
            WHEN CAST(SUBSTR(CAST(birthdate AS STRING), 1, 4) AS INT64)
                <= EXTRACT(YEAR FROM CURRENT_DATE()) - 25 THEN '25_34'
            ELSE 'under_25'
        END                                         AS age_group,

        -- PII — nullified (no analytical value)
        NULL                                        AS sex,

        -- Address — kept for operational routing
        street,
        house_number,
        zip_code,
        country_code,

        -- Employment
        courier_zone,
        LOWER(TRIM(contract_type))                  AS contract_type,
        CAST(employment_date AS DATE)               AS employment_date,
        LOWER(TRIM(employment_rank))                AS employment_rank,
        LOWER(TRIM(employment_status))              AS employment_status,
        CAST(hourly_rate_eur AS NUMERIC)            AS hourly_rate_eur,

        -- Metadata
        CAST(_loaded_at AS TIMESTAMP)               AS _loaded_at

    FROM source
)

SELECT * FROM renamed