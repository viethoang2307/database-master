# Bản đồ bao phủ transcript

Transcript nguồn là một khóa học SQL Server. Bảng này ghi lại cách các nhóm nội dung chính được tái cấu trúc trong PostgreSQL curriculum. Các video ngắn được gom khi cùng dạy một concept có tính thống nhất.

| Khoảng transcript | Section trong repository | Nội dung mở rộng | Trạng thái |
| --- | --- | --- | --- |
| 001-008 | docs/foundations/ | SQL, database, DBMS, database type và PostgreSQL setup | Foundation Sprint |
| 009-011 | docs/foundations/ | Date/string/NULL foundation và prerequisite cho CASE | Foundation Sprint |
| 012-017 | docs/querying/ | Window-function orientation, subquery, CTE và TOP/LIMIT | Đã lên kế hoạch |
| 018-019 | docs/advanced-sql/ | View, CTAS và temporary table | Đã lên kế hoạch |
| 020 | docs/advanced-sql/ | PostgreSQL function/procedure và error handling | Đã lên kế hoạch |
| 021-023 | docs/performance/ | Index, partition và performance principle | Đã lên kế hoạch |
| 024 | docs/advanced-sql/ | Responsible AI assistance cho SQL development | Đã lên kế hoạch |
| 025 | docs/data-warehouse/ | Định hình data warehouse project | Đã lên kế hoạch |
| 027-034 | docs/querying/ | Predicate và prerequisite cho querying | Đã lên kế hoạch |
| 035-046 | docs/querying/ | No JOIN, JOIN types, anti-join, CROSS JOIN, cách chọn JOIN và multiple-table JOIN | Đã triển khai theo transcript |
| 047-055 | docs/querying/ | SET rules, UNION, UNION ALL, EXCEPT, INTERSECT, combine và delta detection | Đã triển khai theo transcript |
| 056-064 | docs/querying/ | Data transformation, SQL functions, CONCAT, UPPER, LOWER, TRIM, REPLACE, length/LEN, LEFT, RIGHT và SUBSTRING | Đã triển khai theo transcript |
| 065-082 | docs/querying/ | Numeric functions, date/time functions và casting | Đã lên kế hoạch |
| 083-099 | docs/foundations/ và docs/querying/ | NULL, CASE và conditional transformation | Foundation đã có; cần mở rộng theo transcript |
| 100-134 | docs/querying/ | Window aggregate, ranking và value function | Đã lên kế hoạch |
| 135-159 | docs/advanced-sql/ | Subquery và CTE | Đã lên kế hoạch |
| 160-198 | docs/advanced-sql/ | Architecture, view, table, CTAS, temp table, procedure và trigger | Đã lên kế hoạch |
| 199-221 | docs/performance/ | Index structure, statistics, execution plan và indexing strategy | Đã lên kế hoạch |
| 222-234 | docs/performance/ | Partitioning và performance tip | Đã lên kế hoạch |
| 235-241 | docs/advanced-sql/ | AI tool và prompt literacy, kèm safety/correctness check | Đã lên kế hoạch |
| 242-276 | docs/data-warehouse/ | Bronze/Silver/Gold warehouse project | Đã lên kế hoạch |
| 277-297 | docs/analytics/ | EDA, metric, report và project documentation | Đã lên kế hoạch |

## Ghi chú

- Transcript number 026, 034, 100 và 280 bị thiếu hoặc được thể hiện trong auxiliary course material; bản đồ dùng topic range thay vì giả định file number liên tục.
- FULL_TRANSCRIPT.txt cũng chứa Java material và không được dùng làm source of truth cho database.
- Các claim vendor-specific trong lesson ưu tiên PostgreSQL Documentation; SQL Server behavior chỉ được giữ lại khi cần giải thích migration từ transcript.
