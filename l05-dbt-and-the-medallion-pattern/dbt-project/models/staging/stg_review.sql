SELECT
    review_id,
    buyer_id,
    rating,
    -- not null is not not-empty, and not-empty is not not-blank
    NULLIF(TRIM(r_desc), '') AS review_text,
    NULLIF(TRIM(title), '')  AS review_title
FROM {{ source('marketplace', 'review') }}
