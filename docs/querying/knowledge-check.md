# Knowledge check — JOIN và set operators

Hãy trả lời trước khi mở file solution.

1. **Trắc nghiệm:** Join nào giữ mọi row của table bên trái dù không có match?
   - A. §INNER JOIN§
   - B. §LEFT JOIN§
   - C. §CROSS JOIN§
   - D. §INTERSECT§

2. **Đúng/sai:** Foreign key tự động tạo index trên referencing column trong PostgreSQL.

3. **Trả lời ngắn:** Vì sao join order_items vào orders có thể làm số row tăng?

4. **Dự đoán result:** Với §LEFT JOIN§, column bên phải có giá trị gì khi không có match?

5. **Phân tích query:** Vì sao filter §o.order_status = 'paid'§ trong §WHERE§ có thể làm left join hoạt động như inner join?

6. **Trắc nghiệm:** Dạng nào biểu đạt anti-join an toàn khi subquery có thể chứa §NULL§?
   - A. §NOT IN§
   - B. §NOT EXISTS§
   - C. §CROSS JOIN§
   - D. §UNION ALL§

7. **Đúng/sai:** §UNION ALL§ loại duplicate giống §UNION§.

8. **Trả lời ngắn:** Hai query input của set operator phải tương thích ở những điểm nào?

9. **Query analysis:** Vì sao §COUNT(*)§ sau join parent-child không luôn bằng số parent?

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
