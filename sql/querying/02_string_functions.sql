-- Lesson 2 lab: Data Transformation va String Functions
-- PostgreSQL. Chay trong mot psql session de temp table ton tai.

CREATE TEMP TABLE lab_contacts (
    contact_id integer PRIMARY KEY,
    raw_name text,
    country text,
    phone text,
    note text
) ON COMMIT DROP;

INSERT INTO lab_contacts (contact_id, raw_name, country, phone, note)
VALUES
    (1, ' John ', 'VN', '090-123-4567', '  welcome  '),
    (2, 'Maria', NULL, '0901234567', 'active'),
    (3, '  Đặng An  ', 'VN', NULL, E'line1\nline2');

-- 1. NULL va noi chuoi
SELECT
    contact_id,
    concat_ws(' - ', btrim(raw_name), country) AS with_ws,
    concat(btrim(raw_name), ' - ', country) AS with_concat,
    btrim(raw_name) || ' - ' || country AS with_operator
FROM lab_contacts
ORDER BY contact_id;

-- 2. Audit whitespace, empty string va NULL
SELECT
    contact_id,
    raw_name,
    btrim(raw_name) AS clean_name,
    char_length(raw_name) AS raw_chars,
    char_length(btrim(raw_name)) AS clean_chars,
    raw_name <> btrim(raw_name) AS has_edge_space,
    raw_name = '' AS is_empty,
    raw_name IS NULL AS is_null
FROM lab_contacts
ORDER BY contact_id;

-- 3. Case transformation va replace
SELECT
    contact_id,
    phone,
    replace(phone, '-', '') AS phone_digits_demo,
    upper(btrim(raw_name)) AS upper_name,
    lower(btrim(raw_name)) AS lower_name
FROM lab_contacts
ORDER BY contact_id;

-- 4. Character count va byte count
SELECT
    contact_id,
    raw_name,
    char_length(raw_name) AS character_count,
    octet_length(raw_name) AS byte_count
FROM lab_contacts
ORDER BY contact_id;

-- 5. Prefix, suffix va substring
SELECT
    contact_id,
    raw_name,
    left(raw_name, 2) AS raw_prefix,
    left(btrim(raw_name), 2) AS clean_prefix,
    right(btrim(raw_name), 2) AS clean_suffix,
    substring(btrim(raw_name) FROM 2) AS without_first
FROM lab_contacts
ORDER BY contact_id;

-- 6. Function predicate va expression index
EXPLAIN (COSTS OFF)
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = 'alice@example.com';

CREATE INDEX IF NOT EXISTS sales.lab_customers_lower_email_idx
ON sales.customers (lower(btrim(email)));

ANALYZE sales.customers;

EXPLAIN (COSTS OFF)
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = 'alice@example.com';

DROP INDEX IF EXISTS sales.lab_customers_lower_email_idx;
