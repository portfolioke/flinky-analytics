-- Business rule: gross pay must never be negative
-- Negative pay = wrong contract rate or data error
SELECT
    courier_id,
    shift_date,
    gross_pay_eur
FROM {{ ref('fct_courier_shifts') }}
WHERE gross_pay_eur < 0