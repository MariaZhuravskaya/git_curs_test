{{
 config(
   materialized='view'
 )
}}

with generated_dates as (
   {{ dbt_utils.date_spine("day", "cast('2016-02-01' as date)", 'dateadd("day", 1, current_date)') }}
)

select
  dss.*,
  gd.date_day::timestamp_ntz as historical_date
from {{ ref('dim_subscription_snapshot') }} dss
  inner join generated_dates gd on gd.date_day between dateadd('day', -1, dss.dbt_valid_from) and coalesce(dss.dbt_valid_to, current_date)
