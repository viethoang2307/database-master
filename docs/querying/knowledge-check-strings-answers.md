# Knowledge Check Answers - String Functions và Data Transformation

## Multiple choice

1. B. CONCAT_WS dùng separator và bỏ qua argument NULL.
2. C. octet_length đếm byte.
3. C. PostgreSQL bắt đầu từ vị trí 1, nên FROM 2 lấy từ ký tự thứ hai đến hết.
4. C. Expression index khớp expression query; table nhỏ vẫn có thể khiến planner chọn sequential scan.
5. C. sum là aggregate function.

## True / False

6. False. SELECT chỉ tạo projection; muốn persistence phải dùng DML/pipeline/generated column theo thiết kế.
7. False. TRIM chủ yếu xử lý đầu/cuối theo tập character; không tự xóa internal whitespace hoặc mọi loại newline/tab.
8. False. Chuỗi rỗng là text length 0; NULL là missing/unknown và có logic riêng.
9. True.
10. True. EXPLAIN ANALYZE chạy statement, nên cần cẩn thận với DML.

## Short answer

11. Leading space có thể trở thành character đầu tiên, làm prefix business sai. Btrim trước khi LEFT nếu policy coi edge space là dirty.
12. Dùng char_length khi rule nói về số character, ví dụ giới hạn hiển thị. Dùng octet_length khi boundary nói về số byte của payload.
13. Replace chỉ thay substring. Nó không kiểm tra country code, format, extension, digit semantics hay domain invariant.
14. Expression index có thể giúp lookup expression nhanh hơn, nhưng tăng storage và chi phí insert/update. Query phải dùng expression tương thích; planner vẫn có thể chọn scan.
15. Presentation transformation tạo output cho một consumer và không nhất thiết thay đổi storage. Canonicalization tạo representation chuẩn dùng cho identity, uniqueness, join hoặc search và cần policy/enforcement rõ ràng.

## Predict the output / explain why

16. Trong PostgreSQL:

- concat bỏ qua argument country NULL nhưng literal separator vẫn được nối theo các argument còn lại.
- concat_ws bỏ qua country NULL và không tạo separator cho field bị bỏ qua.
- toán tử || có thể cho NULL vì một operand là NULL.

Cần kiểm tra cụ thể trên DBMS mục tiêu; không suy ra semantics của SQL Server từ PostgreSQL.

17. PostgreSQL length(text) đếm character và giữ semantics trailing spaces của text. SQL Server LEN bỏ qua trailing spaces. Đây là khác biệt cần test khi migrate; không thay tên hàm máy móc.

18. left(raw_name, 2) bắt đầu bằng space rồi lấy thêm character kế tiếp. left(btrim(raw_name), 2) lấy hai character đầu của tên đã sạch, thường là Jo.

## Query analysis

19. lower(btrim(email)) bọc quanh column nên ordinary index trên email raw có thể không đủ. Điều tra bằng SQL generated, EXPLAIN/EXPLAIN ANALYZE, actual rows, buffers, statistics và selectivity. Hướng sửa gồm normalized column có index hoặc expression index đúng lower(btrim(email)); đồng thời chốt policy về trim, case folding và uniqueness.

20. Query loại row NULL vì phép so sánh với NULL không trả TRUE. Nó cũng chỉ tìm edge whitespace, không tìm chuỗi rỗng hoặc internal whitespace. Audit NULL riêng bằng:

~~~sql
WHERE full_name IS NULL
~~~

Nếu muốn một report đầy đủ, dùng các cờ is_null, is_empty và has_edge_whitespace riêng.
