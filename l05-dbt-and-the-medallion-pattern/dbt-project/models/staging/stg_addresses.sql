-- The default address only. One row per customer.
SELECT
    cs.c_id,
    sd.country
FROM {{ source('marketplace', 'customer_shipping') }} AS cs
JOIN {{ source('marketplace', 'shipping_details') }} AS sd USING (address_id)
WHERE cs.is_default = 1
