-- CDC without a CDC tool: read the write-ahead log with three SQL statements.
--
-- Run:  docker exec -i albert-marketplace-db-1 psql -U postgres -d marketplace \
--         -f - < cdc-in-plain-sql.sql
--
-- Safe to run twice. Every change is made to a product this script creates and
-- then deletes, so no real row is ever touched. The first version of this
-- script changed a real price by a cent and restored it afterwards; a failed
-- run left the compensating UPDATE behind and corrupted one product's price.
-- Never write a compensating statement outside the transaction it compensates.

\echo === 0. clean up anything a previous run left behind ===
DELETE FROM product WHERE p_id = 'L03DEMO';
SELECT pg_drop_replication_slot(slot_name)
FROM pg_replication_slots WHERE slot_name = 'l03_demo';

\echo === 1. the one server setting change data capture needs ===
SELECT current_setting('wal_level') AS wal_level,
       current_setting('max_slot_wal_keep_size') AS safety_valve;

\echo === 2. a logical replication slot - this is what Debezium creates ===
SELECT slot_name FROM pg_create_logical_replication_slot('l03_demo', 'test_decoding');

\echo === 3. three changes, only the first of which a cursor could see ===
-- a new product is listed
INSERT INTO product (p_id, p_name, p_desc, price, qty)
VALUES ('L03DEMO', 'Demo kettle', 'created by the lesson 3 demo', 21.98, 1);
-- the seller corrects the price: no cursor column moves
UPDATE product SET price = 24.50 WHERE p_id = 'L03DEMO';
-- the listing is withdrawn: no row is left to read
DELETE FROM product WHERE p_id = 'L03DEMO';

\echo === 4. the write-ahead log, read as a stream of changes ===
-- test_decoding prints every column; p_desc is long, so keep the two that matter
SELECT substring(data for 70) ||
       coalesce(' … ' || substring(data from 'price\[numeric\]:[0-9.]+'), '') AS change
FROM pg_logical_slot_peek_changes('l03_demo', NULL, NULL)
WHERE data NOT LIKE 'BEGIN%' AND data NOT LIKE 'COMMIT%';

\echo === 5. the operational danger: log files held by a slot nobody reads ===
SELECT slot_name, active,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS wal_retained
FROM pg_replication_slots WHERE slot_name = 'l03_demo';

\echo === 6. drop the slot. A slot outlives the tool that made it. ===
SELECT pg_drop_replication_slot('l03_demo');
