# Lời giải - String Functions và Data Transformation

Các lời giải dưới đây là một đáp án có thể chấp nhận. Với bài engineering, chất lượng được đánh giá bằng reasoning, invariant và cách kiểm chứng, không chỉ bằng một câu SQL.

## Level 1 - Recall

1. Không. SELECT tạo projection mới; chỉ DML, pipeline, generated column hoặc application boundary mới có thể persistence thay đổi.
2. Scalar thường tạo một output value cho mỗi input row. Aggregate gom nhiều row thành một output cho mỗi group.
3. Window function tính trên tập row nhưng vẫn giữ output gắn với từng row; aggregate thường làm giảm số row theo group.
4. Separator là argument đầu tiên của CONCAT_WS.
5. Vùng đầu và cuối của chuỗi theo tập character được chỉ định; mặc định là space. Nó không tự xóa internal whitespace.
6. Chuỗi rỗng là một text value có độ dài 0. NULL biểu thị missing/unknown và tham gia three-valued logic.
7. length/char_length đếm character; octet_length đếm byte trong PostgreSQL.
8. Vị trí 1.
9. PostgreSQL replace thay tất cả occurrence của substring.
10. Planner phải đánh giá expression cho candidate row nếu không có access path phù hợp. Expression index hoặc normalized column có thể mở lại khả năng lookup.

## Level 2 - Apply

### Bài 2.1

~~~sql
SELECT
    c.customer_id,
    c.full_name AS raw_name,
    btrim(c.full_name) AS clean_name,
    concat_ws(' / ', btrim(c.full_name), c.country) AS display_label
FROM sales.customers AS c
ORDER BY c.customer_id;
~~~

CONCAT_WS bỏ qua argument NULL và phù hợp cho label có delimiter. Đây là projection, không sửa table.

### Bài 2.2

~~~sql
SELECT
    c.customer_id,
    c.full_name AS raw_name,
    btrim(c.full_name) AS proposed_name,
    char_length(c.full_name) AS raw_chars,
    char_length(btrim(c.full_name)) AS cleaned_chars,
    c.full_name IS NOT NULL
        AND c.full_name <> btrim(c.full_name) AS has_edge_whitespace
FROM sales.customers AS c
WHERE c.full_name IS NOT NULL
  AND c.full_name <> btrim(c.full_name)
ORDER BY c.customer_id;
~~~

NULL được lọc riêng để không nhầm với dữ liệu có edge whitespace. Nếu cần audit NULL, dùng một query/cờ riêng với IS NULL.

### Bài 2.3

~~~sql
SELECT
    c.customer_id,
    left(btrim(c.full_name), 3) AS first_three,
    right(btrim(c.full_name), 3) AS last_three,
    substring(btrim(c.full_name) FROM 2) AS without_first
FROM sales.customers AS c
WHERE c.full_name IS NOT NULL
ORDER BY c.customer_id;
~~~

Btrim nằm ở lớp trong để prefix/suffix không bị leading/trailing space làm sai.

### Bài 2.4

~~~sql
SELECT
    c.customer_id,
    lower(btrim(c.email)) AS normalized_email
FROM sales.customers AS c
WHERE c.email IS NOT NULL;
~~~

Khi có parameter đã bind:

~~~sql
SELECT c.customer_id
FROM sales.customers AS c
WHERE lower(btrim(c.email)) = lower(btrim(:input));
~~~

Trong production, expression này cần policy/index phù hợp; query đúng về semantics chưa đủ để đảm bảo nhanh.

### Bài 2.5

~~~sql
WITH sample(value) AS (
    VALUES ('Maria'), ('abc  '), ('Café')
)
SELECT
    value,
    char_length(value) AS character_count,
    octet_length(value) AS byte_count
FROM sample;
~~~

UI character limit dùng char_length; external byte limit dùng octet_length. Grapheme mà người dùng nhìn thấy có thể khác character count nên UI phức tạp cần test thêm.

### Bài 2.6

Trong PostgreSQL, CONCAT bỏ qua argument NULL nhưng literal separator vẫn được nối; CONCAT_WS bỏ qua field NULL cùng separator field; toán tử || có thể cho NULL nếu một operand NULL. Vì semantics vendor-specific, cần chạy test trên DBMS mục tiêu thay vì đoán từ tên hàm.

### Bài 2.7

~~~sql
SELECT
    c.customer_id,
    c.phone,
    replace(c.phone, '-', '') AS phone_without_dashes
FROM sales.customers AS c
WHERE c.phone IS NOT NULL;
~~~

REPLACE chỉ thay substring. Nó không kiểm tra country code, extension, độ dài, digit-only sau mọi loại whitespace hoặc format business.

### Bài 2.8

~~~sql
SELECT substring(btrim(full_name) FROM 2)
FROM sales.customers;
~~~

Bỏ FOR count để lấy phần còn lại. PostgreSQL dùng start 1-based.

## Level 3 - Engineering

### Bài 3.1

Một thiết kế hợp lý:

1. Chốt policy: có trim không, lower/case folding nào, email NULL có hợp lệ không, original value có cần giữ không.
2. Nếu normalized value là identity, cân nhắc cot email_normalized được populate ở write boundary và unique index trên cột đó. Expression index trên lower(btrim(email)) phù hợp khi không cần expose value riêng.
3. Backfill theo batch, kiểm tra duplicate trước khi bật unique enforcement.
4. Kiểm tra SQL generated và parameter type. Dùng EXPLAIN, EXPLAIN ANALYZE trên safe SELECT, BUFFERS và production telemetry.
5. So sánh plan trước/sau trên dữ liệu gần production. Table nhỏ có thể vẫn sequential scan.
6. Rollout index concurrently khi phù hợp với PostgreSQL production policy; chuẩn bị migration retry, monitoring và rollback/drop plan.
7. Không lower mọi email cho display nếu cần giữ original presentation.

### Bài 3.2

Không sửa mọi row trong request. Tách job repair:

1. Preview và ghi các row candidate vào audit table hoặc export.
2. Xác định conflict sau trim, ví dụ hai row trở thành cùng normalized key.
3. Chạy batch nhỏ trong transaction, có predicate idempotent full_name <> btrim(full_name).
4. Theo dõi lock duration, rows changed, errors và retry.
5. Chạy validation sau batch; chỉ COMMIT sau khi invariant được kiểm tra.
6. Nếu business yêu cầu dữ liệu mới sạch, enforce ở write boundary; repair job xử lý lịch sử.
7. Không trim secret/token/password một cách máy móc.

### Bài 3.3

REPLACE mọi "pro" rất dễ sửa nhầm "profile" hoặc tên hợp lệ. Quy trình:

- SELECT raw_name và proposed_name, kèm predicate có giới hạn.
- Review sample và count; phân biệt case/word boundary nếu business yêu cầu.
- Giữ raw value trong audit table.
- Dùng transaction và migration id cố định để idempotent.
- Update theo primary key đã review, không chạy lại replace mù.
- Có verification query và rollback/restore plan.
- Nếu chỉ cần report label mới, dùng projection thay vì sửa raw.

### Bài 3.4

Dùng char_length cho giới hạn 100 characters của UI và octet_length cho giới hạn 256 bytes của API. Chạy cả hai validation ở boundary tương ứng. Với Unicode cần test cụ thể, vì character count vẫn không hoàn toàn là grapheme count.

### Bài 3.5

Checklist:

1. Log SQL thật và bind values/type, không chỉ method name.
2. Xác nhận expression chính xác là lower(trim(email)) hay lower(btrim(email)).
3. Kiểm tra ordinary index có match không.
4. Kiểm tra expression index hoặc normalized column.
5. Chạy EXPLAIN, actual rows, buffers trên dữ liệu tương tự production.
6. Xem selectivity, statistics freshness và table size.
7. Xem projection, network payload, pool saturation và concurrent load.
8. Test plan sau khi migrate/index; không benchmark chỉ bằng một request.
9. Xác định dialect của Hibernate có sinh SQL đúng PostgreSQL không.

### Bài 3.6

Test tối thiểu:

~~~sql
WITH sample(value) AS (
    VALUES
        (NULL::text),
        (''),
        ('abc  '),
        ('Café')
)
SELECT
    value,
    char_length(value) AS pg_char_length,
    octet_length(value) AS pg_byte_length,
    value IS NULL AS is_null
FROM sample;
~~~

Kiểm tra riêng trailing spaces thay vì dùng giả định LEN. Nếu cần tương đương SQL Server LEN theo business, phải mô tả rule rồi dùng expression PostgreSQL phù hợp, có thể là char_length(rtrim(value)) cho text không NULL, chứ không thay máy móc trong mọi query.

## Debugging Challenges

### Challenge 1

- Normalize parameter và column cùng một policy, tránh input đã lower nhưng column còn edge space.
- NULL không match bằng dấu =; cần policy email NULL.
- Ordinary index trên email raw không tự động match lower/btrim(email).
- Dùng normalized column hoặc expression index đúng expression.
- Kiểm tra EXPLAIN và unique rule trước rollout.

### Challenge 2

Trong PostgreSQL, || với country NULL có thể làm customer_label NULL.

Cách 1, bỏ qua country NULL:

~~~sql
SELECT concat_ws(', ', full_name, country) AS customer_label
FROM sales.customers;
~~~

Cách 2, hiển thị giá trị mặc định:

~~~sql
SELECT concat(btrim(full_name), ', ', coalesce(country, '[unknown]')) AS customer_label
FROM sales.customers;
~~~

Hai cách có semantics business khác nhau: một cách bỏ qua field, một cách công khai trạng thái unknown.

### Challenge 3

Preview:

~~~sql
SELECT
    customer_id,
    full_name AS old_name,
    btrim(full_name) AS proposed_name
FROM sales.customers
WHERE full_name IS NOT NULL
  AND full_name <> btrim(full_name);
~~~

Sau review, có thể:

~~~sql
BEGIN;

UPDATE sales.customers
SET full_name = btrim(full_name)
WHERE full_name IS NOT NULL
  AND full_name <> btrim(full_name);

-- Chạy validation/đếm row ở đây.
ROLLBACK;
~~~

Production cần audit old/new values, batch strategy, duplicate check, lock review và quyết định COMMIT có kiểm soát.

### Challenge 4

Vấn đề:

- length(NULL) là NULL; WHERE length(...) > 0 loại row NULL một cách implicit.
- Chuỗi chỉ có spaces có length > 0 nhưng có thể rỗng theo business sau trim.
- length là character count, không giải quyết grapheme/byte.
- left trong SELECT chỉ là presentation; nếu lọc prefix cần access-path analysis.

Phiên bản cho rule có nội dung sau trim:

~~~sql
SELECT
    left(btrim(full_name), 2) AS prefix,
    char_length(btrim(full_name)) AS clean_length
FROM sales.customers
WHERE full_name IS NOT NULL
  AND btrim(full_name) <> '';
~~~

Nếu query chỉ cần filter raw length và không quan tâm whitespace thì biểu thức đơn giản hơn, nhưng phải viết rõ business rule.

## Kết luận tự chấm

Một câu trả lời engineering tốt phải tách bốn lớp: semantics SQL, data contract, performance plan và rollout safety. Một query trả đúng output trên sample nhỏ chưa chứng minh index, Unicode policy hay migration an toàn.
