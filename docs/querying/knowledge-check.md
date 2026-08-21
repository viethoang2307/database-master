# Knowledge check — JOIN và set operators

Hãy trả lời trước khi mở file solution.

1. **Trắc nghiệm:** Join nào giữ mọi row của table bên trái dù không có match?
   - A. `INNER JOIN`
   - B. `LEFT JOIN`
   - C. `CROSS JOIN`
   - D. `INTERSECT`

2. **Đúng/sai:** Foreign key tự động tạo index trên referencing column trong PostgreSQL.

3. **Trả lời ngắn:** Vì sao join order_items vào orders có thể làm số row tăng?

4. **Dự đoán result:** Với `LEFT JOIN`, column bên phải có giá trị gì khi không có match?

5. **Phân tích query:** Vì sao filter `o.order_status = 'paid'` trong `WHERE` có thể làm left join hoạt động như inner join?

6. **Trắc nghiệm:** Dạng nào biểu đạt anti-join an toàn khi subquery có thể chứa `NULL`?
   - A. `NOT IN`
   - B. `NOT EXISTS`
   - C. `CROSS JOIN`
   - D. `UNION ALL`

7. **Đúng/sai:** `UNION ALL` loại duplicate giống `UNION`.

8. **Trả lời ngắn:** Hai query input của set operator phải tương thích ở những điểm nào?

9. **Query analysis:** Vì sao `COUNT(*)` sau join parent-child không luôn bằng số parent?

10. **Trắc nghiệm:** Join algorithm nào thường build hash table cho một input rồi probe bằng input kia?
    - A. Nested loop
    - B. Hash join
    - C. Merge join
    - D. Set difference

11. **Dự đoán output:** Query sau có thể trả bao nhiêu row?

    ~~~sql
    SELECT c.customer_id, p.product_id
    FROM (VALUES (1), (2)) AS c(customer_id)
    CROSS JOIN (VALUES (10), (20), (30)) AS p(product_id);
    ~~~

12. **Suy luận engineering:** Nêu một cách tránh N+1 query khi API cần order và customer name.

13. **Trả lời ngắn:** Vì sao No JOIN không phải một join type? Khi nào hai result set riêng phù hợp hơn một join?
14. **Đúng/sai:** RIGHT JOIN có semantics khác hoàn toàn LEFT JOIN và không thể đổi thứ tự bảng để thay thế.
15. **Query analysis:** Full anti-join cần điều kiện WHERE nào sau FULL OUTER JOIN?
16. **Trắc nghiệm:** Set operator ghép column theo tiêu chí nào?
    - A. Tên alias
    - B. Vị trí ordinal
    - C. Foreign key
    - D. Thứ tự tạo index
17. **Đúng/sai:** Alias ở nhánh thứ hai của UNION sẽ đổi tên column output.
18. **Trả lời ngắn:** Vì sao UNION ALL thường nhanh hơn UNION?
19. **Dự đoán output:** day_2 EXCEPT day_1 trả về loại record nào trong delta detection?
20. **Query analysis:** Vì sao join orders -> order_items -> products có thể trả nhiều row cho một order? Nếu API cần một row/order thì sửa thế nào?

## Đáp án

1. B  LEFT JOIN.
2. Sai  PostgreSQL không tự động tạo index cho referencing column của foreign key.
3. One-to-many tạo một output row cho mỗi child.
4. Column phía phải được null-extend, thường là NULL.
5. Predicate trong WHERE loại row null-extended; đưa predicate vào ON nếu muốn giữ parent.
6. B  NOT EXISTS.
7. Sai  UNION ALL giữ duplicate.
8. Cùng số column, type tương thích, mapping cùng vị trí; ORDER BY đặt ở query cuối.
9. Vì child row làm parent lặp; dùng COUNT(DISTINCT parent_id) nếu metric là parent.
10. B  hash join.
11. Sáu row.
12. Dùng projection/batch query hoặc join có kiểm soát; tránh lazy load trong vòng lặp.
13. Nó tạo hai result set độc lập và phù hợp khi hai collection có contract/pagination/lifecycle riêng.
14. Sai  đổi thứ tự input và dùng LEFT JOIN có thể biểu đạt cùng semantics.
15. left_key IS NULL OR right_key IS NULL.
16. B  vị trí ordinal.
17. Sai  tên output lấy từ nhánh đầu.
18. Không có bước distinct/deduplicate toàn bộ output.
19. Record có ở ngày 2 nhưng không có ở ngày 1 theo projection đã chọn.
20. Vì một order có nhiều line item; aggregate theo order_id hoặc pre-aggregate items trước khi join.
