-- GRAIN: one product in one order.
SELECT
    i.order_id,
    i.p_id,
    i.qty,
    i.price_at_purchase,
    i.qty * i.price_at_purchase AS line_revenue,
    i.order_date,
    a.country,
    pr.avg_rating
FROM {{ ref('int_order_items') }} AS i
LEFT JOIN {{ ref('stg_addresses') }} AS a ON a.c_id = i.buyer_id
LEFT JOIN {{ ref('int_product_ratings') }} AS pr USING (p_id)
