# Lời giải Querying Sprint — JOIN và set operators

Đây là model solution. Khi workload, invariant hoặc schema khác, design có thể thay đổi nếu trade-off được giải thích.

## Level 1 — Nhớ và giải thích

1. Inner join chỉ giữ cặp có match; left join giữ toàn bộ row bên trái và điền `NULL` cho phía phải không match; cross join tạo mọi combination.
2. Nếu một parent có nhiều child, mỗi child tạo một result row kết hợp với parent; một parent có k child xuất hiện k lần.
3. Filter trong `ON` giới hạn row được match ở phía phải nhưng vẫn giữ row bên trái của outer join. Filter trong `WHERE` chạy sau đó và có thể loại null-extended row.
4. Anti-join lấy row không có match. Có thể dùng `NOT EXISTS` hoặc `LEFT JOIN ... IS NULL` với một non-nullable key phía phải.
5. `NULL` trong subquery làm `NOT IN` có thể evaluate thành `UNKNOWN`. `NOT EXISTS` kiểm tra relationship trực tiếp.
6. `UNION` loại duplicate; `UNION ALL` giữ duplicate và thường tránh chi phí distinct.
7. Hai query phải trả cùng số column; các column tương ứng phải có type tương thích. Column position, không phải tên, quyết định việc ghép.
8. Nested loop thường hợp với outer input nhỏ và lookup rẻ; hash join phù hợp equality join trên input lớn; merge join phù hợp input đã được order hoặc có thể sort hiệu quả.

## Level 2 — Áp dụng

### 1. Order kèm customer

~~~sql
SELECT
    o.order_id,
    c.full_name,
    o.order_status
FROM sales.orders AS o
JOIN sales.customers AS c
  ON c.customer_id = o.customer_id
ORDER BY o.order_id;
~~~

Mỗi order hợp lệ có đúng một customer nhờ foreign key và key uniqueness.

### 2. Mọi customer và paid order

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    o.order_id
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
 AND o.order_status = 'paid'
ORDER BY c.customer_id, o.order_id;
~~~

Customer không có paid order vẫn xuất hiện với `o.order_id IS NULL`.

### 3. Product chưa từng bán bằng `NOT EXISTS`

~~~sql
SELECT p.product_id, p.product_name
FROM sales.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.order_items AS oi
    WHERE oi.product_id = p.product_id
)
ORDER BY p.product_id;
~~~

### 4. Product chưa từng bán bằng left anti-join

~~~sql
SELECT p.product_id, p.product_name
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi
  ON oi.product_id = p.product_id
WHERE oi.product_id IS NULL
ORDER BY p.product_id;
~~~

Hai query tương đương khi `oi.product_id` là key non-nullable cho mọi matched row. `NOT EXISTS` thường rõ intent hơn và tránh phụ thuộc vào column được chọn để test null.

### 5. Đếm distinct order của từng customer

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    count(DISTINCT o.order_id) AS order_count
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY c.customer_id;
~~~

Left join giữ customer zero order; `COUNT` không đếm `NULL` order id.

### 6. Hợp nhất country code

~~~sql
SELECT country AS country_code
FROM sales.customers
WHERE country IS NOT NULL
UNION
SELECT shipping_country AS country_code
FROM sales.orders
WHERE shipping_country IS NOT NULL
ORDER BY country_code;
~~~

`UNION` trả mỗi code một lần.

### 7. Product active và đã bán

~~~sql
SELECT product_id
FROM sales.products
WHERE active = TRUE
INTERSECT
SELECT product_id
FROM sales.order_items
ORDER BY product_id;
~~~

Cả hai input đều có một column cùng type `BIGINT`.

### 8. Phân tích order_count

Query đang đếm order item, vì mỗi order có thể có nhiều `oi` row. Sửa bằng `count(DISTINCT o.order_id)` nếu metric là số order; hoặc đổi tên thành item line count nếu đó mới là business meaning.

## Level 3 — Engineering

1. Dùng DTO projection cho order/customer summary. Nếu cần 20 order theo customer, lấy parent page bằng query có deterministic order rồi fetch các row cần thiết bằng một query thứ hai hoặc join có kiểm soát. Tránh load collection lazy trong vòng lặp. Đo generated SQL, số round trip và result row count.
2. Đưa status predicate vào `ON`. `WHERE o.order_status = 'paid'` loại row null-extended của customer không có paid order. Test bằng một customer không có paid order.
3. Dùng `UNION ALL` nếu hai nguồn là event stream và duplicate event vẫn là những event khác nhau hoặc đã có unique identity ở mỗi nguồn. Dùng `UNION` chỉ khi duplicate row là cùng một fact và cần deduplicate; đo memory/sort/hash cost.
4. Kiểm tra index trên child join key, statistics freshness, estimated versus actual rows, join algorithm và buffer read. Chỉ thêm index sau khi xác định query shape và workload; index giúp read nhưng tăng write/storage.
5. Dùng `FULL OUTER JOIN` trên business key, thêm status bằng `CASE`: chỉ payment, chỉ order, hoặc match. Với duplicate business key, trước tiên định nghĩa uniqueness hoặc aggregate mỗi phía để reconciliation không nhân row.

## Lời giải debugging

1. Filter ở `WHERE` làm left join chỉ còn customer có paid order. Đưa filter vào `ON` và kiểm tra customer không có paid order.
2. Query đếm child row. Dùng `count(DISTINCT o.order_id)` để đếm order hoặc đổi metric name nếu muốn đếm order item.
3. Nếu subquery có `NULL`, `NOT IN` có thể trả `UNKNOWN`. Dùng `NOT EXISTS` tương quan theo customer id.
4. `UNION` deduplicate những row giống nhau. Dùng `UNION ALL` nếu mỗi source event cần được giữ, hoặc chọn business key/version để deduplicate có chủ đích.
5. Điều kiện cũ dạng comma join không có predicate nối order với product; nó tạo cross join rồi chỉ filter order status. Viết explicit `JOIN ... ON`.

## Các nguyên tắc cần nhớ

- Chọn join type theo row nào phải được giữ, không theo thói quen cú pháp.
- Dùng `COUNT(DISTINCT parent_id)` khi đo parent sau one-to-many join.
- Anti-join là existence question; ưu tiên `NOT EXISTS`.
- Set operators yêu cầu compatible result shape.
- Luôn kiểm tra plan và cardinality thay vì suy luận chỉ từ số index.

## Lời giải bổ sung theo transcript 035–055

### Level 1

9. No JOIN là hai câu SELECT tạo hai result set độc lập. Nó phù hợp khi API có hai collection riêng; nếu cần correlation, dùng join hoặc batch query có chủ đích.
10. Left anti giữ row bên trái không match; right anti giữ row bên phải không match; full anti giữ unmatched ở cả hai phía.
11. Q1 EXCEPT Q2 có hướng nên đổi thứ tự đổi kết quả. INTERSECT là phần giao nên thường không đổi tập row khi đổi thứ tự.
12. Set operator map theo vị trí, nên SQL có thể chạy nhưng ghép sai business column.
13. Alias output lấy từ nhánh đầu; PostgreSQL chọn common type bằng type resolution.

### Level 2

#### 9. Left anti bằng hai cách

~~~sql
SELECT p.product_id, p.product_name
FROM sales.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.order_items AS oi
    WHERE oi.product_id = p.product_id
);

SELECT p.product_id, p.product_name
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi
  ON oi.product_id = p.product_id
WHERE oi.product_id IS NULL;
~~~

#### 10. Full anti

~~~sql
SELECT c.customer_id, o.order_id
FROM sales.customers AS c
FULL OUTER JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
   OR o.order_id IS NULL;
~~~

#### 11–12. Combine và delta

Dùng UNION ALL với explicit columns và source_table khi append current/archive. Dùng day_2 EXCEPT day_1 để lấy record mới theo projection đã chọn. Nếu cần phát hiện update, so sánh thêm payload/version.

#### 13. Multiple-table join

Grain của query orders nối order_items là một row/order item; một order có nhiều item nên order columns lặp. Nếu cần một row/order, aggregate hoặc pre-aggregate order_items.

### Level 3

6. Dùng FULL OUTER JOIN trên business key sau khi bảo đảm mỗi phía tối đa một row/key hoặc đã aggregate. CASE phân loại matched, only_order và only_payment; duplicate key nên đi vào error/quarantine path.
7. Chỉ đổi UNION thành UNION ALL khi duplicate giữa source/partition là event hợp lệ hoặc uniqueness đã được chứng minh. Nếu cần dedup, dedup theo event id/version có chủ đích.
8. Hai phép EXCEPT rỗng chỉ chứng minh hai projection không khác nhau. Có thể vẫn bỏ sót duplicate, column không so sánh, khác chuẩn hóa, snapshot không nhất quán hoặc race trong lúc đọc.
