# Querying Sprint

## Phạm vi

Querying Sprint mở rộng nền tảng SQL bằng cách kết hợp nhiều relation trong một result set. Lesson đầu tiên tập trung vào `JOIN`, anti-join và set operators; các lesson sau sẽ bổ sung functions, aggregates, window functions và query nâng cao.

## Mục tiêu học tập

Sau sprint này, bạn có thể:

- Chọn đúng loại join cho câu hỏi business.
- Giải thích vì sao một join có thể làm tăng số row.
- Phân biệt điều kiện match trong `ON` với filter trong `WHERE`.
- Viết inner join, outer join và anti-join bằng cả `NOT EXISTS` và `LEFT JOIN ... IS NULL`.
- Chọn giữa `UNION` và `UNION ALL`, đồng thời hiểu chi phí loại duplicate.
- Kiểm tra join bằng execution plan và nhận diện cardinality estimate sai.
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
~~~

## Lesson

1. [JOIN, anti-join và set operators](01-joins-and-set-operators.md)
2. [Knowledge check](knowledge-check.md)

## Dữ liệu dùng chung

Chạy bootstrap ở root trước. Lesson dùng các relation `sales.customers`, `sales.orders`, `sales.order_items` và `sales.products`. Seed data deterministic giúp expected result có thể kiểm tra lặp lại.

## Thực hành

- [Bài tập Querying Sprint](../../exercises/querying-exercises.md)
- [Lời giải Querying Sprint](../../solutions/querying-solutions.md)
- [SQL lab: JOIN và set operators](../../sql/querying/01_joins_and_sets.sql)

## Đối chiếu transcript

Lesson đầu tiên được xây dựng từ transcript **035–055**:

- 035–036: mental model JOIN/set operator và No JOIN.
- 037–046: INNER, LEFT, RIGHT, FULL, anti-join, CROSS JOIN, cách chọn JOIN và multiple-table join.
- 047–055: rules, UNION, UNION ALL, EXCEPT, INTERSECT, combine information và delta detection.

Ví dụ SQL Server trong transcript được chuyển sang PostgreSQL nhưng giữ nguyên câu hỏi business và result shape.
