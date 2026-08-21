# Dap an Knowledge Check - Number, Date/Time, Formatting va Casting

1. C - to_char tra text.
2. C - range giu predicate tren column goc va co co hoi dung index.
3. B - payment event la instant toan cau.
4. C - date_trunc tra ve dau bucket.
5. B - timestamp co the co fractional seconds sau 23:59:59.
6. B - SQL Server DATEDIFF dem boundary cua datepart.
7. False. Format tao text; cast doi type.
8. True. Cast timestamptz ve date phu thuoc TimeZone session.
9. False. ABS chi bo dau am; khong phan loai nghiep vu.
10. False. Bang nho co the Seq Scan la plan hop ly.
11. Bucket date giu nam, thu tu chronologic va kieu typed; month_name co the gom nham cac nam va la text.
12. Timeout 24 gio la elapsed duration; lich hang ngay la calendar/timezone rule. Khong mac dinh 24 hours = next local 09:00.
13. Staging raw, validate truoc, valid vao typed table, invalid vao quarantine. Dung pg_input_is_valid tren PostgreSQL phu hop hoac parser/application.
14. 2025-03-01, vi 23:30 UTC + 7 gio = 06:30 ngay hom sau tai Vietnam.
15. 1800 giay.
16. Ham date_trunc tren column co the phai tinh cho nhieu row va khong dung index thuong. Rewrite cho thang 02/2025:

~~~sql
SELECT *
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07';
~~~

Neu can expression index cho workload group/filter lap lai, do EXPLAIN va can nhac chi phi write/storage; khong mac dinh tao ngay.
