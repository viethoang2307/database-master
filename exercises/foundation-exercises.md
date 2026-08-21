# Bài tập Sprint nền tảng

Đừng mở file solution cho đến khi bạn đã viết ra prediction và reasoning của mình.

## Level 1 — Nhớ và giải thích

1. Giải thích khác nhau giữa PostgreSQL server, database, schema và table.
2. DBMS cung cấp vai trò nào mà một CSV file thuần túy không có?
3. Định nghĩa projection, predicate, ordering và pagination.
4. Vì sao cần `ORDER BY` để có top-N result xác định?
5. Kể tên bốn constraint trong `sales` schema và nêu invariant mỗi constraint bảo vệ.
6. So sánh `DELETE`, `TRUNCATE` và `DROP TABLE`.
7. `COMMIT` làm gì, và `ROLLBACK` làm gì?
8. Vì sao `NULL` khác empty string?

## Level 2 — Áp dụng

1. Viết query trả về các active product có giá từ 50 đến 150 inclusive, order theo price giảm dần và product id tăng dần.
2. Viết query trả về năm order mới nhất của customer `8`, có tie-breaker xác định.
3. Tính total của mỗi order từ `sales.order_items`, áp dụng `discount_pct` và round đến hai chữ số thập phân.
4. Trả về mọi customer chưa từng đặt order. Dùng `NOT EXISTS`.
5. Tạo table `lab.shipment_events` có identity primary key, foreign key đến order, non-null event type chỉ nhận `created`, `packed` hoặc `shipped`, cùng event timestamp.
6. Insert một shipment event hai lần một cách an toàn để lần chạy thứ hai không tạo duplicate cho cùng order và event type. Nêu unique constraint cần có.
7. Viết transaction insert order item rồi đánh dấu order là `paid`. Giải thích phải xảy ra điều gì nếu statement thứ hai fail.
8. Dự đoán mỗi predicate trả về `TRUE`, `FALSE` hay `UNKNOWN` với `country = NULL`, rồi verify:

   ~~~sql
   SELECT
       NULL = NULL AS equality,
       NULL IS NULL AS is_null,
       NULL <> 'VN' AS inequality;
   ~~~

## Level 3 — Engineering

1. Order-placement endpoint hiện làm `SELECT stock`, validate trong Java, rồi `UPDATE stock`. Giải thích race condition và đề xuất write strategy an toàn trong PostgreSQL.
2. Report endpoint dùng `OFFSET 100000 LIMIT 50` trên table 200 triệu row. Thiết kế keyset pagination query và xác định ordering/index shape cần thiết.
3. Một migration thêm column `NOT NULL` có default vào table đang nhận 5.000 write mỗi giây. Mô tả safe rollout sequence và những metric cần đo.
4. Service validate email uniqueness trước khi insert nhưng production vẫn xuất hiện duplicate-email error. Giải thích vì sao và database rule nào phải tồn tại.
5. Developer thay mọi `NULL` country bằng string `unknown` trong ingestion. Thảo luận cách thay đổi này ảnh hưởng filtering, analytics và quyết định data quality tương lai.

## Debugging challenges

Với mỗi scenario, hãy nêu vấn đề, nguyên nhân và cách sửa.

### Challenge 1 — Pagination không ổn định

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
ORDER BY ordered_at DESC
LIMIT 20 OFFSET 20;
~~~

### Challenge 2 — So sánh null

~~~sql
SELECT customer_id, full_name
FROM sales.customers
WHERE country = NULL;
~~~

### Challenge 3 — Race trong check-then-insert

~~~text
if repository.findByEmail(email) is empty:
    repository.insert(user)
~~~

### Challenge 4 — Business operation bị partial

~~~text
insert order       // autocommit
insert order items // fails
~~~

### Challenge 5 — Bulk update nguy hiểm

~~~sql
UPDATE sales.orders
SET order_status = 'cancelled';
~~~

## Bài cần nộp

Lưu câu trả lời thành một personal note. Với SQL ở Level 2, ghi query và một câu giải thích expected result. Với Level 3, phải nêu invariant, transaction boundary, failure behavior và observability plan.
