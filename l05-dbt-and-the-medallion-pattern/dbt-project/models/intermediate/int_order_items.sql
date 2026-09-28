-- order_items records no date of its own, so the date comes from the order.
-- That join is a decision, which is why this is not a staging model.
SELECT
    i.order_id,
    i.p_id,
    i.qty,
    i.price_at_purchase,
    o.order_date,
    o.buyer_id
FROM {{ ref('stg_order_items') }} AS i
JOIN {{ ref('stg_orders') }}      AS o USING (order_id)
