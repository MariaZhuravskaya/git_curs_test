/*
  We have a sequence of combinations of plan, subscription_id and type ordered by date_created in m_subscription_with_type_plan_range.
  Over here we also set date_ended for each row so that each row in dim_subscription would have a valid period (date_created to date_ended)
 */
{{
 config(
   sort='date_started',
   dist='user_id'
 )
}}

with subs_with_rank as (
  select
    ussl.user_id,
    ussl.subscription_id,
    se.subscription_date,
    se.subscription_end_date,
    se.status as current_status,
    se.type as current_type,
    se.plan as current_plan,
    se.refunded_after_cancellation,
    ussl.type,
    ussl.plan,
    ussl.date_started,
    row_number() over (partition by ussl.user_id order by se.subscription_end_date desc, ussl.date_started desc, ussl.date_ended desc) as rank
  from {{ref('subscription_entity_opt_no_gifts')}} as se
    inner join {{ref('m_subscription_with_type_plan_range')}} as ussl on se.id = ussl.subscription_id
),

up_rank_subscription as (
  select
    se.id as subscription_id,
    row_number() over (partition by ussl.user_id order by ussl.date_started) as up_rank
  from {{ref('subscription_entity_opt_no_gifts')}} as se
    inner join {{ref('m_subscription_with_type_plan_range')}} as ussl on se.id = ussl.subscription_id
),

deduplicate_offers as (
  select * from (
    select
      id,
      user_id,
      subscription_id,
      offer,
      row_number() over (partition by user_id, subscription_id order by date_created desc) as rank
    from {{ref('b_user_subscription_offer')}}
  ) as buso
  where buso.rank = 1

),

charges_number as (
  select
    subscription_id,
    count(*) as charges_number
  from {{ref('actual_charges')}}
  group by 1
),

last_card_failed as (
  select
    subscription_id,
    date_created,
    row_number() over (partition by subscription_id order by date_created desc) as rank
  from {{ref('b_subscription_log')}}
  where status = 'TransactionFailed'
),

enriched_subscription_events as (
  select
    subscription_id,
    timestamp as tstamp,
    event_type,
    lag(event_type) over (partition by subscription_id order by timestamp) as previous_event_type
  from subscription_events
),

card_failed_periods as (
  select
    subscription_id,
    tstamp,
    row_number() over (partition by subscription_id order by tstamp desc) as period_index
  from enriched_subscription_events
  where event_type = 'CardFailed' and previous_event_type <> 'CardFailed'
),

recurrent_subscription_orders as (
  select
    ac.payment_date as "DATE",
    o.subscription_id,
    row_number() over (partition by o.subscription_id order by ac.payment_date) as rank
  from {{ref('b_subscription_order')}} as o
    inner join {{ref('actual_charges')}} as ac on o.charge_id = ac.id
),

ranked_charges as (
  select
    subscription_id,
    payment_type,
    row_number() over (partition by subscription_id order by date) as rank
  from {{ref('actual_charges')}}
),

enriched_marketing_coupons as (
  select
    so.subscription_id,
    mc.code,
    mc.redeem_date,
    mc.type,
    mc.revenue,
    mc.is_free_trial
  from {{ref('b_marketing_coupon')}} as mc
    inner join {{ref('b_subscription_order')}} as so on mc.subscription_order_id = so.id
),

subscription_with_rank as (
  select
    c.user_id,
    c.subscription_id,
    c.subscription_date,
    c.subscription_end_date,
    c.current_status,
    c.current_type,
    c.current_plan,
    c.type,
    c.plan,
    c.date_started,
    case
      when c.rank = 1
        then coalesce(c.subscription_end_date, '9999-01-01'::date)
      else{{ least_date('c.subscription_end_date', 'n.date_started') }}
    end as date_ended,
    c.rank = 1 as is_current_subscription,
    c.refunded_after_cancellation,
    opt.next_billing_date,
    urs.subscription_id is not null as is_first_subscription,
    opt.utm_medium,
    opt.utm_source,
    opt.utm_campaign,
    opt.utm_content,
    opt.utm_term,
    opt.coupon,
    opt.coupon_id,
    opt.first_coupon,
    opt.channel,
    opt.adjust_network_name,
    opt.adjust_campaign_name,
    opt.adjust_adgroup_name,
    opt.adjust_creative_name,
    opt.adjust_tracker_name,
    opt.payment_provider,
    bst.billing_period,
    bst.shipping_period,
    bst.credits,
    bst.price / 100.00 as price,
    bst.products_per_period,
    bst.recurrable,
    bst.upgradable,
    buso.offer,
    lcf.date_created as last_card_failed_date,
    cfp.tstamp as last_serie_card_failed_date,
    coalesce(bsc.size, 0) as credits_amount,
    case
      when opt.coupon = 'FREE_TRIAL' or opt.coupon = 'FREE_TRIAL_7' or opt.is_free_trial or emc.is_free_trial then rso.date
      else c.subscription_date
    end as subscription_pay_date,
    coalesce(css.is_upcharge_for_perfume, false) as upcharge_for_perfume_case,
    coalesce(css.is_upcharge_for_candle, false) as upcharge_for_candle,
    coalesce(css.is_upcharge_for_drift, false) as upcharge_for_drift,
    slp.landing_page_url,
    slp.landing_page_host,
    split_part(opt.application_version, '/', 1) as platform,
    split_part(opt.application_version, '/', 2) as platform_version,
    rc.payment_type as first_charge_payment_type,
    emc.code as marketing_coupon_code,
    emc.redeem_date as marketing_coupon_redeem_date,
    emc.type as marketing_coupon_type,
    emc.revenue as marketing_coupon_revenue,
    emc.is_free_trial as is_marketing_free_trial,
    fmu.first_month_upgraded_plan,
    fmu.first_month_upgraded_shipping_period,
    fmu.first_month_upgraded_products_per_period,
    opt.billing_day
  from subs_with_rank as c
    left join up_rank_subscription as urs on c.subscription_id = urs.subscription_id and urs.up_rank = 1
    left join last_card_failed as lcf on c.subscription_id = lcf.subscription_id and lcf.rank = 1
    left join card_failed_periods as cfp on c.subscription_id = cfp.subscription_id and cfp.period_index = 1
    inner join {{ref('subscription_entity_opt_no_gifts')}} as opt on c.subscription_id = opt.id
    inner join {{ref('b_subscription_plan')}} as bst on c.plan = bst.name
    left join deduplicate_offers as buso on opt.id = buso.subscription_id
    left outer join subs_with_rank as n on c.user_id = n.user_id and c.rank = n.rank + 1
    left join charges_number as cn on c.subscription_id = cn.subscription_id
    left join {{ref('m_subscription_credits')}} as bsc on c.subscription_id = bsc.subscription_id
    left join {{ref('b_subscription_entity')}} as se on c.subscription_id = se.id
    left join {{ref('b_cashbird_subscription')}} as bcs on se.cashbird_subscription_id = bcs.recurly_id
    left join {{ref('b_cashbird_subscription_settings')}} as css on bcs.id = css.subscription_id
    left join recurrent_subscription_orders as rso on c.subscription_id = rso.subscription_id and rso.rank = 2
    left join {{ref('h_subscription_landing_page')}} as slp on c.subscription_id = slp.subscription_id
    left join ranked_charges as rc on c.subscription_id = rc.subscription_id and rc.rank = 1
    left join enriched_marketing_coupons as emc on c.subscription_id = emc.subscription_id
    left join {{ref('m_first_month_upgrade')}} as fmu on c.subscription_id = fmu.subscription_id
),

status_enriched as (
  select
    subscription_id,
    status as status_enriched
  from {{ ref('s_subscription_status_enriched') }}
  qualify row_number() over (partition by subscription_id order by date desc) = 1
)

select
  {{ dbt_utils.surrogate_key(['s.subscription_id', 's.date_started', 's.type', 's.plan']) }} as uniq_id,
  {{ dbt_utils.surrogate_key([
    's.adjust_adgroup_name',
    's.adjust_campaign_name',
    's.adjust_creative_name',
    's.adjust_network_name',
    's.adjust_tracker_name',
    's.billing_day',
    's.billing_period',
    's.channel',
    's.coupon',
    's.coupon_id',
    's.credits',
    's.credits_amount',
    's.current_plan',
    's.current_status',
    's.current_type',
    's.date_ended',
    's.date_started',
    's.first_charge_payment_type',
    's.first_coupon',
    's.first_month_upgraded_plan',
    's.first_month_upgraded_products_per_period',
    's.first_month_upgraded_shipping_period',
    's.is_current_subscription',
    's.is_first_subscription',
    's.is_marketing_free_trial',
    's.landing_page_host',
    's.landing_page_url',
    's.last_card_failed_date',
    's.last_serie_card_failed_date',
    's.marketing_coupon_code',
    's.marketing_coupon_redeem_date',
    's.marketing_coupon_revenue',
    's.marketing_coupon_type',
    's.next_billing_date',
    's.offer',
    's.payment_provider',
    's.plan',
    's.platform',
    's.platform_version',
    's.price',
    's.products_per_period',
    's.recurrable',
    's.refunded_after_cancellation',
    's.shipping_period',
    's.subscription_date',
    's.subscription_end_date',
    's.subscription_id',
    's.subscription_pay_date',
    's.type',
    'uniq_id',
    's.upcharge_for_candle',
    's.upcharge_for_drift',
    's.upcharge_for_perfume_case',
    's.upgradable',
    's.user_id',
    's.utm_campaign',
    's.utm_content',
    's.utm_medium',
    's.utm_source',
    's.utm_term',
    'se.status_enriched'
  ]) }} as hash,
  se.status_enriched,
  s.*
from subscription_with_rank s
  left join status_enriched se on se.subscription_id = s.subscription_id
qualify row_number() over (partition by uniq_id order by date_ended desc) = 1
