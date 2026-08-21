# Querying Sprint

## Phạm vi

Querying Sprint mở rộng nền tảng SQL bằng cách kết hợp nhiều relation, biến đổi dữ liệu, hàm ngày giờ và đọc query plan. Lesson 1 tập trung vào JOIN và set operators. Lesson 2 tập trung vào string functions. Lesson 3 tập trung vào numeric, date/time, timezone, formatting, casting và validation. Các lesson sau sẽ bổ sung NULL/CASE, aggregate, window functions và query nâng cao.

## Mục tiêu học tập

Sau sprint này, bạn có thể:

- Chọn đúng loại join cho câu hỏi business.
- Giải thích vì sao một join có thể làm tăng số row.
- Phân biệt điều kiện match trong ON với filter trong WHERE.
- Viết inner join, outer join và anti-join.
- Chọn giữa UNION và UNION ALL, đồng thời hiểu chi phí loại duplicate.
- Dùng CONCAT, CONCAT_WS, UPPER, LOWER, TRIM, REPLACE, length, LEFT, RIGHT và SUBSTRING.
- Dùng round, abs, extract, date_trunc, to_char, CAST và interval trong PostgreSQL.
- Phân biệt date, timestamp without time zone và timestamptz.
- Chọn timezone nghiệp vụ trước khi extract hoặc group date/time.
- Viết predicate half-open có cơ hội dùng index.
- Nhận diện khác biệt SQL Server/PostgreSQL của DATEPART, DATENAME, DATETRUNC, EOMONTH, FORMAT, CONVERT, DATEADD, DATEDIFF và ISDATE.
- Kiểm tra tác động của function predicate bằng EXPLAIN.
- Tránh N+1 query, sai business date và sai duration trong backend/ORM.

## Bản đồ module

~~~text
Một relation
     |
     v
JOIN nhiều relation
     |
     +--> INNER JOIN: chỉ row match
     +--> LEFT JOIN: giữ toàn bộ row bên trái
     +--> ANTI-JOIN: row không có match
     |
     v
Set operators
     |
     +--> UNION / UNION ALL
     +--> INTERSECT
     +--> EXCEPT
     |
     v
Data transformation
     |
     +--> String functions
     +--> Numeric/date/time functions
     +--> Formatting / casting
     +--> NULL / CASE
~~~

## Lesson

1. [JOIN, anti-join và set operators](01-joins-and-set-operators.md)
2. [Data transformation và string functions](02-string-functions-and-data-transformation.md)
3. [Numeric, date/time, formatting và casting](03-number-date-time-and-casting.md)
4. NULL, CASE và conditional transformation - foundation đã có, sẽ mở rộng theo transcript

## Dữ liệu dùng chung

Chạy bootstrap ở root trước. Các lesson dùng sales.customers, sales.orders, sales.order_items và sales.products. Cột thời điểm trong schema là sales.orders.ordered_at, kiểu timestamptz; transcript dùng các tên khác như order_date hoặc creation_time nên lesson ghi rõ mapping. Seed data deterministic giúp expected result có thể kiểm tra lặp lại.

## Thực hành

- [Bài tập JOIN và set operators](../../exercises/querying-exercises.md)
- [Lời giải JOIN và set operators](../../solutions/querying-solutions.md)
- [SQL lab: JOIN và set operators](../../sql/querying/01_joins_and_sets.sql)
- [Bài tập string functions](../../exercises/string-functions-exercises.md)
- [Lời giải string functions](../../solutions/string-functions-solutions.md)
- [SQL lab: string functions](../../sql/querying/02_string_functions.sql)
- [Bài tập numeric/date/time/casting](../../exercises/number-date-time-exercises.md)
- [Lời giải numeric/date/time/casting](../../solutions/number-date-time-solutions.md)
- [SQL lab: numeric/date/time/casting](../../sql/querying/03_number_date_time.sql)
- [Knowledge check JOIN và set operators](knowledge-check.md)
- [Knowledge check string functions](knowledge-check-strings.md)
- [Đáp án knowledge check string functions](knowledge-check-strings-answers.md)
- [Knowledge check numeric/date/time/casting](knowledge-check-number-date-time.md)
- [Đáp án knowledge check numeric/date/time/casting](knowledge-check-number-date-time-answers.md)

## Đối chiếu transcript

Lesson 1 được xây dựng từ transcript 035-055:

- 035-036: mental model JOIN/set operator và No JOIN.
- 037-046: INNER, LEFT, RIGHT, FULL, anti-join, CROSS JOIN, cách chọn JOIN và multiple-table JOIN.
- 047-055: rules, UNION, UNION ALL, EXCEPT, INTERSECT, combine information và delta detection.

Lesson 2 được xây dựng từ transcript 056-064:

- 056-057: data transformation và phân loại SQL functions.
- 058-061: CONCAT, UPPER, LOWER, TRIM và REPLACE.
- 062-064: length/LEN, LEFT, RIGHT và SUBSTRING.

Lesson 3 được xây dựng từ transcript 065-082:

- 065: ROUND, ABS và chính sách làm tròn.
- 066-074: date/time type, timezone, DAY/MONTH/YEAR, DATEPART, DATENAME, DATETRUNC, EOMONTH và date extraction.
- 075-078: formatting, FORMAT, CONVERT và CAST.
- 079-081: DATEADD, DATEDIFF và validation tương đương ISDATE.
- 082: summary, lab, exercises và connections.

Ví dụ SQL Server trong transcript được chuyển sang PostgreSQL nhưng giữ nguyên câu hỏi business và result shape. Những khác biệt vendor như PostgreSQL date_trunc/to_char, SQL Server DATEDIFF boundary semantics và ISDATE đều được ghi rõ trong lesson.
