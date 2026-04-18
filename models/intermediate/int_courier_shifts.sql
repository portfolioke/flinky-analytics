WITH courier_events AS (
    SELECT * FROM {{ ref('stg_courier_events') }}
),

-- Remove duplicate events — same deduplication pattern as order timeline
deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY courier_event_id
            ORDER BY _loaded_at DESC
        ) AS row_num
    FROM courier_events
),

cleaned AS (
    SELECT * FROM deduped
    WHERE row_num = 1
),

-- Sessionise: group courier events by courier + shift date
-- to compute shift-level metrics
-- Add shift_date before grouping to avoid aggregate in GROUP BY
with_shift_date AS (
    SELECT
        *,
        DATE(event_timestamp) AS shift_date
    FROM cleaned
),

shifts AS (
    SELECT
        courier_id,
        store_id,
        shift_date,

        MIN(event_timestamp)                    AS shift_started_at,
        MAX(event_timestamp)                    AS shift_ended_at,

        -- Hours worked derived from first to last event of the shift
        TIMESTAMP_DIFF(
            MAX(event_timestamp),
            MIN(event_timestamp),
            MINUTE
        ) / 60.0                                AS hours_worked,

        COUNT(DISTINCT order_id)                AS deliveries_completed

    FROM with_shift_date
    GROUP BY 1, 2, 3
)

SELECT * FROM shifts