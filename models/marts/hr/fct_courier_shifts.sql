{{
    config(
        materialized = 'table',
        partition_by = {
            "field": "shift_date",
            "data_type": "date"
        },
        cluster_by = ['courier_id']
    )
}}

WITH shifts AS (
    SELECT * FROM {{ ref('int_courier_shifts') }}
),

-- Use full snapshot history — not dim_couriers (current state only)
-- This ensures we get the contract rate valid AT THE TIME of the shift
contracts AS (
    SELECT * FROM {{ ref('courier_contracts_snapshot') }}
),

final AS (
    SELECT
        -- Keys
        s.courier_id,
        s.store_id,
        s.shift_date,

        -- Shift metrics
        s.shift_started_at,
        s.shift_ended_at,
        s.hours_worked,
        s.deliveries_completed,

        -- Contract details at time of shift — SCD2 temporal join
        -- Join on shift_date falling within the contract validity window
        ct.hourly_rate_eur,
        ct.contract_type,
        ct.employment_rank,

        -- Gross pay calculated at the rate valid on shift date
        ROUND(
            s.hours_worked * ct.hourly_rate_eur,
            2
        )                                       AS gross_pay_eur,

        -- Cumulative hours per courier — running total window function
        SUM(s.hours_worked) OVER (
            PARTITION BY s.courier_id
            ORDER BY s.shift_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )                                       AS cumulative_hours_worked

    FROM shifts s
    LEFT JOIN contracts ct
        ON s.courier_id = ct.courier_id
        -- Temporal join: rate must be valid on the shift date
        AND s.shift_date >= DATE(ct.dbt_valid_from)
        AND s.shift_date < DATE(
            COALESCE(ct.dbt_valid_to, '9999-12-31')
        )
)

SELECT * FROM final