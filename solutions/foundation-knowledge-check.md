# Đáp án bài kiểm tra kiến thức nền tảng

1. **B.** Planner/optimizer so sánh các physical plan có thể có bằng estimates và cost settings.
2. **Sai.** Primary key định danh row nhưng không đảm bảo result order.
3. `LIMIT` không kèm `ORDER BY` không xác định row nào thỏa điều kiện sẽ được trả; tie-breaker làm page boundary ổn định.
4. Chỉ `NULL IS NULL` là `TRUE`. Equality và inequality với `NULL` evaluate thành `UNKNOWN`.
5. **C.** Foreign key enforce referenced relationship.
6. Foreign key đảm bảo correctness nhưng không tự động tạo mọi index hữu ích ở referencing side và không đảm bảo join plan luôn rẻ.
7. Query inclusive ở cả hai date endpoint nhưng convert timestamp column trên mọi row và có thể xử lý sai end-of-day boundary. Ưu tiên `ordered_at >= '2025-03-01' AND ordered_at < '2025-04-01'` với time-zone semantics rõ ràng.
8. **Đúng.** `EXPLAIN ANALYZE` chạy statement và báo execution detail quan sát được; phải cẩn thận với statement có side effect.
9. Abort/rollback transaction rồi retry toàn bộ logical operation khi operation an toàn và có giới hạn retry.
10. **C.** `DROP TABLE` xóa relation definition và data.
11. SQL dùng three-valued logic: nếu không có known value nào match nhưng set chứa `NULL`, predicate `NOT IN` có thể là `UNKNOWN` và không pass `WHERE`.
12. Service validation giúp feedback tốt hơn và tránh database error không cần thiết; database enforcement bảo vệ trước race, script và writer khác.
