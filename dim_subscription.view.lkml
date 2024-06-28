view: dim_subscription {
  sql_table_name: public.dim_subscription ;;
  # contains information about user subscription status when an action was taken

  label: "Subscription Info"

  parameter: granularity_period {
    type: string
    allowed_value: {value: "Day"}
    allowed_value: {value: "Week"}
    allowed_value: {value: "Month"}
    allowed_value: {value: "Quarter"}
  }

  dimension: subscription_end_granularity_date {
    type: date
    convert_tz: no
    sql: case
         when {% parameter granularity_period %} = 'Day' then date_trunc('day', ${subscription_end_date_date})
         when {% parameter granularity_period %} = 'Week' then date_trunc('week', ${subscription_end_date_date})
         when {% parameter granularity_period %} = 'Month' then date_trunc('month', ${subscription_end_date_date})
         when {% parameter granularity_period %} = 'Quarter' then date_trunc('quarter', ${subscription_end_date_date})
       end ;;
  }

  dimension_group: date_ended {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.date_ended ;;
  }

  dimension_group: date_started {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.date_started ;;
  }

  dimension_group: next_billing_date {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.next_billing_date ;;
  }

  dimension_group: subscription_date {
    type: time
    timeframes: [
      raw,
      time,
      hour,
      date,
      week,
      month,
      quarter,
      year,
      day_of_month,
      day_of_week
    ]
    sql: ${TABLE}.subscription_date ;;
  }

  dimension: subscription_day_of_month {
    type: number
    sql: EXTRACT(d from CONVERT_TIMEZONE('America/New_York', 'UTC', ${subscription_date_raw})) ;;
    hidden: yes
  }

  dimension_group: subscription_pay {
    description: "A date of the first whole payment for the Free_trial and a subscription date for other subscriptions"
    type: time
    timeframes: [
      raw,
      time,
      hour,
      date,
      week,
      month,
      quarter,
      year,
      day_of_month,
      day_of_week
    ]
    sql: ${TABLE}.subscription_pay_date ;;
  }

  dimension_group: subscription_end_date {
    type: time
    timeframes: [
      raw,
      time,
      hour,
      date,
      week,
      month,
      quarter,
      year,
      day_of_month,
      day_of_week
    ]
    sql: ${TABLE}.subscription_end_date ;;
  }

  dimension_group: last_card_failed {
    type: time
    timeframes: [
      raw,
      time,
      hour,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.last_card_failed_date ;;
  }

  dimension_group: last_serie_card_failed {
    type: time
    timeframes: [
      raw,
      time,
      hour,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.last_serie_card_failed_date ;;
  }

  dimension_group: hidden_today {
    type: time
    timeframes: [day_of_month]
    hidden: yes
    sql: getdate() ;;
  }

  dimension: id {
    hidden: yes
    primary_key: yes
    type: string
    sql: ${TABLE}.uniq_id ;;
  }

  dimension: legacy_id {
    hidden: yes
    type: number
    sql: ${TABLE}.legacy_id ;;
  }

  dimension: adjust_network_name {
    group_label: "Marketing"
    type: string
    sql: ${TABLE}.adjust_network_name ;;
  }

  dimension: adjust_campaign_name {
    group_label: "Marketing"
    type: string
    sql: ${TABLE}.adjust_campaign_name ;;
  }

  dimension: adjust_adgroup_name {
    group_label: "Marketing"
    type: string
    sql: ${TABLE}.adjust_adgroup_name ;;
  }

  dimension: adjust_creative_name {
    group_label: "Marketing"
    sql: ${TABLE}.adjust_creative_name ;;
  }

  dimension: adjust_tracker_name {
    group_label: "Marketing"
    type: string
    sql: ${TABLE}.adjust_tracker_name ;;
  }


  dimension: channel {
    group_label: "Marketing"
    type: string
    sql: ${TABLE}.channel ;;
  }

  dimension: channel_agr {
    group_label: "Marketing"
    type: string
    sql: case
          when ${channel} like '%Facebook%' then 'Facebook'
          when ${channel} = 'Instagram' then 'Facebook'
          when ${channel} like '%Adparlor%' then 'Facebook'
          when ${channel} like '%Stoyo%' then 'Facebook'
          when ${channel} = 'Agency (Group 9)' then 'Facebook'
          when ${channel} like '%Influencers%' then 'Influencers'
          when ${channel} = 'Tiktok' then 'Tiktok'
          when ${channel} = 'Bing' then 'Bing'
          when ${channel} like '%Affiliate (Fluent)%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Fluent MEN%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Fluent HDR50%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Fluent without card%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Tapjoy free_trial%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Ironsrc Free Trial%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Fluent low quality%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (tophatter%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Cactus Media freetrial%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (FREE_TRIAL not Fluent%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (Fluent boodle%' then 'Fluent\\Free_trial'
          when ${channel} like '%Affiliate (flex_mg%' then 'Fluent\\Free_trial'
          when ${channel} like '%Email%' then 'Email'
          when ${channel} like '%Adwords%' then 'Adwords'
          when ${channel} like '%Other%' then 'Organic\\Not_set'
          when ${channel} like '%Affiliate (Rokt)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (flex_mg 25_off)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (Ironsrc 25_off)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate All%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate All (Fluent w standard_offer)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (Miles 60_off)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (pepperjam)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (pepperjam_176193)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (Tapjoy 25_off)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (Nift 60_off)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (Ad Net)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (ClickBooth%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Affiliate (tophatter)%' then 'Affiliate (non Free_trial)'
          when ${channel} like '%Fluent (Flashrewards)%' then 'Affiliate (non Free_trial)'
          else 'Other'
         end ;;
  }

  dimension: landing_page_host {
    label: "Marketing"
    type: string
    sql: ${TABLE}.landing_page_host ;;
  }

  dimension: landing_page_url {
    label: "Marketing"
    type: string
    sql: ${TABLE}.landing_page_url ;;
  }

  dimension: utm_campaign {
    label: "Marketing"
    type: string
    sql: ${TABLE}.utm_campaign ;;
  }

  dimension: utm_content {
    label: "Marketing"
    type: string
    sql: ${TABLE}.utm_content ;;
  }

  dimension: utm_medium {
    label: "Marketing"
    type: string
    sql: ${TABLE}.utm_medium ;;
  }

  dimension: utm_source {
    label: "Marketing"
    type: string
    sql: ${TABLE}.utm_source ;;
  }

  dimension: utm_term {
    label: "Marketing"
    type: string
    sql: ${TABLE}.utm_term ;;
  }

  dimension: first_coupon {
    description: "First used coupon for subscription"
    label: "Marketing"
    type: string
    sql: ${TABLE}.first_coupon ;;
  }

  dimension: marketing_coupon_code {
    label: "Code"
    type: string
    group_label: "Marketing"
    sql: ${TABLE}.marketing_coupon_code ;;
  }

  dimension: is_marketing_free_trial {
    label: "Is Free Trial"
    type: string
    group_label: "Marketing"
    sql: ${TABLE}.is_marketing_free_trial ;;
  }

  dimension: marketing_coupon_type {
    label: "Type"
    type: string
    group_label: "Marketing"
    sql: ${TABLE}.marketing_coupon_type ;;
  }

  dimension: marketing_coupon_revenue {
    label: "Revenue"
    type: number
    group_label: "Marketing"
    sql: ${TABLE}.marketing_coupon_revenue ;;
  }

  dimension_group: marketing_coupon_redeem {
    type: time
    label: "Redeem"
    group_label: "Marketing"
    timeframes: [
      raw,
      date,
      month,
      year
    ]
    sql: ${TABLE}.marketing_coupon_redeem_date ;;
  }

  dimension: billing_period {
    group_label: "Current Plan"
    type: number
    sql: ${TABLE}.billing_period ;;
  }

  dimension: price {
    group_label: "Current Plan"
    type: number
    sql: ${TABLE}.price ;;
  }

  dimension: monthly_price {
    group_label: "Current Plan"
    type: number
    sql: ${price}/${billing_period} ;;
  }

  dimension: months_in_plan {
    group_label: "Current Plan"
    type: number
    sql: case
          when ${plan} in (
          'MONTHLY','BIMONTHLY','TRIMONTHLY','MONTHLY_2PCS','BIMONTHLY_2PCS','TRIMONTHLY_2PCS','MONTHLY_3PCS','BIMONTHLY_3PCS','TRIMONTHLY_3PCS','GIFT_ORDER','GIFT_ACCEPT','BIMONTHLY_GIFT_ACCEPT','COUPON_MONTHLY','BIMONTHLY_COUPON_MONTHLY','RECURRING_COUPON_MONTHLY','BIMONTHLY_RECURRING_COUPON_MONTHLY'
          )
          then 1
          when ${plan} in (
          'QUARTER','BIMONTHLY_QUARTER','TRIMONTHLY_QUARTER','QUARTER_2PCS','BIMONTHLY_QUARTER_2PCS','TRIMONTHLY_QUARTER_2PCS','QUARTER_3PCS','BIMONTHLY_QUARTER_3PCS','TRIMONTHLY_QUARTER_3PCS','GIFT_ORDER_QUARTER','GIFT_ACCEPT_QUARTER','BIMONTHLY_GIFT_ACCEPT_QUARTER','COUPON_QUARTER','BIMONTHLY_COUPON_QUARTER','RECURRING_COUPON_QUARTER','BIMONTHLY_RECURRING_COUPON_QUARTER'
          )
          then 3
          when ${plan} in (
          'SEMI_ANNUAL','BIMONTHLY_SEMI_ANNUAL','TRIMONTHLY_SEMI_ANNUAL','SEMI_ANNUAL_2PCS','BIMONTHLY_SEMI_ANNUAL_2PCS','TRIMONTHLY_SEMI_ANNUAL_2PCS','SEMI_ANNUAL_3PCS','BIMONTHLY_SEMI_ANNUAL_3PCS','TRIMONTHLY_SEMI_ANNUAL_3PCS','GIFT_ORDER_SEMI_ANNUAL','GIFT_ACCEPT_SEMI_ANNUAL','BIMONTHLY_GIFT_ACCEPT_SEMI_ANNUAL','COUPON_SEMI_ANNUAL','BIMONTHLY_COUPON_SEMI_ANNUAL','RECURRING_COUPON_SEMI_ANNUAL','BIMONTHLY_RECURRING_COUPON_SEMI_ANNUAL'
          )
          then 6
          when ${plan} in (
          'ANNUAL','BIMONTHLY_ANNUAL','TRIMONTHLY_ANNUAL','GIFT_ORDER_ANNUAL','GIFT_ACCEPT_ANNUAL','BIMONTHLY_GIFT_ACCEPT_ANNUAL','COUPON_ANNUAL','BIMONTHLY_COUPON_ANNUAL','RECURRING_COUPON_ANNUAL','BIMONTHLY_RECURRING_COUPON_ANNUAL'
          )
          then 12
    end;;
  }

  dimension: products_per_period {
    group_label: "Current Plan"
    type:  number
    sql: ${TABLE}.products_per_period ;;
  }

  dimension: shipping_period {
    group_label: "Current Plan"
    type: number
    sql: ${TABLE}.shipping_period ;;
  }

  dimension: current_plan {
    group_label: "Current Plan"
    type: string
    sql: ${TABLE}.current_plan ;;
  }

  dimension: current_status {
    group_label: "Current Plan"
    type: string
    sql: ${TABLE}.current_status ;;
  }

  dimension: lifetime {
    group_label: "Lifetime metrics"
    description: "number of days between subscription date and subscription end date / current date"
    type: number
    sql: datediff("day", ${subscription_date_raw}, COALESCE(${subscription_end_date_raw}, current_date)) ;;
  }

  dimension: lifetime_hours {
    group_label: "Lifetime metrics"
    description: "number of hours between subscription date and subscription end date / current date"
    type: number
    sql: datediff("hour", ${subscription_date_raw},  COALESCE(${subscription_end_date_raw}, current_date)) ;;
  }

  dimension: lifetime_month {
    group_label: "Lifetime metrics"
    description: "number of months between subscription date and subscription end date / current date"
    type: number
    sql: datediff("month", ${subscription_date_raw},  COALESCE(${subscription_end_date_raw}, current_date)) ;;
  }

  dimension: payment_provider {
    type: string
    sql: ${TABLE}.payment_provider ;;
  }

  dimension: first_charge_payment_type {
    type: string
    sql: ${TABLE}.first_charge_payment_type ;;
  }

  dimension: is_current_subscription {
    type: yesno
    label: "Is Current Subscription"
    sql: ${TABLE}.is_current_subscription ;;
  }

  dimension: current_type {
    type: string
    sql: ${TABLE}.current_type ;;
  }

  dimension: coupon {
    type: string
    description: "Last used coupon for subscription"
    sql: ${TABLE}.coupon ;;
  }

  dimension: plan {
    type: string
    sql: ${TABLE}.plan ;;
  }

  dimension: first_month_upgraded_plan {
    group_label: "First Month Upgrade"
    type: string
    sql: ${TABLE}.first_month_upgraded_plan ;;
  }

  dimension: first_month_upgraded_shipping_period {
    group_label: "First Month Upgrade"
    type: number
    sql: ${TABLE}.first_month_upgraded_shipping_period ;;
  }

  dimension: first_month_upgraded_products_per_period {
    group_label: "First Month Upgrade"
    type: number
    sql: ${TABLE}.first_month_upgraded_products_per_period ;;
  }

  dimension: first_month_upgrade {
    group_label: "First Month Upgrade"
    description: "Simplified flag that shows products per period only in case if
    there was an upgrade or no otherwise"
    type: string
    sql: case
      when first_month_upgraded_products_per_period is not null then
        first_month_upgraded_products_per_period::varchar
        else 'no'
      end;;
  }

  dimension: credits_amount {
    type: number
    sql: ${TABLE}.credits_amount ;;
  }

  dimension: subscription_id {
    type: number
    sql: ${TABLE}.subscription_id ;;
  }

  dimension: type {
    type: string
    sql: ${TABLE}.type ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: is_first_subscription_flag {
    type: yesno
    label: "Is First Subscription"
    sql: ${TABLE}.is_first_subscription ;;
  }

  dimension: month_number_from_subscription {
    type:  number
    sql: datediff('month', ${TABLE}.subscription_date, CURRENT_DATE) ;;
    description: "Number of months from subscription to current date"
  }

  dimension: subscription_date_to_charge_date {
    label: "Number of months from subscription date to a charge"
    type:  number
    sql:  datediff('month', DATE_TRUNC('month', ${dim_subscription.subscription_date_raw}),DATE_TRUNC('month',${cohort_charges.charge_date_raw})) ;;
  }

  dimension: subscription_pay_date_to_charge_date {
    label: "Number of months from subscription pay date to a charge"
    type:  number
    sql:  datediff('month', DATE_TRUNC('month', ${dim_subscription.subscription_pay_raw}),DATE_TRUNC('month',${cohort_charges.charge_date_raw})) ;;
  }

  dimension: user_time_to_cohort {
    description: "Number of months between subscription date and cohort month (each column in a cohort analysis)"
    type:  number
    sql:  datediff('month', DATE_TRUNC('month', ${dim_subscription.subscription_date_raw}),DATE_TRUNC('month', ${active_cohort.start_date})) ;;
  }

  dimension: is_active {
    description: "Currently active which means status in ('Active', 'Pending','PendingUpgrade')"
    type: yesno
    sql:  ${current_status} in ('Active', 'Pending','PendingUpgrade');;
  }

  dimension: sharing_frequency {
    description: "How many sharings has a user per month on average (within a lifetime)"
    type: number
    sql:${dim_user.user_sharing}::float/(${lifetime_month}+1) ;;
  }

  dimension:subscription_date_to_further_month {
    description: "Number of months from the first Month to the one in cohort"
    type:  number
    sql:  datediff('month', DATE_TRUNC('month', ${subscription_date_raw}),DATE_TRUNC('month', ${fact_subscription_monthly_further.date_month_raw})) ;;
  }

  dimension: offer {
    type:  string
    sql: ${TABLE}.offer ;;
  }

  dimension: coupon_id {
    type:  number
    sql: ${TABLE}.coupon_id ;;
  }

  dimension: platform{
    description: "Like  web or android or IOS"
    type: string
    sql: ${TABLE}.platform ;;
  }

  dimension: platform_version {
    description: "A version of the platform"
    type: string
    sql: ${TABLE}.platform_version ;;
  }

  dimension: refunded_after_cancellation {
    group_label: "Unsubscribe info"
    description: "Whether there was a refund after cancellation of subscription"
    type: yesno
    sql: ${TABLE}.refunded_after_cancellation ;;
  }

  dimension: url_to_admin_panel {
    type: string
    hidden:  yes
    sql: concat('https://admin.scentbird.com/user/show/', ${dim_subscription.user_id}) ;;
  }

  dimension: link_to_admin_panel {
    type: string
    sql: ${url_to_admin_panel} ;;
    html: <a href="{{value}}" target="_blank">Show User</a> ;;
  }

  dimension: url_to_order_admin_panel {
    type: string
    hidden: yes
    sql: concat('https://crm.scentbird.com/user/', ${dim_subscription.user_id}, '/profile/orders/', ${dim_orders.order_id}) ;;
  }

  dimension: link_to_order_admin_panel {
    type: string
    sql: ${url_to_order_admin_panel} ;;
    html: <a href="{{value}}" target="_blank">Show Order</a> ;;
  }

  dimension: billing_day {
    description: "Day of month the subscription will be charge for next period"
    type: number
    sql: ${TABLE}.billing_day ;;
  }

  measure: subscription_count {
    type: count_distinct
    sql: ${subscription_id} ;;
    drill_fields: [id, user_id, type]
  }
}
