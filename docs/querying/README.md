# Querying Sprint

## Phạm vi

Querying Sprint mở rộng nền tảng SQL bằng cách kết hợp nhiều relation, biến đổi dữ liệu và đọc query plan. Lesson 1 tập trung vào JOIN, anti-join và set operators. Lesson 2 tập trung vào data transformation và string functions; các lesson sau sẽ bổ sung numeric/date functions, NULL/CASE, aggregates, window functions và query nâng cao.

## Mục tiêu học tập

Sau sprint này, bạn có thể:

- Chọn đúng loại join cho câu hỏi business.
- Giải thích vì sao một join có thể làm tăng số row.
- Phân biệt điều kiện match trong ON với filter trong WHERE.
- Viết inner join, outer join và anti-join bằng NOT EXISTS hoặc LEFT JOIN ... IS NULL.
- Chọn giữa UNION và UNION ALL, đồng thời hiểu chi phí loại duplicate.
- Dùng CONCAT, CONCAT_WS, UPPER, LOWER, TRIM, REPLACE, length, LEFT, RIGHT và SUBSTRING trong PostgreSQL.
- Phân biệt display transformation, canonicalization và data repair.
- Nhận diện NULL, whitespace, character length và byte length trong data-quality query.
- Kiểm tra tác động của function predicate bằng EXPLAIN và expression index.
- Tránh N+1 query và kiểm soát số row mà ORM materialize.

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
     +--> Numeric/date functions
     +--> NULL / CASE
~~~

## Lesson

1. [JOIN, anti-join và set operators](01-joins-and-set-operators.md)
2. [Data transformation và string functions](02-string-functions-and-data-transformation.md)
3. Numeric, date/time functions và casting - đang lên kế hoạch
4. NULL, CASE và conditional transformation - foundation đã có, sẽ mở rộng theo transcript

## Dữ liệu dùng chung

Chạy bootstrap ở root trước. Lesson JOIN dùng các relation sales.customers, sales.orders, sales.order_items và sales.products. Lesson string functions dùng sales.customers và có temp-table lab độc lập. Seed data deterministic giúp expected result có thể kiểm tra lặp lại.

## Thực hành

- [Bài tập JOIN và set operators](../../exercises/querying-exercises.md)
- [Lời giải JOIN và set operators](../../solutions/querying-solutions.md)
- [SQL lab: JOIN và set operators](../../sql/querying/01_joins_and_sets.sql)
- [Bài tập string functions](../../exercises/string-functions-exercises.md)
- [Lời giải string functions](../../solutions/string-functions-solutions.md)
- [SQL lab: string functions](../../sql/querying/02_string_functions.sql)
- [Knowledge check JOIN và set operators](knowledge-check.md)
- [Knowledge check string functions](knowledge-check-strings.md)
- [Đáp án knowledge check string functions](knowledge-check-strings-answers.md)

## Đối chiếu transcript

Lesson 1 được xây dựng từ transcript 035-055:

- 035-036: mental model JOIN/set operator và No JOIN.
- 037-046: INNER, LEFT, RIGHT, FULL, anti-join, CROSS JOIN, cách chọn JOIN và multiple-table JOIN.
- 047-055: rules, UNION, UNION ALL, EXCEPT, INTERSECT, combine information và delta detection.

Lesson 2 được xây dựng từ transcript 056-064:

- 056-057: data transformation và phân loại SQL functions.
- 058-061: CONCAT, UPPER, LOWER, TRIM và REPLACE.
- 062-064: length/LEN, LEFT, RIGHT và SUBSTRING.

Ví dụ SQL Server trong transcript được chuyển sang PostgreSQL nhưng giữ nguyên câu hỏi business và result shape. Những khác biệt vendor như PostgreSQL length so với SQL Server LEN, hoặc CONCAT và toán tử nối chuỗi, đều được ghi rõ trong lesson.
