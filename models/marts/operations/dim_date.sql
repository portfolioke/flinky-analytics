{{
    config(
        materialized = 'table',
        partition_by = none,
        cluster_by = none
    )
}}

WITH date_spine AS (
    -- Generate one row per day for the full operational range
    {{ dbt_utils.date_spine(
        datepart = "day",
        start_date = "cast('2024-01-01' as date)",
        end_date = "cast('2024-12-31' as date)"
    ) }}
),

final AS (
    SELECT
        CAST(date_day AS DATE)                          AS date_id,
        CAST(date_day AS DATE)                          AS full_date,
        EXTRACT(DAYOFWEEK FROM date_day)                AS day_of_week,
        FORMAT_DATE('%A', CAST(date_day AS DATE))       AS day_name,
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM date_day)
                IN (1, 7) THEN TRUE
            ELSE FALSE
        END                                             AS is_weekend,
        EXTRACT(HOUR FROM TIMESTAMP(date_day))          AS hour_of_day,
        EXTRACT(WEEK FROM date_day)                     AS week_of_year,
        EXTRACT(MONTH FROM date_day)                    AS month,
        FORMAT_DATE('%B', CAST(date_day AS DATE))       AS month_name,
        EXTRACT(QUARTER FROM date_day)                  AS quarter,
        EXTRACT(YEAR FROM date_day)                     AS year
    FROM date_spine
)

SELECT * FROM final