# Lesson 2 — Vòng đời query và `SELECT`

## Tổng quan lesson

Transcript giới thiệu `SELECT`, `FROM`, `WHERE`, sorting và giới hạn kết quả. Điểm cần sửa quan trọng là SQL không được thực thi đơn giản từ dòng đầu tiên đến dòng cuối cùng. PostgreSQL parse statement, chuyển nó thành query tree, lập physical operators rồi mới execute plan.

### Mục tiêu học tập

- Viết projection với các column rõ ràng thay vì phụ thuộc vào `SELECT *`.
- Giải thích logical query processing khác physical execution như thế nào.
- Tạo kết quả top-N và pagination có tính xác định.
- Đọc hình dạng cơ bản của PostgreSQL plan.
- Phân biệt estimated rows/cost với actual rows/time.

## Mental map

~~~text
SQL text + parameters
        |
        v
Parser / analyzer
        |
        v
Logical query representation
        |
        v
Planner / optimizer
        |
        v
Seq Scan | Index Scan | Join | Sort | Aggregate
        |
        v
Rows returned to the client
~~~

## Khái niệm: projection, filtering và ordering

### Định nghĩa chính xác

- **Projection** chọn các output expression/column.
- **Filtering** chọn những row thỏa predicate.
- **Ordering** yêu cầu thứ tự output; nếu không có `ORDER BY` thì thứ tự row không được đảm bảo.
- **Limiting** giới hạn số row trả về, nhưng nếu không có ordering thì không xác định được row nào sẽ được chọn.

### Ví dụ

~~~sql
SELECT
    o.order_id,
    c.full_name AS customer_name,
    o.order_status,
    o.ordered_at
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status IN ('paid', 'shipped')
ORDER BY o.ordered_at DESC, o.order_id DESC
LIMIT 5;
~~~

Kết quả có tối đa năm order ở trạng thái paid hoặc shipped, xếp mới nhất trước. `order_id` là tie-breaker để hai order cùng timestamp không làm pagination bị thiếu hoặc lặp row.

### Logical order và written order

Một teaching model hữu ích là:

~~~text
FROM / JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> LIMIT
~~~

Đây là logical model, không phải lời hứa rằng PostgreSQL sẽ physically thực hiện mọi operation đúng theo thứ tự đó. Optimizer có thể push predicate xuống sớm hơn, dùng index cho ordering hoặc loại bỏ work không cần thiết nhưng vẫn giữ nguyên result semantics.

## Hành vi bên trong database

Với query đơn giản, PostgreSQL có thể chọn sequential scan trên các table page. Với predicate selective và index phù hợp, nó có thể chọn index scan hoặc bitmap scan. Planner so sánh estimated cost; nó không mặc định ưu tiên index.

`EXPLAIN` hiển thị plan mà không execute query. `EXPLAIN ANALYZE` execute statement và báo row count, timing quan sát được, vì vậy phải đặc biệt cẩn thận với `UPDATE`, `DELETE` hoặc statement có side effect. `BUFFERS` giúp quan sát hoạt động trên shared/local/temp block.

Ví dụ:

~~~sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, ordered_at
FROM sales.orders
WHERE customer_id = 8
ORDER BY ordered_at DESC;
~~~

Plan cụ thể phụ thuộc environment. Hãy đọc node tree từ dưới lên, so sánh `rows=` với `actual rows=`, đồng thời tìm misestimate lớn hoặc sort/scan tốn kém.

## Tác động performance

- Trả ít column hơn làm giảm work ở network và materialization.
- Filtering sớm có thể giảm số row đi vào join hoặc aggregate phía sau, nhưng optimizer quyết định cách thực thi.
- `LIMIT` có thể giảm work khi plan tạo ra row theo đúng order một cách incremental; nó không tự biến unordered full scan thành operation rẻ.
- Offset pagination thường ngày càng đắt khi database phải bỏ qua nhiều row. Keyset pagination dùng stable cursor như `(ordered_at, order_id)`.

## Góc nhìn Backend

Không bao giờ tạo identifier trong `ORDER BY` từ input người dùng bằng string concatenation. Hãy map API sort key được cho phép sang một SQL expression cố định. Bind value bằng parameter.

Ví dụ JPA:

~~~java
@Query("""
    select o from OrderEntity o
    where o.customer.id = :customerId
    order by o.orderedAt desc, o.id desc
    """)
List<OrderEntity> findRecentOrders(long customerId, Pageable pageable);
~~~

ORM có thể sinh `SELECT` kèm join và limit. Khi latency quan trọng, hãy inspect generated SQL và execution plan thực tế.

## Sai lầm thường gặp

- Giả định row tự nhiên được order theo primary key.
- Dùng `SELECT *` trong API projection.
- Dùng `LIMIT` không có `ORDER BY` cho top-N phục vụ business.
- Xem cost unit của `EXPLAIN` như milliseconds.
- Nghĩ rằng index chắc chắn được dùng chỉ vì index tồn tại.

## Lab thực hành

Chạy `sql/foundations/01_querying_sales.sql`, sau đó chạy `sql/labs/01_query_plan.sql` trong cùng một session. Trước query-plan `EXPLAIN` thứ hai, hãy dự đoán PostgreSQL sẽ dùng index, bitmap scan hay sequential scan. Lab cố ý không khẳng định một đáp án duy nhất vì plan phụ thuộc vào cost và statistics.

## So sánh

| Operation | Mục đích | Hành vi bên trong | Use case điển hình |
| --- | --- | --- | --- |
| `SELECT` | Đọc/project row | Planner chọn scan và operator | API read và report |
| `SELECT ... ORDER BY` | Yêu cầu thứ tự xác định | Có thể sort hoặc tận dụng ordered access path | Recent record, top-N |
| `SELECT ... LIMIT` | Giới hạn số result | Có thể dừng sớm, nhưng chỉ sau khi đáp ứng ordering/filtering | Page size |
| `EXPLAIN` | Inspect work dự kiến | Không execute statement | Phân tích plan |
| `EXPLAIN ANALYZE` | Đo execution quan sát được | Execute statement | Điều tra performance có kiểm soát |

## Câu hỏi phỏng vấn

1. **Junior — Vì sao cần `ORDER BY` cùng với `LIMIT`?** Nếu không có `ORDER BY`, database có thể trả về bất kỳ row nào thỏa điều kiện vì relational result mặc định không có thứ tự.
2. **Junior — Sequential scan là gì?** Là access method kiểm tra tuần tự các table page/row.
3. **Mid — Vì sao sequential scan đôi khi nhanh hơn index scan?** Khi nhiều row thỏa predicate, sequential I/O và filtering có thể rẻ hơn nhiều lần heap lookup ngẫu nhiên.
4. **Mid — `actual rows` cho biết điều gì trong `EXPLAIN ANALYZE`?** Nó cho biết số row node đã emit trên thực tế, hữu ích để so sánh reality với estimate.
5. **Senior — Vì sao ORM-generated query có thể đúng nhưng vẫn chậm?** Correctness và access-path efficiency là hai vấn đề khác nhau; join, projection, predicate, row estimate và index vẫn có thể tạo ra plan đắt.

## Tài liệu tham khảo

- [PostgreSQL `SELECT`](https://www.postgresql.org/docs/current/sql-select.html)
- [Using `EXPLAIN`](https://www.postgresql.org/docs/current/using-explain.html)
- [Giới hạn query và pagination trong PostgreSQL](https://www.postgresql.org/docs/current/queries-limit.html)
