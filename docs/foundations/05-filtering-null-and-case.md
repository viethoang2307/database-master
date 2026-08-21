# Lesson 5 — Filtering, `NULL` và Three-Valued Logic

## Tổng quan lesson

Khóa học nguồn xem comparison và logical operator như các building block đơn giản. Chi tiết production khó hơn là SQL predicate có ba kết quả logic: `TRUE`, `FALSE` và `UNKNOWN`. `NULL` biểu diễn dữ liệu missing/unknown/not-applicable; nó không phải zero, empty string hay một normal value.

### Mục tiêu học tập

- Dùng comparison, `IN`, `BETWEEN`, `LIKE`, `AND`, `OR` và `NOT` đúng cách.
- Dự đoán `NULL` thay đổi predicate như thế nào.
- Giải thích vì sao `column = NULL` là sai.
- Dùng `IS NULL`, `COALESCE` và `CASE` có chủ đích.
- Nhận diện bẫy `NOT IN` kết hợp với `NULL`.
- Giữ predicate index-friendly khi performance quan trọng.

## Formal model

Với `WHERE` clause, PostgreSQL giữ row khi predicate evaluate thành `TRUE`. Row có predicate là `FALSE` hoặc `UNKNOWN` sẽ bị filter.

~~~text
NULL = 5       -> UNKNOWN
NULL <> 5      -> UNKNOWN
NULL = NULL    -> UNKNOWN
NULL IS NULL   -> TRUE
~~~

### Ví dụ

~~~sql
SELECT customer_id, full_name, country
FROM sales.customers
WHERE country IS NULL;
~~~

Query trả về Farah vì `IS NULL` kiểm tra trực tiếp null marker. `country = NULL` không trả row vì ordinary equality không thể xác định hai unknown value có bằng nhau hay không.

## Operator và edge case

~~~sql
-- Inclusive range; dùng half-open range cho timestamp khi phù hợp.
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-03-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-04-01 00:00:00+07';

-- Pattern matching; leading wildcard có thể ngăn b-tree prefix use thông thường.
SELECT product_id, product_name
FROM sales.products
WHERE product_name ILIKE 'wire%';

-- Fallback rõ ràng cho display; không giả vờ rằng dữ liệu thiếu đã tồn tại.
SELECT full_name, COALESCE(country, 'unknown') AS display_country
FROM sales.customers;

-- Phân loại value nhưng vẫn giữ amount gốc.
SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price >= 200 THEN 'premium'
        WHEN unit_price >= 50 THEN 'standard'
        ELSE 'entry'
    END AS price_band
FROM sales.products;
~~~

## Bẫy `NOT IN`

Nếu right-hand set chứa `NULL`, `x NOT IN (...)` có thể evaluate thành `UNKNOWN` với value không bằng bất kỳ member đã biết nào. Khi subquery có thể chứa null và ý định là anti-membership, ưu tiên `NOT EXISTS`.

~~~sql
-- Dạng anti-membership robust.
SELECT c.customer_id, c.full_name
FROM sales.customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.orders AS o
    WHERE o.customer_id = c.customer_id
);
~~~

## Hành vi bên trong và performance

Planner có thể dùng statistics để estimate predicate selectivity. Predicate đơn giản trên indexed column thường hữu ích hơn việc apply function lên mọi row:

~~~sql
-- Thường index-friendly hơn với timestamp range:
WHERE ordered_at >= :start_at AND ordered_at < :end_at

-- Có thể cần expression index hoặc nhiều work hơn:
WHERE date(ordered_at) = :target_date
~~~

Đây không phải quy luật tuyệt đối; hãy inspect `EXPLAIN`. `LIKE 'wire%'` có prefix có thể indexable dưới collation/operator-class phù hợp, trong khi `LIKE '%wire%'` thường cần search strategy khác, chẳng hạn trigram indexing, khi workload lớn.

## Góc nhìn Backend

Hãy quyết định missing value có nghĩa là unknown, not applicable hay not yet collected. Policy này ảnh hưởng API serialization, filter, reporting và uniqueness. Đừng âm thầm đổi mọi `NULL` thành empty string chỉ để JSON dễ xử lý hơn.

Khi tạo optional filter, dùng parameterized predicate và query shape có chủ đích. Query dạng `WHERE (:country IS NULL OR country = :country)` tiện dụng nhưng có thể làm selectivity và planning phức tạp; hãy đo trong endpoint volume cao.

## Hiểu lầm thường gặp

- `NULL` không giống `0`, `''` hay `FALSE`.
- `BETWEEN` inclusive ở cả hai đầu; timestamp reporting thường an toàn hơn với range `[start, end)`.
- `CASE` là expression trả về value; nó không phải general procedural `if` block.
- `COALESCE` không phải data repair; nó chỉ thay đổi kết quả của expression.

## Lab thực hành

1. Chạy các query trong `sql/foundations/01_querying_sales.sql`.
2. Dự đoán kết quả của `WHERE country = NULL`, sau đó thay bằng `IS NULL`.
3. Tạo temporary values table gồm `(1), (2), (NULL)` và so sánh `NOT IN` với `NOT EXISTS`.
4. Chạy `EXPLAIN` cho timestamp range và cho `date(ordered_at) = ...`; giải thích khác biệt nếu có, nhưng không giả định plan bắt buộc phải khác trên demo table nhỏ.

## Câu hỏi phỏng vấn

1. **Junior — Vì sao `column = NULL` không hoạt động?** Equality với unknown value cho kết quả `UNKNOWN`; `IS NULL` mới là null test.
2. **Junior — Row nào pass `WHERE`?** Chỉ row có predicate evaluate thành `TRUE`; `FALSE` và `UNKNOWN` bị loại.
3. **Mid — Vì sao `NOT IN` có thể cho kết quả bất ngờ?** `NULL` trong compared set có thể làm result thành `UNKNOWN`; `NOT EXISTS` biểu đạt anti-membership robust hơn.
4. **Mid — `BETWEEN` có inclusive không?** Có, ở cả hai endpoint; với timestamp liền kề, explicit half-open range thường an toàn hơn.
5. **Senior — Vì sao bọc indexed column trong function có thể làm performance kém?** Normal index được sắp theo stored expression, không nhất thiết theo function result; planner có thể không dùng được nó nếu không có expression index hoặc rewrite.

## Tài liệu tham khảo

- [PostgreSQL Comparison Functions and Operators](https://www.postgresql.org/docs/current/functions-comparison.html)
- [PostgreSQL Conditional Expressions](https://www.postgresql.org/docs/current/functions-conditional.html)
- [PostgreSQL Pattern Matching](https://www.postgresql.org/docs/current/functions-matching.html)
- [PostgreSQL Indexes on Expressions](https://www.postgresql.org/docs/current/indexes-expressional.html)
