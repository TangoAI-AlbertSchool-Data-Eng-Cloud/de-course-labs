{{ config(materialized='table') }}

-- The central fact table for reporting.
-- One row per order, with the product and quantity brought in from
-- order_items and the delivery region from shipping_details.

with orders as (

    select * from {{ ref('stg_orders') }}

),

order_items as (

    select * from {{ ref('stg_order_items') }}

),

shipping as (

    select * from {{ ref('stg_shipping_details') }}

),

customer_shipping as (

    select * from {{ ref('stg_customer_shipping') }}

)

select
    o.order_id,
    o.buyer_id,
    o.order_date                                   as created_at,
    oi.p_id                                        as product_id,
    oi.qty                                         as quantity,
    oi.price_at_purchase,
    oi.qty * oi.price_at_purchase                  as line_total,
    s.country,
    s.state                                        as region

from orders o
left join order_items oi
    on oi.order_id = o.order_id
left join customer_shipping cs
    on cs.c_id = o.buyer_id
   and cs.is_default = '1'
left join shipping s
    on s.address_id = cs.address_id
