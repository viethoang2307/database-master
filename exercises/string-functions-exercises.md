# Bài tập - String Functions và Data Transformation

> PostgreSQL là hệ chính của sprint. Hãy chạy các bài SQL trên dữ liệu lab hoặc schema sales trong bootstrap. Với bài thiết kế, câu trả lời cần nêu rõ giả định, trade-off và cách kiểm chứng.

## Level 1 - Recall

1. Data transformation trong một câu SELECT có sửa dữ liệu gốc không?
2. Scalar function khác aggregate function ở shape output như thế nào?
3. Window function khác aggregate function ở điểm nào?
4. Trong PostgreSQL, CONCAT_WS dùng tham số nào làm separator?
5. TRIM mặc định xử lý vùng nào của text?
6. Phân biệt chuỗi rỗng với NULL.
7. length/char_length và octet_length đo những đại lượng nào?
8. Vị trí bắt đầu của PostgreSQL SUBSTRING là bao nhiêu?
9. REPLACE thay thế một occurrence hay tất cả occurrence?
10. Vì sao function bọc quanh column có thể ảnh hưởng ordinary index?

## Level 2 - Apply

### Bài 2.1 - Display label

Dùng sales.customers để tạo các cột:

- customer_id
- raw_name
- clean_name
- display_label dạng tên và country, ngăn bằng " / "
- không biến đổi table

Yêu cầu: country NULL không tạo label có separator thừa.

### Bài 2.2 - Data-quality audit

Viết query tìm customer có leading hoặc trailing space trong full_name. Trả về raw value, proposed value, raw character count, cleaned character count và cờ has_edge_whitespace.

Hãy nói thêm NULL sẽ được xử lý thế nào.

### Bài 2.3 - Prefix, suffix, substring

Viết query lấy 3 ký tự đầu, 3 ký tự cuối và phần tên bỏ ký tự đầu tiên. Tất cả phải thao tác trên full_name đã btrim. Sắp xếp theo customer_id.

### Bài 2.4 - Lookup key

Tạo normalized_email bằng lower và btrim. Chỉ lấy email khác NULL. Viết thêm predicate tìm một input parameter đã normalize.

### Bài 2.5 - Character và byte limit

Tạo một CTE có các giá trị Maria, abc có hai trailing spaces và Café. Trả về value, char_length và octet_length. Nêu metric nào dùng cho UI, metric nào dùng cho byte limit.

### Bài 2.6 - Dự đoán NULL

Không chạy trước, dự đoán kết quả của query sau khi country là NULL:

~~~sql
SELECT
    concat('Name', ' - ', country),
    concat_ws(' - ', 'Name', country),
    'Name' || ' - ' || country;
~~~

Sau đó chạy trong PostgreSQL và giải thích.

### Bài 2.7 - Preview phone transformation

Từ sales.customers, tạo phone_without_dashes bằng replace chỉ để preview. Không UPDATE. Nêu vì sao replace chưa phải validation số điện thoại.

### Bài 2.8 - Sửa SUBSTRING

Sửa query sau để lấy toàn bộ chuỗi sau ký tự đầu tiên, không hard-code count cố định:

~~~sql
SELECT substring(btrim(full_name) FROM 2 FOR 5)
FROM sales.customers;
~~~

## Level 3 - Engineering

### Bài 3.1 - Login trên bảng lớn

Login đang chạy:

~~~sql
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = lower(btrim(:input));
~~~

Bảng có 100 triệu row và request latency tăng. Đề xuất:

1. canonicalization policy;
2. normalized column hoặc expression index;
3. uniqueness policy;
4. cách dùng EXPLAIN và telemetry để xác minh;
5. kế hoạch rollout và rollback.

Không được trả lời đơn giản là "thêm index".

### Bài 3.2 - Batch data repair

Team muốn chạy UPDATE trim(full_name) trong mỗi HTTP request để dữ liệu luôn sạch. Phân tích vấn đề về latency, lock, audit, retry và race condition. Thiết kế một batch repair an toàn.

### Bài 3.3 - Replace gây sửa nhầm

Product name có thể chứa từ "pro", nhưng team muốn replace mọi "pro" thành "premium". Hãy thiết kế preview query, predicate giới hạn, sample review, migration idempotency và cách bảo vệ raw value.

### Bài 3.4 - Hai loại giới hạn

External API giới hạn 256 bytes; giao diện giới hạn 100 characters; dữ liệu có Unicode. Chọn hàm/validation cho mỗi boundary và giải thích vì sao không dùng một metric cho cả hai.

### Bài 3.5 - ORM query chậm

Hibernate sinh lower(trim(email)) trong WHERE. Code đúng về business nhưng query chậm. Lập checklist từ SQL generated, bind parameter, index expression, selectivity, statistics, EXPLAIN đến connection pool.

### Bài 3.6 - Migration SQL Server sang PostgreSQL

Một test cũ dùng LEN(value) để kiểm tra trailing spaces. Viết bộ test regression cho NULL, chuỗi rỗng, "abc  ", Unicode và chuỗi ngắn. Nêu thay thế PostgreSQL phù hợp.

## Debugging Challenges

### Challenge 1 - Mất index

~~~sql
SELECT customer_id
FROM sales.customers
WHERE trim(lower(email)) = :input;
~~~

Nêu các vấn đề có thể có về input normalization, NULL, expression index và data contract. Đề xuất query/index policy.

### Challenge 2 - Label thành NULL

~~~sql
SELECT full_name || ', ' || country AS customer_label
FROM sales.customers;
~~~

Giải thích khi country NULL. Đưa ra hai cách sửa với hai semantics khác nhau.

### Challenge 3 - UPDATE thiếu kiểm soát

~~~sql
UPDATE sales.customers
SET full_name = trim(full_name);
~~~

Viết quy trình preview, transaction, audit và điều kiện WHERE trước khi cho phép COMMIT.

### Challenge 4 - Predicate khó tối ưu

~~~sql
SELECT left(full_name, 2), length(full_name)
FROM sales.customers
WHERE length(full_name) > 0;
~~~

Tìm vấn đề về NULL, whitespace, Unicode, ý nghĩa prefix và performance. Đề xuất phiên bản rõ ràng hơn cho business.

## Yêu cầu tự đánh giá

Trước khi xem lời giải, hãy ghi:

- dự đoán output;
- giả định về NULL và whitespace;
- access path bạn mong đợi;
- test hoặc EXPLAIN dùng để kiểm chứng;
- quyết định nào là vendor-specific.
