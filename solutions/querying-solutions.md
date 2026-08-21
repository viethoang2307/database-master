# Lời giải Querying Sprint — JOIN và set operators

Đây là model solution. Khi workload, invariant hoặc schema khác, design có thể thay đổi nếu trade-off được giải thích.

## Level 1 — Nhớ và giải thích

1. Inner join chỉ giữ cặp có match; left join giữ toàn bộ row bên trái và điền §NULL§ cho phía phải không match; cross join tạo mọi combination.
2. Nếu một parent có nhiều child, mỗi child tạo một result row kết hợp với parent; một parent có k child xuất hiện k lần.
3. Filter trong §ON§ giới hạn row được match ở phía phải nhưng vẫn giữ row bên trái của outer join. Filter trong §WHERE§ chạy sau đó và có thể loại null-extended row.
4. Anti-join lấy row không có match. Có thể dùng §NOT EXISTS§ hoặc §LEFT JOIN ... IS NULL§ với một non-nullable key phía phải.
5. §NULL§ trong subquery làm §NOT IN§ có thể evaluate thành §UNKNOWN§. §NOT EXISTS§ kiểm tra relationship trực tiếp.
6. §UNION§ loại duplicate; §UNION ALL§ giữ duplicate và thường tránh chi phí distinct.
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

Customer không có paid order vẫn xuất hiện với §o.order_id IS NULL§.

### 3. Product chưa từng bán bằng §NOT EXISTS§

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

Hai query tương đương khi §oi.product_id§ là key non-nullable cho mọi matched row. §NOT EXISTS§ thường rõ intent hơn và tránh phụ thuộc vào column được chọn để test null.

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

Left join giữ customer zero order; §COUNT§ không đếm §NULL§ order id.

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

§UNION§ trả mỗi code một lần.

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

Cả hai input đều có một column cùng type §BIGINT§.

### 8. Phân tích order_count

Query đang đếm order item, vì mỗi order có thể có nhiều §oi§ row. Sửa bằng §count(DISTINCT o.order_id)§ nếu metric là số order; hoặc đổi tên thành item line count nếu đó mới là business meaning.

## Level 3 — Engineering

1. Dùng DTO projection cho order/customer summary. Nếu cần 20 order theo customer, lấy parent page bằng query có deterministic order rồi fetch các row cần thiết bằng một query thứ hai hoặc join có kiểm soát. Tránh load collection lazy trong vòng lặp. Đo generated SQL, số round trip và result row count.
2. Đưa status predicate vào §ON§. §WHERE o.order_status = 'paid'§ loại row null-extended của customer không có paid order. Test bằng một customer không có paid order.
3. Dùng §UNION ALL§ nếu hai nguồn là event stream và duplicate event vẫn là những event khác nhau hoặc đã có unique identity ở mỗi nguồn. Dùng §UNION§ chỉ khi duplicate row là cùng một fact và cần deduplicate; đo memory/sort/hash cost.
4. Kiểm tra index trên child join key, statistics freshness, estimated versus actual rows, join algorithm và buffer read. Chỉ thêm index sau khi xác định query shape và workload; index giúp read nhưng tăng write/storage.
5. Dùng §FULL OUTER JOIN§ trên business key, thêm status bằng §CASE§: chỉ payment, chỉ order, hoặc match. Với duplicate business key, trước tiên định nghĩa uniqueness hoặc aggregate mỗi phía để reconciliation không nhân row.

## Lời giải debugging

1. Filter ở §WHERE§ làm left join chỉ còn customer có paid order. Đưa filter vào §ON§ và kiểm tra customer không có paid order.
2. Query đếm child row. Dùng §count(DISTINCT o.order_id)§ để đếm order hoặc đổi metric name nếu muốn đếm order item.
3. Nếu subquery có §NULL§, §NOT IN§ có thể trả §UNKNOWN§. Dùng §NOT EXISTS§ tương quan theo customer id.
4. §UNION§ deduplicate những row giống nhau. Dùng §UNION ALL§ nếu mỗi source event cần được giữ, hoặc chọn business key/version để deduplicate có chủ đích.
5. Điều kiện cũ dạng comma join không có predicate nối order với product; nó tạo cross join rồi chỉ filter order status. Viết explicit §JOIN ... ON§.

## Các nguyên tắc cần nhớ

- Chọn join type theo row nào phải được giữ, không theo thói quen cú pháp.
- Dùng §COUNT(DISTINCT parent_id)§ khi đo parent sau one-to-many join.
- Anti-join là existence question; ưu tiên §NOT EXISTS§.
- Set operators yêu cầu compatible result shape.
- Luôn kiểm tra plan và cardinality thay vì suy luận chỉ từ số index.
