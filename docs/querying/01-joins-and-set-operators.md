# Lesson 1 — JOIN, anti-join và set operators

## Tổng quan lesson

Application hiếm khi cần dữ liệu từ chỉ một table. Màn hình order history cần customer, order và có thể cả product; báo cáo retention cần tìm customer không có order; feed hợp nhất có thể lấy row từ nhiều query khác nhau. `JOIN` và set operators là cách SQL biểu diễn các nhu cầu đó.

Lesson này sửa một hiểu lầm phổ biến: join không chỉ là “ghép hai table theo id”. Join tạo ra một relation mới; số row có thể tăng, giảm hoặc giữ nguyên tùy cardinality và loại join. Set operator cũng không giống join: nó xếp chồng hoặc so sánh hai result có cùng shape.

### Điều kiện tiên quyết

Bạn nên biết projection, predicate, `NULL`, primary key, foreign key, `WHERE` và cách đọc một query plan cơ bản.

### Mục tiêu học tập

Sau lesson này, bạn có thể:

- Mô tả formal shape của inner, left, right, full và cross join.
- Viết query lấy order kèm customer và tổng số item.
- Dự đoán row multiplication trong one-to-many join.
- Đặt filter đúng vị trí để không vô tình biến `LEFT JOIN` thành inner join.
- Viết anti-join an toàn với `NOT EXISTS` khi dữ liệu có thể chứa `NULL`.
- Phân biệt `UNION`, `UNION ALL`, `INTERSECT` và `EXCEPT`.
- Đọc tác động của cardinality, index và join algorithm trong `EXPLAIN`.

## Bức tranh lớn

~~~text
Backend request
      |
      v
SQL với nhiều relation
      |
      v
Parser / analyzer
      |
      v
Planner ước lượng cardinality
      |
      +--> Nested Loop
      +--> Hash Join
      +--> Merge Join
      |
      v
Các row đã join hoặc set result
      |
      v
Projection -> filter cuối -> order -> API response
~~~

Application hỏi “những row nào liên quan với nhau?”. Planner chọn cách tìm các cặp row đó. Constraint giúp bảo đảm relationship đúng; index và statistics giúp planner tìm chúng với chi phí hợp lý.

## Concept 1: JOIN là phép kết hợp relation

### Trực giác

Một order có `customer_id` nhưng thông tin tên customer nằm ở table khác. Join dùng relationship đó để tạo một result row chứa các column từ cả hai relation.

### Định nghĩa chính xác

Với hai table `A` và `B`, join áp dụng một join condition lên các cặp row. Inner join chỉ giữ cặp thỏa condition; outer join còn giữ row không match từ một hoặc cả hai phía và điền giá trị thiếu bằng `NULL`.

Trong relational algebra, join có thể xem là selection trên tích Descartes:

`A JOIN B ON p` tương đương về semantics với chọn các cặp từ `A × B` thỏa predicate `p`, dù database không nhất thiết thực thi bằng cách tạo toàn bộ tích Descartes.

### Vì sao cần

Nếu denormalize toàn bộ customer name vào mọi order, dữ liệu sẽ lặp lại và dễ lệch. Join cho phép giữ data ở nơi có ownership rõ ràng rồi kết hợp khi đọc.

### Cơ chế

1. Planner phân tích join condition và ước lượng số row output.
2. Planner chọn join order và join algorithm.
3. Executor đọc row từ outer/inner input theo algorithm đó.
4. Chỉ các cặp thỏa condition được output, trừ outer join cần tạo null-extended row.
5. Projection và các filter tiếp theo tạo result cuối.

### Ví dụ

~~~sql
SELECT
    o.order_id,
    o.order_status,
    o.ordered_at,
    c.customer_id,
    c.full_name,
    c.country
FROM sales.orders AS o
JOIN sales.customers AS c
  ON c.customer_id = o.customer_id
WHERE o.order_status IN ('paid', 'shipped')
ORDER BY o.ordered_at DESC, o.order_id DESC;
~~~

Schema: `orders.customer_id` là foreign key đến `customers.customer_id`. Expected result: mỗi paid/shipped order đi kèm đúng một customer. Vì quan hệ many-to-one từ order đến customer, số row thường vẫn bằng số order thỏa filter.

### Hành vi bên trong

Foreign key bảo vệ correctness nhưng không bắt planner phải dùng một algorithm cụ thể. PostgreSQL có thể chọn nested loop, hash join hoặc merge join dựa trên statistics, cost settings, kích thước input và order có sẵn.

### Production notes

Luôn qualify column bằng alias khi nhiều table có tên giống nhau. Kiểm tra cardinality thật: nếu join condition không duy nhất như dự kiến, result có thể nhân lên rất lớn mà query vẫn “đúng” theo SQL.

## Concept 2: INNER JOIN

### Trực giác

Inner join trả về “những gì có match ở cả hai phía”. Row không có counterpart bị loại.

### Ví dụ

~~~sql
SELECT
    oi.order_id,
    p.product_id,
    p.product_name,
    oi.quantity,
    oi.unit_price
FROM sales.order_items AS oi
INNER JOIN sales.products AS p
  ON p.product_id = oi.product_id
WHERE oi.order_id = 1001
ORDER BY p.product_id;
~~~

Expected result: các line item của order `1001` cùng thông tin product. Vì `order_items.product_id` là foreign key, product tương ứng phải tồn tại nếu database invariant được giữ.

### Khi dùng và khi không nên dùng

Dùng khi business chỉ quan tâm record có relationship hợp lệ. Không dùng khi cần hiển thị parent dù chưa có child; khi đó cần outer join hoặc anti-join.

## Concept 3: LEFT, RIGHT và FULL OUTER JOIN

### Trực giác

`LEFT JOIN` giữ mọi row của bảng bên trái. Nếu bên phải không match, column phía phải là `NULL`. `RIGHT JOIN` là chiều ngược lại; `FULL OUTER JOIN` giữ row không match từ cả hai phía.

### Ví dụ: giữ cả customer chưa có order

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    o.order_id,
    o.order_status
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
ORDER BY c.customer_id, o.order_id;
~~~

Nếu customer không có order, customer vẫn xuất hiện với các column `o.*` là `NULL`. Seed hiện tại có order cho mọi customer, nhưng query vẫn đúng khi dữ liệu tương lai có customer mới.

### Filter trong `ON` và `WHERE`

Hai query sau không tương đương:

~~~sql
-- Giữ mọi customer; chỉ match paid order ở phía phải.
SELECT c.customer_id, c.full_name, o.order_id
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
 AND o.order_status = 'paid';

-- Chỉ còn customer có paid order; unmatched customer bị WHERE loại.
SELECT c.customer_id, c.full_name, o.order_id
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
WHERE o.order_status = 'paid';
~~~

Query thứ hai có kết quả tương tự inner join cho điều kiện paid. Đây là một nguồn bug lớn khi thêm filter vào query report.

### So sánh RIGHT và LEFT

`RIGHT JOIN` không có thêm sức mạnh biểu đạt; có thể đổi thứ tự hai table và dùng `LEFT JOIN` để dễ đọc hơn. `FULL OUTER JOIN` phù hợp khi cần reconciliation giữa hai nguồn và phải thấy cả phần chỉ có ở A lẫn chỉ có ở B.

## Concept 4: CROSS JOIN và row explosion

### Định nghĩa

`CROSS JOIN` tạo tích Descartes: mỗi row bên trái kết hợp với mỗi row bên phải.

~~~sql
SELECT
    c.customer_id,
    p.product_id
FROM (VALUES (1), (2)) AS c(customer_id)
CROSS JOIN (VALUES (10), (20), (30)) AS p(product_id);
~~~

Expected result: 2 × 3 = 6 row. Đây có thể là chủ đích khi tạo mọi combination, nhưng thường là bug do quên join condition.

### Production warning

Nếu hai input có lần lượt 100.000 và 100.000 row, cross product lý thuyết có 10 tỷ cặp. Luôn kiểm tra join condition, cardinality estimate và giới hạn result trước khi chạy trên dữ liệu lớn.


## Concept 5: Anti-join

### Trực giác

Anti-join trả về row bên trái không có match ở bên phải. Câu hỏi business thường gặp: “customer nào chưa từng đặt order?” hoặc “product nào chưa được bán?”

### Dạng nên ưu tiên: `NOT EXISTS`

~~~sql
SELECT
    c.customer_id,
    c.full_name
FROM sales.customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.orders AS o
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;
~~~

`EXISTS` kiểm tra sự tồn tại, không cần materialize toàn bộ matching row. PostgreSQL có thể biến subquery thành anti join trong plan.

### Dạng `LEFT JOIN ... IS NULL`

~~~sql
SELECT
    c.customer_id,
    c.full_name
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
~~~

Dạng này cũng hợp lệ khi column kiểm tra là non-nullable key ở phía phải. Hãy kiểm tra plan và tránh chọn column có thể null thật sự, vì khi đó ý nghĩa “không match” dễ bị lẫn.

### Vì sao tránh `NOT IN` khi có NULL

~~~sql
-- Có thể gây UNKNOWN nếu subquery trả về NULL.
SELECT c.customer_id
FROM sales.customers AS c
WHERE c.customer_id NOT IN (
    SELECT o.customer_id
    FROM sales.orders AS o
);
~~~

Nếu subquery có `NULL`, three-valued logic có thể làm nhiều row không pass `WHERE`. Dùng `NOT EXISTS` để biểu đạt anti-membership rõ ràng.

## Concept 6: Set operators

### Định nghĩa

Set operators kết hợp hai query result có cùng số column và các column tương ứng có type tương thích:

- `UNION` gộp kết quả và loại duplicate.
- `UNION ALL` gộp kết quả nhưng giữ duplicate.
- `INTERSECT` giữ row xuất hiện ở cả hai result.
- `EXCEPT` giữ row có ở query bên trái nhưng không có ở query bên phải.

Đây là kết hợp result theo “shape”, không phải ghép column theo relationship như join.

### Ví dụ: nguồn quốc gia

~~~sql
SELECT country AS country_code
FROM sales.customers
WHERE country IS NOT NULL
UNION
SELECT shipping_country AS country_code
FROM sales.orders
WHERE shipping_country IS NOT NULL
ORDER BY country_code;
~~~

Expected result: mỗi country code chỉ xuất hiện một lần. Hai query đều trả một column tương thích.

### `UNION` và `UNION ALL`

~~~sql
SELECT country AS country_code
FROM sales.customers
WHERE country IS NOT NULL
UNION ALL
SELECT shipping_country AS country_code
FROM sales.orders
WHERE shipping_country IS NOT NULL
ORDER BY country_code;
~~~

`UNION ALL` giữ số lần xuất hiện. Dùng nó khi duplicate có ý nghĩa hoặc khi biết input đã unique; dùng `UNION` khi cần semantics distinct và chấp nhận chi phí deduplication.

### `INTERSECT` và `EXCEPT`

~~~sql
-- Product vừa active vừa đã xuất hiện trong order item.
SELECT product_id
FROM sales.products
WHERE active = TRUE
INTERSECT
SELECT product_id
FROM sales.order_items
ORDER BY product_id;

-- Product active nhưng chưa từng xuất hiện trong order item.
SELECT product_id
FROM sales.products
WHERE active = TRUE
EXCEPT
SELECT product_id
FROM sales.order_items
ORDER BY product_id;
~~~

Query cuối là set-based alternative cho anti-join khi chỉ cần cùng một key shape. Với business query phức tạp, `NOT EXISTS` thường diễn đạt ý định rõ hơn.

### Precedence và ordering

`INTERSECT` bind chặt hơn `UNION` và `EXCEPT`; `UNION` và `EXCEPT` associate từ trái sang phải. Dùng parentheses để thể hiện ý định. `ORDER BY` ở cuối áp dụng cho result cuối; muốn limit một input riêng, đặt input đó trong parentheses.

## Điều gì xảy ra bên trong?

~~~text
SQL
 |
 v
Analyzer: resolve aliases, types, join columns
 |
 v
Planner: ước lượng cardinality và chọn join order
 |
 +--> Nested Loop: lấy row input rồi tìm match input kia
 +--> Hash Join: hash một phía, probe bằng phía còn lại
 +--> Merge Join: đọc hai input đã được order
 |
 +--> SetOp: sort/hash để combine hoặc loại duplicate
 |
 v
Projection / filter / sort cuối
~~~

### Nested Loop

Phù hợp khi outer input nhỏ và inner side có index hoặc được materialize hiệu quả. Nếu outer input lớn và inner lookup không rẻ, cost có thể tăng nhanh.

### Hash Join

Thường phù hợp cho equality join trên input lớn khi đủ memory cho hash table. Hash join không giải quyết range join trực tiếp.

### Merge Join

Cần input có order tương thích hoặc phải sort trước; có thể tốt khi dữ liệu đã ordered và phù hợp với các operation tiếp theo.

### Set operation

`UNION`/`INTERSECT`/`EXCEPT` cần xử lý duplicate hoặc membership. Planner có thể dùng hash hoặc sort; `UNION ALL` thường tránh được bước distinct nên rẻ hơn khi semantics cho phép.

## Performance engineering

- Join key nên có type tương thích và không bọc function không cần thiết.
- Primary key có enforcement index; foreign key ở phía referencing không tự động được index trong PostgreSQL. Index nó nếu workload thường join từ child về parent hoặc parent update/delete cần kiểm tra child.
- Index không đảm bảo được dùng. Planner cân nhắc selectivity, table size, statistics, cache và cost.
- Projection ít column giúp giảm network và memory; đừng dùng `SELECT *` khi ORM/API chỉ cần vài field.
- Với one-to-many, tổng row có thể tăng theo số child. Dùng aggregate hoặc `COUNT(DISTINCT ...)` nếu câu hỏi là số parent.
- Đo bằng `EXPLAIN (ANALYZE, BUFFERS)` và so sánh estimated rows với actual rows.
- `UNION` có distinct cost; không thay `UNION ALL` bằng `UNION` chỉ theo thói quen.

Ví dụ đọc plan:

~~~sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, count(DISTINCT o.order_id) AS order_count
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
GROUP BY c.customer_id;
~~~

Tập trung vào node join, `rows`, `actual rows`, loops, buffer hit/read và aggregate phía trên. Cost unit không phải milliseconds.

## Góc nhìn Backend

~~~text
HTTP request
    |
    v
Service xác định result shape
    |
    v
Repository query có join/exists
    |
    v
Database planner chọn access path
    |
    v
DTO projection -> response
~~~

### N+1 query

Một vòng lặp load orders rồi gọi thêm query customer cho từng order tạo N+1 round trip. Giải pháp có thể là join projection, batch fetch hoặc query riêng có kiểm soát; `JOIN FETCH` không phải lúc nào cũng đúng vì fetch nhiều collection có thể tạo row explosion.

### Pagination với join

Khi paginate parent cùng collection child, join trực tiếp có thể làm page chứa duplicate parent hoặc cắt một parent giữa các page. Hãy cân nhắc paginate parent id trước rồi fetch child, hoặc dùng query shape phù hợp.

### Idempotency và anti-join

Các query “chưa tồn tại” không thay thế constraint khi có race. Ví dụ check “email chưa có” bằng anti-join vẫn cần unique constraint khi insert.

## Góc nhìn ORM: JPA/Hibernate

SQL trước:

~~~sql
SELECT o.order_id, c.full_name
FROM sales.orders AS o
JOIN sales.customers AS c
  ON c.customer_id = o.customer_id
WHERE c.customer_id = :customerId
ORDER BY o.ordered_at DESC;
~~~

JPQL tương đương:

~~~java
@Query("""
    select new com.example.OrderSummary(o.id, c.fullName, o.orderedAt)
    from OrderEntity o
    join o.customer c
    where c.id = :customerId
    order by o.orderedAt desc
    """)
List<OrderSummary> findOrderSummaries(long customerId);
~~~

ORM có thể thêm column, alias, join hoặc limit khác với bạn tưởng. Hãy inspect generated SQL. Với existence, ưu tiên method trả boolean/count nhỏ thay vì load entity graph.

## So sánh các concept dễ nhầm

| Concept | Mục đích | Shape result | Duplicate | Use case |
| --- | --- | --- | --- | --- |
| INNER JOIN | Lấy cặp row có relationship match | Column từ nhiều relation | Có thể tăng theo cardinality | Order kèm customer |
| LEFT JOIN | Giữ toàn bộ row bên trái | Bên phải có thể là `NULL` | Có thể tăng theo số child | Customer kể cả chưa có order |
| ANTI-JOIN | Lấy row không có match | Thường chỉ column bên trái | Không nhân row nếu dùng `EXISTS` | Product chưa từng bán |
| UNION | Gộp hai result tương thích | Giữ một shape chung | Loại duplicate | Hợp nhất country codes |
| UNION ALL | Gộp và giữ duplicate | Giữ một shape chung | Giữ duplicate | Append event/result |
| INTERSECT | Lấy phần giao | Giữ một shape chung | Mặc định distinct | Product active và đã bán |
| EXCEPT | Lấy hiệu set | Giữ một shape chung | Mặc định distinct | Product active nhưng chưa bán |

## Sai lầm thường gặp

- Join table one-to-many rồi đếm row như đếm parent.
- Đặt filter phía phải trong `WHERE` sau `LEFT JOIN` và vô tình loại unmatched parent.
- Dùng `NOT IN` với subquery có thể trả `NULL`.
- Dùng `UNION` khi thực ra cần giữ duplicate.
- Nghĩ foreign key tự tạo index ở referencing side.
- Dùng `CROSS JOIN` do quên điều kiện.
- Dùng `DISTINCT` để che row explosion thay vì sửa join condition.
- Load cả entity graph bằng ORM trong khi API chỉ cần projection nhỏ.

## Failure scenario

### Scenario: báo cáo customer bị đếm phồng

~~~sql
SELECT
    c.customer_id,
    count(*) AS orders
FROM sales.customers AS c
JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
JOIN sales.order_items AS oi
  ON oi.order_id = o.order_id
GROUP BY c.customer_id;
~~~

Query trên đếm order item, không phải order. Order có ba item làm count tăng ba lần. Nếu mục tiêu là số order, dùng `count(DISTINCT o.order_id)`. Nếu mục tiêu là tổng item, tên metric phải phản ánh điều đó.

### Scenario: left join bị biến thành inner join

Nếu report phải hiển thị customer chưa có paid order, filter status phải nằm trong `ON`. Đặt `o.order_status = 'paid'` vào `WHERE` sẽ loại row có `o.order_status IS NULL`.

## Lab thực hành

1. Chạy bootstrap.
2. Chạy `sql/querying/01_joins_and_sets.sql`.
3. Trước mỗi query, dự đoán số row và các key có thể lặp.
4. Dùng `EXPLAIN (ANALYZE, BUFFERS)` cho query aggregate.
5. Thay `NOT EXISTS` bằng `LEFT JOIN ... IS NULL` và so sánh result.
6. Thêm một customer chưa có order trong temporary table, rồi quan sát khác biệt giữa filter trong `ON` và `WHERE`.
7. Thử đổi `UNION` thành `UNION ALL` và đếm số row.

## Mental models

- Join ghép row theo relationship; set operator ghép hoặc so sánh result theo shape.
- `LEFT JOIN` giữ thế giới bên trái; filter trong `WHERE` có thể xóa những row vừa được giữ lại.
- Anti-join hỏi “không tồn tại match”, không phải “giá trị bằng null”.
- One-to-many join có thể nhân row; số row output là một phần của semantics.
- `UNION ALL` là append; `UNION` là append rồi distinct.

## Cheat sheet

~~~sql
-- Inner join
FROM a
JOIN b ON b.key = a.foreign_key

-- Left join giữ parent không có child
FROM parent p
LEFT JOIN child c ON c.parent_id = p.id

-- Anti-join
WHERE NOT EXISTS (
    SELECT 1
    FROM child c
    WHERE c.parent_id = p.id
)

-- Gộp result
query_a
UNION [ALL]
query_b

-- Giao / hiệu
query_a INTERSECT query_b
query_a EXCEPT query_b
~~~

## Kết nối đến lesson tiếp theo

~~~text
JOIN và cardinality
       |
       v
Aggregates và GROUP BY
       |
       v
Window functions
       |
       v
Subqueries / CTEs
       |
       v
Execution plans và indexing strategy
~~~

Hiểu row shape của join là prerequisite để đọc aggregate, window function và ORM fetch plan.


## Transcript alignment additions — bài 035–055

Phần này ghi lại những điểm cụ thể trong transcript được bổ sung hoặc hiệu chỉnh khi chuyển lesson sang PostgreSQL.

### 035–036: JOIN, set operator và No JOIN

- JOIN kết hợp column của hai relation theo một predicate/key; set operator kết hợp hoặc so sánh row theo một result shape tương thích.
- No JOIN không phải một join type. Hai câu SELECT độc lập tạo hai result set độc lập. Pattern này phù hợp khi API có hai collection riêng; nếu application phải tự ghép customer với order trong vòng lặp, hãy cân nhắc JOIN hoặc batch fetch để tránh N+1.
- JOIN cần xác định key liên kết. Set operator cần cùng số column, type tương thích và cùng ý nghĩa theo vị trí.

### 037–040: INNER, LEFT, RIGHT và FULL JOIN

- INNER JOIN chỉ giữ các cặp có match; nếu bỏ từ khóa type trong PostgreSQL thì JOIN mặc định là INNER JOIN, nhưng nên viết tường minh trong code review.
- LEFT JOIN giữ toàn bộ row bên trái và null-extend phía phải khi không match. Predicate giới hạn row bên phải nên đặt trong ON nếu vẫn muốn giữ parent không có match.
- RIGHT JOIN có thể biểu đạt bằng cách đổi thứ tự bảng rồi dùng LEFT JOIN; cách đó thường làm bảng chính rõ hơn.
- FULL OUTER JOIN giữ mọi row từ cả hai phía. Nó hữu ích cho reconciliation khi cần thấy match, only-left và only-right.

### 041–043: ba dạng anti-join

Không có keyword portable LEFT ANTI JOIN, RIGHT ANTI JOIN hay FULL ANTI JOIN.

Left anti-join có thể viết bằng NOT EXISTS:

~~~sql
SELECT p.product_id, p.product_name
FROM sales.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.order_items AS oi
    WHERE oi.product_id = p.product_id
);
~~~

Hoặc bằng LEFT JOIN và kiểm tra một key không nullable ở phía phải:

~~~sql
SELECT p.product_id, p.product_name
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi
  ON oi.product_id = p.product_id
WHERE oi.product_id IS NULL;
~~~

Right anti-join giữ row phía phải không có match. Full anti-join giữ phần không match ở cả hai phía:

~~~sql
SELECT c.customer_id, o.order_id
FROM sales.customers AS c
FULL OUTER JOIN sales.orders AS o
  ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
   OR o.order_id IS NULL;
~~~

Schema repository có foreign key từ orders đến customers, vì vậy phía orphan order thường rỗng trong dữ liệu hợp lệ. Pattern vẫn quan trọng khi đọc staging hoặc đối soát hai nguồn chưa có constraint.

### 044–046: CROSS JOIN, chọn JOIN và nhiều bảng

CROSS JOIN tạo Cartesian product. Hai input có lần lượt m và n row sẽ tạo m nhân n cặp trước khi các bước sau lọc; quên điều kiện join trên bảng lớn có thể gây row explosion.

Decision tree:

1. Chỉ cần match hai phía: INNER JOIN.
2. Giữ toàn bộ bảng chính và thêm dữ liệu nếu có: LEFT JOIN.
3. Giữ toàn bộ hai nguồn ngang hàng: FULL OUTER JOIN.
4. Tìm phần không match một phía: left/right anti-join.
5. Tạo mọi combination có chủ đích: CROSS JOIN.
6. Cần hai danh sách riêng: hai SELECT độc lập.

Với multiple-table join, xác định grain trước. Query bắt đầu từ orders rồi nối customers, order_items và products có grain là order item; một order có nhiều item nên order columns lặp. Nếu cần một row/order, aggregate theo order_id hoặc pre-aggregate order_items trước khi join. Luôn dùng alias, qualify column và kiểm tra đúng foreign key.

### 047–052: SET rules và bốn operator

Các nhánh của set expression phải có cùng số column; column tương ứng cần type tương thích; mapping là theo vị trí, không theo tên. ORDER BY nên đặt một lần ở query cuối. Alias output lấy từ nhánh đầu tiên. PostgreSQL thực hiện type resolution để chọn common type, nên diễn đạt chính xác hơn rằng type phải tương thích thay vì nói nhánh đầu luôn quyết định type.

- UNION loại duplicate.
- UNION ALL giữ duplicate và thường tránh bước distinct.
- EXCEPT có hướng: Q1 EXCEPT Q2 khác Q2 EXCEPT Q1.
- INTERSECT lấy row chung của hai query và thường không đổi tập row khi đổi thứ tự.

SQL có thể chạy mà vẫn sai nghĩa nếu developer đảo thứ tự business columns. Không dùng SELECT * khi hợp nhất current/archive hoặc nhiều nguồn có nguy cơ schema drift.

### 053–055: combine information và delta detection

Combine information dùng UNION hoặc UNION ALL để hợp nhất các nguồn cùng business shape, chẳng hạn current orders và archive orders. Nên thêm một column tĩnh như source_table để truy vết nguồn.

Delta detection dùng EXCEPT để lấy batch ngày 2 trừ batch ngày 1:

~~~sql
WITH day_1(customer_id, email) AS (
    VALUES (1, 'a@example.com'), (2, 'b@example.com')
),
day_2(customer_id, email) AS (
    VALUES
        (1, 'a@example.com'),
        (2, 'b@example.com'),
        (3, 'c@example.com')
)
SELECT customer_id, email FROM day_2
EXCEPT
SELECT customer_id, email FROM day_1;
~~~

Kết quả là customer 3 theo projection đã chọn. Khi kiểm tra migration, chạy cả source EXCEPT target và target EXCEPT source. Hai kết quả rỗng chỉ chứng minh hai projection/snapshot không khác nhau; vẫn phải xem xét duplicate, column bị bỏ qua, business key và tính nhất quán của snapshot.

### Hiệu chỉnh quan trọng so với cách nói rút gọn

Transcript dùng ví dụ Sales SQL Server và có thể gọi EXCEPT là phép so sánh đơn giản. Trong production, cần phân biệt set equality với equality có multiplicity, kiểm tra result grain và không dùng anti-join thay cho unique/foreign-key constraint. Các ví dụ trong repository là PostgreSQL; hành vi khác vendor phải được kiểm tra theo documentation của DBMS đang dùng.

## Transcript Coverage Map

| Transcript | Nội dung | Nơi triển khai |
| --- | --- | --- |
| 035–036 | Mental model JOIN/set operator và No JOIN | Concept 1, phần bổ sung 035–036 |
| 037–040 | INNER, LEFT, RIGHT, FULL JOIN | Concepts 2–3, phần bổ sung |
| 041–043 | Left/right/full anti-join | Concept 5, phần bổ sung |
| 044–046 | CROSS JOIN, quyết định JOIN, nhiều bảng | Concept 4, phần bổ sung |
| 047–052 | Rules, UNION, UNION ALL, EXCEPT, INTERSECT | Concept 6 |
| 053–055 | Combine information, delta detection, summary | Concept 6, phần bổ sung |

## Tài liệu tham khảo

- [PostgreSQL Table Expressions — joins](https://www.postgresql.org/docs/current/queries-table-expressions.html)
- [PostgreSQL Combining Queries — UNION, INTERSECT, EXCEPT](https://www.postgresql.org/docs/current/queries-union.html)
- [PostgreSQL `SELECT`](https://www.postgresql.org/docs/current/sql-select.html)
- [PostgreSQL Subquery Expressions — `EXISTS`](https://www.postgresql.org/docs/current/functions-subquery.html)
- [PostgreSQL Using `EXPLAIN`](https://www.postgresql.org/docs/current/using-explain.html)
