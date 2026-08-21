# Bài tập Querying Sprint — JOIN và set operators

Đừng mở file solution trước khi bạn ghi prediction, result shape và reasoning.

## Level 1 — Nhớ và giải thích

1. Phân biệt inner join, left join và cross join.
2. Vì sao one-to-many join có thể làm số row tăng?
3. Khi nào filter nên nằm trong `ON` thay vì `WHERE`?
4. Anti-join là gì? Viết hai cách biểu đạt nó.
5. Vì sao `NOT EXISTS` thường an toàn hơn `NOT IN` khi có nullable data?
6. So sánh `UNION` và `UNION ALL`.
7. Set operators yêu cầu hai query input có những đặc điểm gì?
8. Nêu ba join algorithm và tình huống planner có thể chọn mỗi loại.

## Level 2 — Áp dụng

1. Viết query trả về order id, customer name và order status cho mọi order.
2. Viết query trả về mọi customer, kể cả customer chưa có order; chỉ match paid order nhưng vẫn giữ customer không có paid order.
3. Viết query trả về product chưa từng xuất hiện trong `sales.order_items` bằng `NOT EXISTS`.
4. Viết lại bài 3 bằng `LEFT JOIN ... IS NULL`. Nêu điều kiện để hai query tương đương.
5. Viết query đếm số order distinct của mỗi customer, bao gồm customer có zero order.
6. Hợp nhất country code từ customer country và order shipping country, loại duplicate.
7. Tìm product vừa active vừa đã được bán bằng `INTERSECT`.
8. Phân tích query sau: metric tên `order_count` có thực sự đếm order không?

   ~~~sql
   SELECT c.customer_id, count(*) AS order_count
   FROM sales.customers AS c
   JOIN sales.orders AS o ON o.customer_id = c.customer_id
   JOIN sales.order_items AS oi ON oi.order_id = o.order_id
   GROUP BY c.customer_id;
   ~~~

## Level 3 — Engineering

1. API hiển thị customer và 20 order gần nhất. Thiết kế query shape để không load toàn bộ entity graph và không tạo N+1 query.
2. Một report dùng `LEFT JOIN` nhưng customer không có order biến mất sau khi thêm filter status. Chẩn đoán và sửa.
3. Một bảng event lớn được append từ hai nguồn. Quyết định giữa `UNION` và `UNION ALL`; nêu invariant cần có.
4. Query anti-join chạy chậm trên 200 triệu order. Nêu index, statistics, cardinality và plan evidence cần kiểm tra.
5. Reconciliation giữa hệ thống payment và order phải thấy record chỉ có ở payment, chỉ có ở order và record match. Chọn join type và thiết kế result.

## Debugging challenges

Với mỗi scenario, nêu vấn đề, nguyên nhân, cách sửa và cách kiểm chứng.

### Challenge 1 — Filter làm mất parent

~~~sql
SELECT c.customer_id, c.full_name, o.order_id
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
WHERE o.order_status = 'paid';
~~~

### Challenge 2 — Đếm sai sau one-to-many join

~~~sql
SELECT count(*) AS orders
FROM sales.orders AS o
JOIN sales.order_items AS oi ON oi.order_id = o.order_id;
~~~

### Challenge 3 — Anti-join với NULL

~~~sql
SELECT c.customer_id
FROM sales.customers AS c
WHERE c.customer_id NOT IN (
    SELECT o.customer_id
    FROM sales.orders AS o
);
~~~

### Challenge 4 — UNION làm mất dữ liệu

~~~sql
SELECT event_id, event_type FROM app_events
UNION
SELECT event_id, event_type FROM imported_events;
~~~

### Challenge 5 — Cross join ngoài ý muốn

~~~sql
SELECT o.order_id, p.product_id
FROM sales.orders AS o, sales.products AS p
WHERE o.order_status = 'paid';
~~~

## Bài cần nộp

Với mỗi bài Level 2, ghi query và expected result shape. Với Level 3, ghi invariant, cardinality giả định, transaction/API boundary, index hoặc plan evidence cần kiểm tra và trade-off.
