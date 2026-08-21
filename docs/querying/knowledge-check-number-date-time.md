# Knowledge Check - Number, Date/Time, Formatting va Casting

## Multiple choice

1. PostgreSQL to_char(timestamp, pattern) tra ve:
   - A. date
   - B. numeric
   - C. text
   - D. interval

2. Predicate nao phu hop nhat de lay nam 2025?
   - A. extract(year FROM ordered_at) = 2025
   - B. to_char(ordered_at, 'YYYY') = '2025'
   - C. ordered_at >= start_2025 AND ordered_at < start_2026
   - D. ordered_at::date BETWEEN date '2025-01-01' AND date '2025-12-31'

3. Timestamptz phu hop nhat cho:
   - A. ngay sinh khong co gio
   - B. payment event can mot instant toan cau
   - C. ten thang hien thi
   - D. so luong san pham

4. Ham nao dua timestamp ve dau bucket thang?
   - A. extract
   - B. to_char
   - C. date_trunc
   - D. abs

5. Vi sao khong hard-code 23:59:59 lam end?
   - A. khong hop le SQL
   - B. co the bo sot fractional seconds
   - C. luon nhanh hon
   - D. vi date khong co timezone

6. DATEDIFF trong SQL Server can canh bao:
   - A. luon tra interval
   - B. dem datepart boundary, khong phai luon elapsed duration
   - C. chi dung cho string
   - D. luon theo UTC

## True/False

7. Format va cast la cung mot thao tac.
8. ordered_at::date co the phu thuoc TimeZone session.
9. ABS(-10) cho thay giao dich do la refund.
10. Seq Scan trong bang nho luon la loi.

## Short answer

11. Vi sao report theo thang nen group bang bucket date thay vi month_name?
12. Neu can tinh timeout 24 gio, can phan biet gi voi lich hang ngay?
13. Neu cast raw text sai lam transaction fail, pipeline nao an toan hon?

## Predict the output

14. Session TimeZone la Asia/Ho_Chi_Minh. Date cua bieu thuc sau la gi?

~~~sql
SELECT TIMESTAMPTZ '2025-02-28 23:30:00+00'::date;
~~~

15. Ket qua duration theo giay la bao nhieu?

~~~sql
SELECT extract(epoch FROM (
    TIMESTAMP '2025-03-01 10:00'
    - TIMESTAMP '2025-03-01 09:30'
));
~~~

## Query analysis

16. Neu query sau cham, hay neu hai nguyen nhan va viet lai predicate:

~~~sql
SELECT *
FROM sales.orders
WHERE date_trunc('month', ordered_at) = TIMESTAMP '2025-02-01';
~~~
