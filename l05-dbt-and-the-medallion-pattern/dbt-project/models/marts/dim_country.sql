SELECT
    country,
    COUNT(*) AS n_customers
FROM {{ ref('stg_addresses') }}
GROUP BY country
