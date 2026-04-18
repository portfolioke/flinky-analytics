{% snapshot courier_contracts_snapshot %}

{{
    config(
        target_schema = 'snapshots',
        unique_key = 'contract_id',
        strategy = 'timestamp',
        updated_at = 'updated_at'
    )
}}

-- SCD2 snapshot on courier contracts
-- Tracks changes to hourly_rate and employment_rank over time
-- dbt_valid_to IS NULL = currently active contract
SELECT * FROM {{ ref('stg_courier_contracts') }}

{% endsnapshot %}