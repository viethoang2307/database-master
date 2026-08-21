# Sprint nền tảng

## Tổng quan lesson

Sprint này xây dựng mental model cần có trước khi dùng ORM hoặc framework. Người học đi từ cách hiểu “database lưu dữ liệu” đến mô hình chính xác hơn: một PostgreSQL server nhận SQL, parse câu lệnh, lập execution strategy, thực thi trên relations và indexes, enforce constraints, đồng thời điều phối các transaction chạy đồng thời.

## Mục tiêu học tập

Sau khi hoàn thành sprint, bạn có thể:

- Phân biệt database, DBMS, schema, table, row, column và SQL statement.
- Giải thích đường đi từ backend request đến PostgreSQL execution plan.
- Viết truy vấn `SELECT` có kết quả xác định với projection, filtering, ordering và pagination.
- Thiết kế relational schema nhỏ có primary key, foreign key, unique, `NOT NULL` và `CHECK` constraint.
- Giải thích vì sao constraint phải nằm trong database ngay cả khi service đã validate input.
- Dùng `INSERT`, `UPDATE`, `DELETE`, `ON CONFLICT` và explicit transaction an toàn.
- Dự đoán `NULL` và three-valued logic ảnh hưởng đến predicate như thế nào.
- Dùng `EXPLAIN (ANALYZE, BUFFERS)` làm bằng chứng thay vì đoán performance.

## Bức tranh lớn

~~~text
HTTP request
    |
    v
Backend service / ORM
    |
    v
SQL + parameters
    |
    v
PostgreSQL connection
    |
    +--> Parser và analyzer
    |
    +--> Planner / optimizer
    |
    +--> Executor
              |
              +--> indexes
              +--> buffer cache
              +--> heap/table pages
              +--> WAL và transaction visibility
~~~

Application mô tả *muốn kết quả gì*. PostgreSQL quyết định *lấy kết quả đó bằng cách nào* trong khi vẫn giữ các quy tắc relational và transactional đã khai báo trong schema.

## Các lesson

1. [Database, DBMS, SQL và PostgreSQL](01-database-dbms-sql-postgresql.md)
2. [Vòng đời query và `SELECT`](02-query-lifecycle-and-select.md)
3. [DDL, data types và constraints](03-ddl-data-types-and-constraints.md)
4. [DML và transaction boundary](04-dml-and-transactions.md)
5. [Filtering, `NULL` và three-valued logic](05-filtering-null-and-case.md)

## Dữ liệu dùng chung cho lab

Chạy bootstrap ở root trước. Lệnh này tạo schema `sales` và seed data có tính xác định. Demo data cố ý nhỏ để dễ suy luận; query-plan lab sẽ tạo một relation tạm thời lớn hơn để các lựa chọn plan có thể quan sát được.
