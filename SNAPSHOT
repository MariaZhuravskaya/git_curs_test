-- Snapshot for dim_subscription

{% snapshot dim_subscription_snapshot %}

    {{
        config(
          target_schema='public',
          unique_key='uniq_id',

          strategy='check',
          check_cols=['hash']
        )
    }}

select * from {{ ref('dim_subscription') }}

{% endsnapshot %}