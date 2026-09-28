-- A product has many reviews and none of them is THE review, so the only
-- safe move is to aggregate up to one row per product before joining.
SELECT
    pr.p_id,
    COUNT(*)                     AS n_reviews,
    ROUND(AVG(r.rating), 3)      AS avg_rating,
    COUNTIF(r.rating > 4) > 0    AS has_rating_above_four
FROM {{ ref('stg_product_reviews') }} AS pr
JOIN {{ ref('stg_review') }}          AS r USING (review_id)
GROUP BY pr.p_id
