SELECT
    p.p_id,
    p.product_name,
    p.category_id,
    p.price,
    COALESCE(r.n_reviews, 0)                    AS n_reviews,
    r.avg_rating,
    COALESCE(r.has_rating_above_four, FALSE)    AS has_rating_above_four
FROM {{ ref('stg_product') }}          AS p
LEFT JOIN {{ ref('int_product_ratings') }} AS r USING (p_id)
