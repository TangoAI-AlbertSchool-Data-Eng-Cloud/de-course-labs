SELECT
    order_id,
    p_id,
    qty,
    price_at_purchase
FROM {{ source('marketplace', 'order_items') }}
