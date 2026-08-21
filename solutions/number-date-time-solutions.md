# Dap an bai tap - Ham so, ngay gio, dinh dang va casting

## Level 1 - Recall

1. date la calendar date; timestamp without time zone la wall-clock khong co instant; timestamptz bieu dien instant va hien thi theo timezone session.
2. round(numeric, digits) tra numeric; abs chi bo dau am, khong phan loai refund hay sua y nghia giao dich.
3. extract lay mot field va tra numeric; date_trunc dua gia tri ve dau bucket va van la date/time.
4. to_char tra text de presentation; CAST doi type de tinh, loc, constraint hoac mapping.
5. DATE '2025-01-01' + 7 va DATE '2025-01-01' + interval '1 month'.
6. column >= start AND column < exclusive_end; tranh lap boundary va tranh phu thuoc fractional precision.
7. Khong. SQL Server DATEDIFF dem datepart boundaries da vuot qua; duration elapsed can phep tru/epoch.
8. Khong co ISDATE y het. PostgreSQL dung typed cast co kiem soat, pg_input_is_valid tren version phu hop, staging hoac application validation.

## Level 2 - Apply

9. Dung CTE monthly:

~~~sql
WITH monthly AS (
    SELECT
        date_trunc(
            'month',
            ordered_at,
            'Asia/Ho_Chi_Minh'
        ) AS month_bucket,
        count(*) AS order_count
    FROM sales.orders
    GROUP BY 1
)
SELECT
    month_bucket,
    to_char(
        month_bucket AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'FMMonth YYYY'
    ) AS month_label,
    order_count
FROM monthly
ORDER BY month_bucket;
~~~

10. Quy 2 la boundary 2025-04-01 den truoc 2025-07-01 tai business timezone:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-04-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-07-01 00:00:00+07';
~~~

11. Dung interval va epoch, co dieu kien end:

~~~sql
SELECT
    extract(epoch FROM ended_at - started_at) / 60.0 AS elapsed_minutes
FROM events
WHERE ended_at IS NOT NULL
  AND ended_at >= started_at;
~~~

12. Dung date_trunc month lam start, cong 1 month lam next_start; last day la next_start tru 1 day roi cast date. Trong filter dung start va next_start.

13. Select to_char nhung ORDER BY ordered_at, khong ORDER BY output text. Neu phan trang, them order_id de tie-break.

14. Dung:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2026-01-01 00:00:00+07';
~~~

15. Dung lag(ordered_at) partition by customer_id order by ordered_at; tru current voi previous; loai NULL previous.

16. Raw phai nam trong staging. Tren PostgreSQL hien dai, dung pg_input_is_valid truoc cast; ghi invalid vao quarantine kem source_row va error reason. Neu khong co ham, validate bang parser/application hoac PL/pgSQL exception theo batch nho, khong cast mu quang toan bo batch.

## Level 3 - Engineering

17. Service validate year/month/timezone trong allow-list, tao local start tai dau thang, next local start, chuyen hai moc thanh instant; repository loc ordered_at >= from_instant va < to_instant. Timezone khong duoc lay ngau nhien tu session.

18. LocalDateTime khong mang zone/offset, nen cung gia tri co the la instant khac nhau o region khac. Migration: xac dinh y nghia du lieu cu, chon timestamptz/Instant cho event, backfill theo timezone legacy da tai lieu, them constraint/test va deploy tung buoc.

19. Rewrite to_char predicate thanh range. Expression index co the phu hop neu workload can group/filter theo cung bieu thuc, nhung phai doi storage, write overhead, timezone immutability va migration; do bang EXPLAIN.

20. 30 days la elapsed/calendar xap xi va sai theo business; 1 month la calendar nhung khong tu no biet 09:00 local; 24 hours la timeout. Quy tac hang thang luc 09:00 local can zone-aware scheduler, tinh local next occurrence roi chuyen sang instant.

21. Cast ve date phu thuoc session timezone. Sua bang explicit AT TIME ZONE Asia/Ho_Chi_Minh truoc cast, hoac loc/group bang boundary instant. Test moc truoc/sau midnight UTC va local, leap day, DST neu zone co DST.

22. Kiem tra: kich thuoc bang; selectivity; statistics va ANALYZE; estimated rows so actual rows voi EXPLAIN ANALYZE; ham/cast tren cot; type parameter; range co dung column goc khong; buffer/cache; query co tra phan lon bang khong.

23. Dung raw landing table, parse/validate theo chunk, valid vao typed table, invalid vao quarantine, metrics valid/invalid/unknown, idempotency key, source row va error reason. Cho reprocess sau khi sua mapping; khong mat raw.

24. Query online phu hop dataset nho va latency chap nhan; summary table phu hop dashboard on dinh va refresh theo batch; materialized view giam chi phi query nhung co stale data va lock/refresh trade-off. Multi-timezone can mo hinh bucket theo market zone, khong dung mot bucket UTC neu nghiep vu khac.

## Debugging prompts

25. Ham to_char tren cot tao text cho moi row va co the lam mat index. Rewrite cho thang 02/2025 bang:

~~~sql
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07'
~~~

26. ordered_at::date phu thuoc TimeZone session. Chuyen sang local timestamp explicit:

~~~sql
SELECT
    (ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS vn_date,
    count(*)
FROM sales.orders
GROUP BY 1
ORDER BY 1;
~~~

27. Year difference khong kiem tra birthday. Tinh birthday nam hien tai theo business timezone va giam 1 neu birthday chua den. Customer co timezone rieng can dung zone cua customer/market, khong dung mot session zone vo danh.

28. Raw cast sai lam ca statement fail va co the rollback transaction. Dung staging, validate truoc, insert valid rows rieng, quarantine invalid rows; them transaction boundary phu hop va audit.
