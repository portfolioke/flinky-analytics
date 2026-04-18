{{
    config(
        materialized = 'table',
        partition_by = none,
        cluster_by = none
    )
}}

WITH couriers AS (
    SELECT * FROM {{ ref('stg_couriers') }}
),

-- Join to snapshot to get current contract details
-- dbt_valid_to IS NULL = current active contract
contracts AS (
    SELECT * FROM {{ ref('courier_contracts_snapshot') }}
    WHERE dbt_valid_to IS NULL
),

final AS (
    SELECT
        c.courier_id,
        c.first_name_hashed,
        c.last_name_hashed,
        c.age_group,
        c.courier_zone,
        c.contract_type,
        c.employment_date,
        c.employment_rank,
        c.employment_status,
        c.country_code,

        -- Current contract rate from snapshot
        ct.hourly_rate_eur,
        ct.valid_from                       AS contract_valid_from

    FROM couriers c
    LEFT JOIN contracts ct
        ON c.courier_id = ct.courier_id
)

SELECT * FROM final