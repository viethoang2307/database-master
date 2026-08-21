# Lộ trình Database Master

## Lộ trình học

| Giai đoạn | Module | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 0 | Định hướng | Mental model về Database, công cụ và workflow học | Foundation Sprint |
| 1 | SQL nền tảng | `SELECT`, DDL, constraints, DML và transactions | Foundation Sprint |
| 2 | Truy vấn dữ liệu | Filtering, `NULL`, `CASE`, sorting và pagination | Foundation Sprint |
| 3 | Kết hợp dữ liệu | Inner/outer joins, anti-joins và set operators | Đang triển khai — Querying Sprint |
| 4 | Biến đổi và phân tích | String/date/numeric functions và aggregates | Đã lên kế hoạch |
| 5 | Window functions | Aggregate, ranking và value windows | Đã lên kế hoạch |
| 6 | SQL phức tạp | Subqueries, CTEs, views, CTAS và temp tables | Đã lên kế hoạch |
| 7 | Lập trình phía Database | Functions, procedures, triggers và error handling | Đã lên kế hoạch |
| 8 | Tối ưu hiệu năng | Indexes, statistics, execution plans và `VACUUM` | Đã lên kế hoạch |
| 9 | Partitioning | Declarative partitioning, pruning và lifecycle operations | Đã lên kế hoạch |
| 10 | Data Warehouse project | Pipeline Bronze/Silver/Gold và dimensional modeling | Đã lên kế hoạch |
| 11 | Analytics project | EDA, metrics, reports và business questions | Đã lên kế hoạch |
| 12 | Production review | Interview questions, failure scenarios và design trade-offs | Đã lên kế hoạch |

## Workflow của mỗi lesson

Mỗi lesson quan trọng đi theo thứ tự:

~~~text
Why -> What -> How -> SQL -> Internals -> Trade-offs -> Production -> Practice
~~~

Lesson phải giải thích behavior thật của Database trước khi trình bày cú pháp ORM. Các transcript video ngắn cùng dạy một ý sẽ được gộp thành một lesson mạch lạc để giảm lặp lại.

## Domain mẫu dùng xuyên suốt

Khóa học sử dụng một domain e-commerce sales nhỏ:

~~~text
customers 1 ---- n orders 1 ---- n order_items n ---- 1 products
~~~

Domain này sẽ tiếp tục được dùng cho project Data Warehouse Bronze/Silver/Gold và các báo cáo analytics. Dữ liệu Foundation là dữ liệu synthetic, deterministic để expected results có thể lặp lại.

## Ranh giới nguồn

Thư mục nguồn có cả transcript Java và SQL. Project này chỉ xử lý bộ transcript SQL được đánh số. Transcript Java không liên quan và nằm ngoài repository này.
