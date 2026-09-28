-- One model per source table. No joins. Unnamed: 0 is simply not selected.
SELECT
    order_id,
    buyer_id,
    payment_id,
    discount_id,
    order_date
FROM {{ source('marketplace', 'orders') }}
