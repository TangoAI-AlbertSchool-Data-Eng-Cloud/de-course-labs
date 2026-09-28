-- A singular test: returns the rows that should not exist.
-- 30 order lines carry a price that rounds to 0.00 - the float-noise defect
-- from lesson 1. Warn, do not fail: the fix is a business decision, not ours.
{{ config(severity = 'warn') }}
SELECT order_id, p_id, line_revenue
FROM {{ ref('fct_order_items') }}
WHERE line_revenue <= 0
