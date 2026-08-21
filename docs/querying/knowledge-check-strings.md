# Knowledge Check - String Functions và Data Transformation

Hãy trả lời trước khi mở file đáp án. Các câu SQL giả định PostgreSQL.

## Multiple choice

1. Câu nào tạo display label và bỏ qua country NULL một cách phù hợp?
   - A. full_name || ' / ' || country
   - B. concat_ws(' / ', full_name, country)
   - C. replace(full_name, country, '')
   - D. octet_length(full_name)

2. Hàm nào đếm byte của text trong PostgreSQL?
   - A. length
   - B. char_length
   - C. octet_length
   - D. substring

3. Expression nào lấy phần còn lại sau ký tự đầu tiên?
   - A. substring(value FROM 0)
   - B. substring(value FROM 1 FOR 1)
   - C. substring(value FROM 2)
   - D. right(value, 1)

4. Khi predicate là lower(btrim(email)) = :key, index nào có khả năng khớp trực tiếp hơn?
   - A. Index trên customer_id
   - B. Index trên email raw
   - C. Expression index trên lower(btrim(email))
   - D. Không có index nào trong mọi trường hợp

5. Hàm nào thuộc nhóm aggregate?
   - A. lower
   - B. replace
   - C. sum
   - D. substring

## True / False

6. SELECT lower(email) sẽ ghi email đã lower vào table.
7. TRIM mặc định xóa toàn bộ whitespace ở cả bên trong chuỗi.
8. Chuỗi rỗng và NULL là cùng một giá trị trong SQL.
9. PostgreSQL SUBSTRING dùng vị trí bắt đầu 1-based.
10. EXPLAIN ANALYZE thực thi statement được phân tích.

## Short answer

11. Vì sao cần trim trước khi dùng LEFT(full_name, 2) nếu dữ liệu có leading spaces?
12. Khi nào char_length phù hợp hơn octet_length?
13. Vì sao replace không đủ để validate số điện thoại?
14. Nêu hai trade-off của expression index.
15. Phân biệt presentation transformation và canonicalization.

## Predict the output / explain why

16. Với country = NULL trong PostgreSQL, mô tả kết quả của ba expression:

~~~sql
concat('Name', ' - ', country)
concat_ws(' - ', 'Name', country)
'Name' || ' - ' || country
~~~

17. Với value = 'abc  ', so sánh ý nghĩa của PostgreSQL length(value) với SQL Server LEN(value). Không cần nhớ số nếu chưa kiểm tra docs; hãy nói điểm khác nhau cần test.

18. Với raw_name = ' John ', dự đoán sự khác nhau giữa:

~~~sql
left(raw_name, 2)
left(btrim(raw_name), 2)
~~~

## Query analysis

19. Query sau có thể có vấn đề hiệu năng gì? Đề xuất ít nhất hai hướng điều tra/sửa.

~~~sql
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = lower(btrim(:input));
~~~

20. Query sau có thể làm mất customer nào và vì sao?

~~~sql
SELECT customer_id, full_name
FROM sales.customers
WHERE full_name <> btrim(full_name);
~~~

Nêu cách audit NULL riêng.
