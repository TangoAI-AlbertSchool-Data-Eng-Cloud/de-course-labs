SELECT
    p_id,
    NULLIF(TRIM(p_name), '') AS product_name,
    category_id,
    ROUND(price, 2) AS price
FROM {{ source('marketplace', 'product') }}
