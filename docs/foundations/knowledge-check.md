# Bài kiểm tra kiến thức nền tảng

Hãy trả lời mà không mở file solution.

1. **Trắc nghiệm:** Component nào chọn giữa sequential scan và index scan?
   - A. SQL client
   - B. Query planner/optimizer
   - C. Foreign key
   - D. Connection pool

2. **Đúng/sai:** Một table có physical row order được đảm bảo nếu nó có primary key.

3. **Trả lời ngắn:** Vì sao API top-N query thường cần deterministic `ORDER BY`?

4. **Dự đoán output:** Expression nào là `TRUE`?

   ~~~sql
   SELECT NULL = NULL, NULL IS NULL, NULL <> 10;
   ~~~

5. **Trắc nghiệm:** Constraint nào bảo vệ việc mọi order đều tham chiếu đến một customer tồn tại?
   - A. `CHECK`
   - B. `UNIQUE`
   - C. `FOREIGN KEY`
   - D. `DEFAULT`

6. **Giải thích:** Vì sao foreign key có thể đúng nhưng join vẫn chậm?

7. **Phân tích query:** Query sau có vấn đề gì khi lấy dữ liệu tháng March?

   ~~~sql
   WHERE date(ordered_at) BETWEEN DATE '2025-03-01' AND DATE '2025-03-31'
   ~~~

8. **Đúng/sai:** `EXPLAIN ANALYZE` execute statement đang được phân tích.

9. **Trả lời ngắn:** Application nên làm gì nếu transaction nhận serialization failure?

10. **Trắc nghiệm:** Operation nào xóa table definition?
    - A. `DELETE`
    - B. `TRUNCATE`
    - C. `DROP TABLE`
    - D. `VACUUM`

11. **Dự đoán kết quả:** Vì sao `NOT IN` có thể không trả row khi subquery chứa `NULL`?

12. **Suy luận engineering:** Nêu một lý do nên enforce một invariant ở cả service và database.
