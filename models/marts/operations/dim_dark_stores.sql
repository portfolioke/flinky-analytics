{{
    config(
        materialized = 'table',
        partition_by = none,
        cluster_by = none
    )
}}

WITH stores AS (
    SELECT * FROM {{ ref('stg_dark_stores') }}
),

final AS (
    SELECT
        store_id,
        store_name,
        street,
        house_number,
        city,
        zip_code,
        country_code,
        shelf_capacity,
        is_active,
        opened_at
    FROM stores
)

SELECT * FROM final