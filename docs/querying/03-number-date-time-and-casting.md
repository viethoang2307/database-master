
# Lesson 3 - Ham so so, ngay gio, dinh dang va chuyen doi kieu du lieu

> Pham vi bai hoc: transcript 065-082.
> He quan tri muc tieu: PostgreSQL.
> Cac ham DATEPART, DATENAME, DATETRUNC, EOMONTH, FORMAT, CONVERT, ISDATE trong transcript la ten ham cua SQL Server; bai hoc nay viet lai theo PostgreSQL va ghi ro cac diem khac nhau.

# 1. Tong quan bai hoc

Bai hoc nay noi ve mot nhom thao tac xuat hien trong hau het backend va he thong bao cao:

- lam tron hoac lay gia tri tuyet doi cua so;
- doc mot thanh phan cua ngay gio, chang han nam, thang, quy, tuan, gio;
- gom du lieu theo mot bucket thoi gian nhu thang hoac ngay;
- tim ngay dau thang va cuoi thang;
- cong, tru va tinh khoang cach thoi gian;
- dinh dang gia tri de hien thi;
- chuyen doi kieu du lieu mot cach tuong minh;
- kiem tra du lieu ngay gio tu input khong tin cay.

Day khong phai la mot bai hoc ve viec nho ten ham. Dieu quan trong hon la phan biet ba muc dich:

1. Tinh toan: ket qua van phai la so hoac ngay gio de tiep tuc tinh.
2. Chuan hoa kieu du lieu: ket qua phai co type dung cho schema, predicate hoac API.
3. Trinh bay: ket qua chi danh cho nguoi doc, thuong la text.

Neu nham lan ba muc dich nay, he thong co the tra ket qua dung nhin be ngoai nhung sai logic, mat index, sai timezone hoac cham trong production.

## Kien thuc tien quyet

Nguoi hoc nen da biet:

- SELECT, WHERE, GROUP BY, ORDER BY;
- NULL va phep tinh ba tri;
- primary key, constraint va kieu du lieu co ban;
- su khac nhau giua date, timestamp va text o muc truc quan;
- cach doc mot execution plan don gian.

Schema xuyen suot repository nay nam trong schema sales:

- sales.orders.ordered_at la thoi diem tao don, kieu timestamptz;
- sales.customers.signup_date la ngay dang ky, kieu date;
- sales.products.unit_price la gia san pham, kieu numeric.

Transcript dung cac ten nhu order_date, ship_date va creation_time. Do schema thuc te cua repository dung ten khac, cac vi du ben duoi dung ordered_at. Khi can thoi diem giao hang, bai lab tao bang tam co cot ended_at de tranh gia lap mot cot khong ton tai.

## Learning Objectives

Sau bai hoc, nguoi hoc co the:

1. Dung round va abs dung muc dich, dong thoi giai thich tac dong cua chung len kieu numeric.
2. Phan biet date, timestamp without time zone va timestamptz trong PostgreSQL.
3. Chuyen mot thoi diem sang timezone nghiep vu ro rang truoc khi trich xuat ngay hoac gom nhom.
4. Chon extract, date_part, date_trunc, to_char va phep cast theo y dinh cua truy van.
5. Viet predicate loc theo khoang thoi gian co the su dung index.
6. Tinh start-of-month, end-of-month va duration ma khong nham giua elapsed time va calendar boundary.
7. Phan biet format voi cast; khong dung text da format lam khoa sap xep hoac khoa loc.
8. Thiet ke cach tiep nhan va validate date string tu API/import.
9. Doc EXPLAIN de nhan ra rui ro function-on-column va sai lech timezone.
10. Viet SQL PostgreSQL tuong duong cho cac ham SQL Server trong transcript.

## Ghi chu sua lai transcript

- Trong SQL Server, DATETRUNC la ham moi, khong phai mot ham SQL pho bien cua moi DBMS. PostgreSQL dung date_trunc; MySQL va Oracle co cach viet khac.
- DATEDIFF trong SQL Server dem so moc datepart bi vuot qua, khong phai luc nao cung la so giay hoac so ngay da troi qua theo nghia vat ly.
- MONTH(order_date) = 2 khong phai luon la cach loc tot nhat. Predicate tren cot goc theo khoang thoi gian thuong de optimizer dung index va tranh tron nam.
- ABS de sua doanh so am co the che dau loi nghiep vu. Nen xac dinh am la refund, reversal hay loi ETL truoc khi bien doi.
- PostgreSQL khong co mot ham ISDATE y het SQL Server. Co the dung cast trong pipeline co kiem soat, pg_input_is_valid tren PostgreSQL hien dai, hoac validation o staging/application.

# 2. Buc tranh lon

Mot request backend co the di qua cac lop sau:

~~~text
HTTP request
    |
    v
Controller / DTO parse
    |
    v
Service: xac dinh timezone va transaction boundary
    |
    v
SQL voi predicate theo khoang thoi gian
    |
    v
Parser -> Planner/Optimizer -> Execution plan
    |                              |
    |                              +--> Index scan / Bitmap scan
    |                              +--> Sequential scan
    v
Execution engine -> Buffer cache -> Disk pages
    |
    v
date/time arithmetic, aggregation, constraints
    |
    v
API response: format o boundary cuoi cung
~~~

Database khong luu ngay thang dep de hien thi; no luu gia tri theo type va thuc thi phep tinh tren type do. Vi du, mot bao cao theo thang co the can:

1. chuyen instant sang timezone cua thi truong;
2. cat ve dau thang;
3. group theo bucket;
4. tinh tong numeric;
5. format bucket thanh chuoi o buoc cuoi.

Neu format buoc 1 thanh text, optimizer mat thong tin kieu du lieu va logic sap xep/loc tro nen mong manh.

# 3. Giai thich tung khai niem

## 3.1 ROUND va ABS: phep tinh so co y nghia nghiep vu

### Truc quan

round la lam tron mot so den mot so chu so thap phan. abs la lay do lon khong am cua so. Ca hai deu la phep tinh, khong phai ham hien thi.

### Dinh nghia ky thuat

Trong PostgreSQL:

- round(numeric) lam tron numeric ve so nguyen;
- round(numeric, integer) lam tron den so chu so thap phan duoc chi dinh;
- abs(number) tra ve gia tri tuyet doi.

Voi numeric, PostgreSQL lam tron gia tri trung gian theo quy tac cua numeric. Khong nen suy ra moi DBMS hoac moi kieu floating point se co cung ket qua tai diem tiep xuc.

### Vi sao ton tai

Tien, thue, chiet khau, diem danh gia va metric thong ke co the co nhieu chu so hon muc nguoi dung can xem. Lam tron dung thoi diem giup:

- bao cao de doc;
- quyet dinh so sanh nhat quan;
- tranh hien thi cac sai so floating point khong co y nghia nghiep vu.

Nhung lam tron som co the lam mat do chinh xac. He thong thanh toan thuong luu numeric chinh xac, tinh theo quy tac tien te, roi moi round o ranh gioi nghiep vu.

### Cach hoat dong

~~~sql
SELECT
    round(3.516::numeric, 2) AS two_digits,
    round(3.516::numeric, 1) AS one_digit,
    round(3.516::numeric, 0) AS zero_digits,
    abs((-10)::numeric) AS absolute_value;
~~~

Ket qua ky vong:

~~~text
 two_digits | one_digit | zero_digits | absolute_value
------------+-----------+-------------+----------------
 3.52       | 3.5       | 4           | 10
~~~

So 3.516 duoc lam tron rieng cho tung bieu thuc. Ket qua van la numeric, khong phai text co dau phay dep de in ra man hinh.

### Vi du thuc te

Gia don hang nen tinh tren gia goc va chiet khau, sau do round theo chinh sach:

~~~sql
SELECT
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    round(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount_pct / 100),
        2
    ) AS line_total
FROM sales.order_items AS oi
WHERE oi.order_id = 1001;
~~~

Neu discount_pct la NULL, ca bieu thuc thanh NULL. Neu nghiep vu coi NULL la 0, phai viet co chu dich:

~~~sql
SELECT
    round(
        quantity * unit_price
        * (1 - coalesce(discount_pct, 0) / 100),
        2
    ) AS line_total
FROM sales.order_items
WHERE order_id = 1001;
~~~

ABS trong phan tich chenh lech:

~~~sql
SELECT
    order_id,
    total_amount,
    abs(total_amount - 100.00::numeric) AS distance_from_target
FROM (
    SELECT
        o.order_id,
        coalesce(sum(
            oi.quantity * oi.unit_price
            * (1 - coalesce(oi.discount_pct, 0) / 100)
        ), 0)::numeric AS total_amount
    FROM sales.orders AS o
    LEFT JOIN sales.order_items AS oi USING (order_id)
    GROUP BY o.order_id
) AS totals;
~~~

### Ben trong database

round/abs thuong la phep tinh CPU tren tung row. Neu ham nam trong SELECT va query da loc duoc it row, chi phi thuong nho. Neu ham nam trong WHERE tren hang tram trieu row, no co the phai tinh cho rat nhieu row; neu khong co expression index phu hop, planner kho khong the tim row bang index thuong.

### Tac dong hieu nang

- round/abs khong tu dong lam cham; so row can tinh moi la bien quan trong.
- numeric chinh xac thuong ton CPU va bo nho hon integer, nhung phu hop tien te hon floating point.
- round trong GROUP BY co the tao bucket khac voi viec round sau aggregation. Hai query sau khong tuong duong: sum sau khi round tung dong; round sau khi sum.
- abs(column) trong WHERE co the lam mat tinh sargable. Vi du abs(amount) < 10 co the can seq scan; neu co the viet amount BETWEEN -10 AND 10 thi planner co co hoi dung index tren amount.

### Loi thuong gap

- Dung ABS de bien giao dich am thanh doanh thu duong ma khong kiem tra refund/reversal.
- Round gia hang o moi buoc va tich luy sai so.
- Dung double precision cho tien roi ky vong ket qua decimal tuyet doi.
- Viet round(integer, 2) va cho rang moi DBMS se tu dong cho phep cung signature.
- Format so bang round roi concat thanh text, sau do lai dung text de tinh.

### Ghi chu production

Chot mot chinh sach: luu gia tri goc, tinh voi type phu hop, round tai diem quy dinh, va ghi ro rounding mode trong tai lieu nghiep vu. Doi voi tien, nen can nhac numeric(p,s), minor units integer, hoac mot money library o application tuy bai toan.

## 3.2 Date, time, timestamp va timezone

### Truc quan

date la mot ngay tren lich, khong co gio. time la gio trong ngay, khong co ngay. Mot instant trong he thong phan tan can bieu dien ca ngay gio va timezone/offset hoac mot quy uoc UTC.

### Dinh nghia trong PostgreSQL

PostgreSQL tach cac type sau:

- date: calendar date;
- time without time zone: gio trong ngay, khong gan timezone;
- timestamp without time zone: ngay gio wall-clock, khong tu no biet instant nao;
- timestamp with time zone, viet tat la timestamptz: mot instant duoc hien thi theo TimeZone cua session;
- interval: khoang thoi gian voi thanh phan month, day va time.

Ten timestamptz de gay nham: PostgreSQL khong luu mot chuoi timezone rieng theo cach nguoi moi hoc thuong tuong. No luu instant va chuyen doi cach hien thi theo timezone cua session. Khi can giu lai timezone goc cua nguoi dung, co the phai luu them cot zone_id.

### Vi sao ton tai

Phan biet type giup tranh nhung loi lon:

- ngay sinh khong nen bi tru 7 gio khi server doi timezone;
- thoi diem thanh toan can la mot instant duy nhat;
- gio mo cua cua hang co the la local time theo dia diem;
- bao cao ngay kinh doanh phai chon timezone, khong the mac dinh timezone cua laptop.

### Vi du

~~~sql
SELECT
    DATE '2025-02-28' AS business_date,
    TIME '09:30:00' AS local_opening_time,
    TIMESTAMP '2025-02-28 09:30:00' AS wall_clock_timestamp,
    TIMESTAMPTZ '2025-02-28 09:30:00+07' AS payment_instant;
~~~

Cung mot instant co the hien thi khac nhau:

~~~sql
SELECT
    TIMESTAMPTZ '2025-02-28 09:30:00+07' AS instant_in_session_zone,
    TIMESTAMPTZ '2025-02-28 09:30:00+07'
        AT TIME ZONE 'UTC' AS utc_wall_clock,
    TIMESTAMPTZ '2025-02-28 09:30:00+07'
        AT TIME ZONE 'America/New_York' AS new_york_wall_clock;
~~~

Bieu thuc AT TIME ZONE voi timestamptz tra ve timestamp without time zone: do la wall-clock time tai timezone yeu cau. Neu dung voi timestamp without time zone, no gan timestamp do vao timezone va tra ve timestamptz; hai chieu nay khac nhau.

### Internal behavior

Voi timestamptz, PostgreSQL quy doi input co offset ve mot instant. Khi select, server dung timezone cua session de render ket qua. Vi vay ket qua query co the hien khac giua hai connection neu SET TIME ZONE khac nhau, du gia tri instant goc giong nhau.

~~~sql
SET TIME ZONE 'Asia/Ho_Chi_Minh';

SELECT ordered_at, ordered_at::date
FROM sales.orders
ORDER BY ordered_at
LIMIT 3;
~~~

ordered_at::date la ngay theo timezone cua session, khong phai mot ngay UTC bat bien. Neu bao cao nghiep vu theo timezone khac, dung AT TIME ZONE hoac date_trunc co chi ro zone.

### Tac dong hieu nang va production

- Dung timestamptz cho event, payment, log, created_at, updated_at khi can mot instant toan cau.
- Dung date cho ngay nghiep vu khong co gio, nhu ngay sinh hoac ngay hieu luc.
- Dung timestamp without time zone cho wall-clock value khi timezone duoc quan ly boi context khac; khong dung no cho payment event neu khong co ly do ro rang.
- Luu timezone cua dia diem neu quy tac local time can duoc tai tao sau nay.
- Chuan hoa API: ISO 8601 co offset, vi du 2025-02-28T09:30:00+07:00, hoac UTC Z. Khong gui chuoi mo ho 02/03/2025.
- Index tren ordered_at khong giai quyet viec chon sai timezone; dung index tren cot dung van co the tra ket qua sai nghiep vu.

### Loi thuong gap

- Nghi timestamptz luu nguyen chuoi +07.
- Dung timestamp without time zone cho thoi diem can dong bo giua region.
- Lay ordered_at::date de bao cao theo Vietnam trong khi session dang la UTC.
- Format timezone o frontend nhung lai group theo UTC o database, lam tong ngay khong khop.
- Dung time de luu thoi diem giao dich.
- Dung mot timezone server lam timezone nghiep vu cho tat ca thi truong.


## 3.3 EXTRACT va date_part: lay thanh phan ngay gio

### Truc quan

EXTRACT khong tao bucket va khong format. No doc mot thanh phan tu ngay gio: nam, thang, quy, tuan ISO, gio hoac epoch.

### Dinh nghia

PostgreSQL co syntax theo SQL:

~~~sql
EXTRACT(field FROM source)
~~~

Ket qua la numeric. PostgreSQL cung co ham date_part(text, source), ve ban chat tuong tu va tra ve double precision trong tai lieu PostgreSQL. EXTRACT thuong de doc hon va portable hon trong cac he SQL ho tro syntax nay.

### Vi sao ton tai

Bao cao va phan tich can dimension tu thoi gian:

~~~sql
SELECT
    extract(year FROM ordered_at)::int AS order_year,
    extract(month FROM ordered_at)::int AS order_month,
    count(*) AS order_count
FROM sales.orders
GROUP BY 1, 2
ORDER BY 1, 2;
~~~

### Chuyen timezone truoc khi extract

Neu ordered_at la timestamptz, field phu thuoc cach database hien thi instant theo timezone. Bao cao theo thi truong Vietnam nen viet ro:

~~~sql
SELECT
    extract(year FROM ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int AS vn_year,
    extract(month FROM ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int AS vn_month,
    count(*) AS order_count
FROM sales.orders
GROUP BY 1, 2
ORDER BY 1, 2;
~~~

Cach nay tao timestamp without time zone tai Vietnam roi moi extract. Neu khong chi ro, ket qua co the phu thuoc TimeZone cua session.

### DATENAME cua transcript va PostgreSQL

SQL Server DATENAME tra ve text, vi du ten thang hoac thu. PostgreSQL khong co DATENAME cung ten. Hai cach tuong duong thuong gap:

- extract(month FROM value) cho so, phu hop tinh toan/grouping;
- to_char(value, 'FMMonth') cho ten thang, phu hop hien thi.

~~~sql
SELECT
    extract(month FROM ordered_at)::int AS month_number,
    to_char(
        ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'FMMonth'
    ) AS month_name
FROM sales.orders
ORDER BY ordered_at
LIMIT 5;
~~~

Ten thang phu thuoc locale/cach cai dat va format pattern. Khong dung month_name de sap xep chronologically. Neu can hien thi dung ngon ngu, co the format o application hoac dung locale/culture duoc kiem soat.

### Internal behavior va performance

EXTRACT thuong la phep tinh CPU. Trong GROUP BY tren bang lon, no co the tao nhieu group neu chon field qua chi tiet. extract(month FROM ordered_at) = 2 trong WHERE ap ham len cot; planner khong the su dung index ordered_at theo cach range binh thuong. Neu co business requirement loc tat ca thang 2 cua moi nam, can can nhac expression index, nhung thuong query can them nam va nen dung khoang bat dau/ket thuc.

### Vi du predicate dung hon

Khong nen viet cho nam 2025:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE extract(year FROM ordered_at) = 2025;
~~~

Nen viet khoang half-open, voi timezone nghiep vu ro rang:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2026-01-01 00:00:00+07'
ORDER BY ordered_at;
~~~

Predicate nay co the dung index tren ordered_at, khong phu thuoc do chinh xac microsecond cua ngay cuoi, va khong nham lan giua 31/12 va 01/01.

## 3.4 DATEPART va DATENAME trong transcript: dich sang PostgreSQL

### DATEPART la gi

Trong SQL Server, DATEPART(datepart, date) tra ve integer cho nam, thang, quy, tuan, weekday, hour, minute va nhieu thanh phan khac. PostgreSQL dung extract(field FROM source), nhung danh sach field, quy tac tuan va kieu ket qua co the khac.

Vi du tuong duong khong nen viet theo ten ham SQL Server trong PostgreSQL:

~~~sql
SELECT
    extract(quarter FROM ordered_at)::int AS quarter_number,
    extract(isoweek FROM ordered_at)::int AS iso_week,
    extract(isodow FROM ordered_at)::int AS iso_day_of_week,
    extract(hour FROM ordered_at)::int AS hour_of_day
FROM sales.orders;
~~~

isodow la thu theo ISO, thu 1 den 7. Neu dung week cua nam thong thuong, can doc ro quy tac ISO week-year; ngay dau nam co the thuoc ISO week-year truoc.

### DATENAME la gi

DATENAME trong SQL Server tra ve nvarchar cho mot datepart. PostgreSQL khong co mot ham portable co ten do. to_char la ham format ve text, vi vay phu hop cho presentation:

~~~sql
SELECT
    to_char(
        ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'FMDay'
    ) AS weekday_name,
    to_char(
        ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'FMMonth'
    ) AS month_name
FROM sales.orders;
~~~

Ket qua la text. No khong nen dung lam khoa group chinh neu co the group theo date hoac integer roi format o SELECT.

### Khi nao dung

- Dung DATEPART/EXTRACT cho filter, grouping, metric numeric khi khong co predicate range phu hop.
- Dung DATENAME/to_char cho nhan hien thi sau khi da co bucket date.
- Ghi ro DBMS trong code migration. Cung mot y nghia tuan co the khac giua ISO week va week theo locale.

## 3.5 DATETRUNC va date_trunc: cat ve dau bucket

### Truc quan

EXTRACT tra ve mot thanh phan. date_trunc tra ve mot gia tri date/time dai dien cho dau cua bucket. Vi du, moi thoi diem trong thang 02/2025 deu tro ve 2025-02-01 00:00:00 theo timezone/quy uoc da chon.

### Dinh nghia

PostgreSQL date_trunc(field, source) cat cac thanh phan nho hon field. Co overload cho timestamptz cho phep chi ro timezone trong cac phien ban hien dai:

~~~sql
date_trunc('month', ordered_at, 'Asia/Ho_Chi_Minh')
~~~

Ket qua cua overload nay la timestamptz tai moc dau thang theo timezone yeu cau. Neu phien ban khong ho tro overload, co the chuyen sang local timestamp bang AT TIME ZONE, trunc tai do, roi giu ro type.

### Vi sao ton tai

Gom nhom bang month_name de hien thi co the gom nham cac thang cua nhieu nam. Gom nhom bang date_trunc month giu duoc ca nam va thu tu tu nhien:

~~~sql
SELECT
    date_trunc(
        'month',
        ordered_at,
        'Asia/Ho_Chi_Minh'
    ) AS month_bucket,
    count(*) AS order_count
FROM sales.orders
GROUP BY 1
ORDER BY 1;
~~~

### Internal behavior

Planner co the tinh date_trunc cho tung row, tao group key va aggregate. Neu bang da co expression index phu hop, planner co the tan dung index cho mot so truy van; nhung GROUP BY van co the can doc nhieu row. Khong nen coi date_trunc la cach lam cho query nhanh tu dong.

### Filter theo bucket

De lay don trong thang 02/2025 tai Vietnam:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07'
ORDER BY ordered_at;
~~~

Cach nay thuong tot hon viec viet date_trunc('month', ordered_at, 'Asia/Ho_Chi_Minh') = moc. Predicate range bao toan bo thoi gian va co the dung B-tree index tren ordered_at.

### DATETRUNC cua SQL Server

SQL Server DATETRUNC co y tuong giong PostgreSQL date_trunc, nhung version va signature khac. Transcript minh hoa DATETRUNC de gom theo nam/thang la dung ve y tuong, nhung khong nen copy nguyen ten ham sang PostgreSQL.

## 3.6 EOMONTH va ngay dau/cuoi thang

### Truc quan

Bao cao thang thuong can interval [start, next_start), khong nhat thiet phai tim ngay cuoi. EOMONTH tra ve ngay cuoi thang de hien thi, deadline, hoac quy tac nghiep vu.

### PostgreSQL tuong duong

PostgreSQL khong co ham EOMONTH cung ten. Ta co the viet:

~~~sql
WITH month_start AS (
    SELECT date_trunc(
        'month',
        TIMESTAMPTZ '2025-02-18 14:30:00+07',
        'Asia/Ho_Chi_Minh'
    ) AS start_at
)
SELECT
    start_at::date AS first_day,
    (start_at + interval '1 month' - interval '1 day')::date AS last_day,
    (start_at + interval '1 month') AS exclusive_next_start
FROM month_start;
~~~

Neu can loc, dung exclusive_next_start. Vi du, khong viet <= '2025-02-28 23:59:59' vi co the bo sot microsecond sau do.

### Calendar month khac 30 ngay

Cong interval '1 month' la phep tinh calendar, khong phai 30 * 24 gio. Cuoi thang va leap year la ly do nen dung date_trunc/interval thay vi tu cong so ngay co dinh.

### Use case

- Chot so lieu den ngay cuoi thang.
- Tao nhan bao cao February 2025.
- Tinh ky billing.
- Tao predicate cho thang bang start va exclusive next start.

### Loi thuong gap

- Dung EOMONTH o SQL Server nhung deploy sang PostgreSQL khong co mapping.
- Dung ngay cuoi cung voi 23:59:59 va bo sot phan le giay.
- Dung month name lam khoa aggregation.
- Cho rang mot thang luon co 30 ngay.
- Khong xac dinh timezone khi start-of-month cua mot timestamptz.


## 3.7 FORMAT va to_char: bien gia tri thanh text de trinh bay

### Truc quan

Format thay doi cach gia tri duoc hien thi, khong nen thay doi y nghia du lieu. Sau khi format, ket qua thuong la text. Text phu hop cho label, email, CSV va UI; khong phu hop lam type trung gian cho phep tinh va loc.

### SQL Server FORMAT va PostgreSQL to_char

Transcript dung FORMAT(value, format [, culture]) cua SQL Server. PostgreSQL thuong dung to_char(value, pattern):

~~~sql
SELECT
    to_char(
        ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'YYYY-MM-DD HH24:MI:SS'
    ) AS display_time,
    to_char(
        1234567.5::numeric,
        'FM999G999G990D00'
    ) AS display_amount
FROM sales.orders
ORDER BY ordered_at
LIMIT 1;
~~~

Ket qua la text, vi du 2025-02-18 14:30:00 va 1,234,567.50 tuy locale/dau format. Pattern date co y nghia rieng: YYYY la nam, MM la thang, DD la ngay, HH24 la gio 24h.

PostgreSQL to_char cua numeric va timestamp khong phai SQL Server FORMAT. Khi migrate, viet test cho output va locale thay vi thay ten ham may moc.

### Vi sao ton tai

- Tao nhan bao cao co thang, nam, tien te.
- Tao chuoi timestamp trong log/export.
- Hien thi so 0 padding theo contract cua mot file.

### Internal behavior va performance

Formatting la phep tinh CPU va tao text. SQL Server FORMAT co the ton chi phi dang ke trong mot so workload vi no dua tren CLR; PostgreSQL to_char cung khong phai free. Khong format hang trieu row neu frontend co the format o application. Khong dung output format de filter:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE to_char(ordered_at, 'YYYY-MM') = '2025-02';
~~~

Query tren vua tao text cho moi row, vua de bi mat index thuong. Dung range:

~~~sql
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07';
~~~

### Sap xep text da format

ISO-like format YYYY-MM-DD co thu tu text trung voi thu tu ngay neu format co padding. FMMonth YYYY thi khong co tinh chat nay. Luon ORDER BY bucket date goc, chi select them label:

~~~sql
SELECT
    month_bucket,
    to_char(month_bucket, 'FMMonth YYYY') AS month_label,
    count(*) AS order_count
FROM (
    SELECT date_trunc(
        'month', ordered_at, 'Asia/Ho_Chi_Minh'
    ) AS month_bucket
    FROM sales.orders
) AS x
GROUP BY month_bucket
ORDER BY month_bucket;
~~~

## 3.8 CAST, :: va CONVERT: chuyen doi kieu du lieu

### Truc quan

CAST la noi rang ro: gia tri nay can duoc coi la kieu khac. No khac format: cast thay doi type va quy tac semantic; format tao text de doc.

### PostgreSQL syntax

SQL standard:

~~~sql
CAST(ordered_at AS date)
~~~

PostgreSQL co syntax rieng:

~~~sql
ordered_at::date
~~~

Hai bieu thuc tren cung y nghia trong nhieu truong hop, nhung CAST portable hon. SQL Server dung CAST(value AS type) va CONVERT(type, value, style). Tham so style cua CONVERT la dac thu SQL Server, khong co trong PostgreSQL.

### Vi du

~~~sql
SELECT
    ordered_at,
    CAST(ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS date) AS vn_business_date,
    CAST(order_id AS text) AS order_id_text
FROM sales.orders
ORDER BY ordered_at
LIMIT 5;
~~~

Ket qua cot vn_business_date la date, cot order_id_text la text. Khong nen cast order_id thanh text chi de join voi cot bigint cua bang khac; hai type nen thong nhat trong schema.

### Timestamptz va phep cast ve date

Voi timestamptz, cast ve date phu thuoc timezone cua session:

~~~sql
SET TIME ZONE 'UTC';

SELECT
    TIMESTAMPTZ '2025-02-28 23:30:00+07'::date AS utc_date;

SET TIME ZONE 'Asia/Ho_Chi_Minh';

SELECT
    TIMESTAMPTZ '2025-02-28 23:30:00+07'::date AS vietnam_date;
~~~

Cung instant co the cho hai date khac nhau. Neu business date la Vietnam, dung explicit AT TIME ZONE truoc cast, khong phu thuoc config ngau nhien:

~~~sql
SELECT
    (TIMESTAMPTZ '2025-02-28 23:30:00+07'
        AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS business_date;
~~~

### Loi thuong gap

- Dung cast de format va sau do quen mat ket qua la text.
- Cast timestamp thanh date truoc khi chon timezone.
- Dung :: trong code SQL can migrate sang DBMS khac ma khong ghi chu.
- CAST text khong hop le va lam ca transaction fail.
- Dung CONVERT cua SQL Server trong PostgreSQL.
- Cast join key de chua chay du lieu thay vi sua schema; cast tren cot co the lam join cham.

## 3.9 Parse va validation: thay the ISDATE trong PostgreSQL

### Truc quan

Input tu CSV, webhook hoac legacy database co the la text. Validation can tach khoi transformation:

1. giu raw value trong staging;
2. kiem tra no co hop le theo type va format expected khong;
3. chi cast vao bang chuan hoa neu hop le;
4. dua record loi vao quarantine, khong lam mat toan bo batch.

### ISDATE trong SQL Server

ISDATE(expression) tra 1 neu expression co the duoc nhan la datetime theo quy tac SQL Server hien tai, 0 neu khong. Ket qua chiu anh huong session/date format va co cac gioi han rieng, chang han tai lieu SQL Server ghi chu rang ISDATE khong validate datetime2 nhu nguoi dung co the mong doi.

### PostgreSQL khong co ISDATE cung ten

Voi du lieu da typed, phep cast binh thuong la strict:

~~~sql
SELECT CAST('2025-02-28' AS date);
~~~

Nhung cast chuoi sai se nem error, khong tra false. PostgreSQL hien dai co pg_input_is_valid cho mot so pipeline can kiem tra truoc khi cast:

~~~sql
SELECT
    raw_date,
    pg_input_is_valid(raw_date, 'date') AS is_valid_date
FROM (
    VALUES
        ('2025-02-28'),
        ('2025-02-30'),
        ('not-a-date'),
        (NULL)
) AS input(raw_date);
~~~

Ket qua mong doi: dong 2025-02-28 la true; hai chuoi sai la false; NULL can xu ly theo quy tac NULL cua input function va phien ban, nen can test tren version production.

Co the doc them thong tin loi bang pg_input_error_info tren PostgreSQL phu hop. Neu khong co cac ham nay, dung staging va application/parser de validate, hoac dung PL/pgSQL exception block voi batch nho.

### to_date khong phai strict validator tuyet doi

to_date(text, text) dung de parse format cu the:

~~~sql
SELECT to_date('28/02/2025', 'DD/MM/YYYY');
~~~

Nhung cac ham parse format co the cho phep mot so input thieu/duoc normalize theo quy tac pattern. Neu can strict validation, check raw text theo format expected, validate bang parser, sau do cast; dung coi viec to_date khong loi la bang chung duy nhat rang input phu hop nghiep vu.

### Production pattern

~~~sql
CREATE TEMP TABLE import_orders (
    source_row integer,
    raw_order_date text
);

INSERT INTO import_orders VALUES
    (1, '2025-02-28'),
    (2, '2025-02-30'),
    (3, '2025-03-01');

SELECT
    source_row,
    raw_order_date,
    CASE
        WHEN pg_input_is_valid(raw_order_date, 'date')
        THEN raw_order_date::date
        ELSE NULL
    END AS parsed_order_date
FROM import_orders;
~~~

Dong loi khong nen bi im lang. Can them status, error_reason va quarantine table de data steward xu ly.


## 3.10 DATEADD va phep tinh calendar

### Truc quan

DATEADD cua SQL Server cong hoac tru mot so luong vao mot datepart. PostgreSQL thuong dung toan tu + va - voi integer hoac interval.

### Mapping co ban

~~~sql
SELECT
    DATE '2025-01-31' + 1 AS next_day,
    DATE '2025-01-31' + INTERVAL '1 month' AS plus_one_calendar_month,
    TIMESTAMPTZ '2025-02-28 10:00:00+07'
        + INTERVAL '3 days' AS three_days_later,
    TIMESTAMPTZ '2025-02-28 10:00:00+07'
        - INTERVAL '2 hours' AS two_hours_earlier;
~~~

Voi date + integer, PostgreSQL cong so ngay. Voi timestamp/timestamptz, interval cho phep bieu dien month, day va time.

### Calendar month khong phai elapsed hours

Interval '1 month' mang y nghia lich. Interval '24 hours' mang y nghia elapsed duration. Trong timezone co DST, hai phep tinh co the cho wall-clock ket qua khac nhau:

~~~sql
SET TIME ZONE 'America/New_York';

SELECT
    TIMESTAMPTZ '2025-03-08 12:00:00-05' + INTERVAL '1 day' AS plus_calendar_day,
    TIMESTAMPTZ '2025-03-08 12:00:00-05' + INTERVAL '24 hours' AS plus_24_hours;
~~~

Ngay ca khi ket qua co the trung trong mot so timezone, code phai chon theo y nghia: nhac lich hang ngay hay timeout 24 gio.

### Use case backend

- expiry_at = created_at + interval '15 minutes';
- subscription_renewal = date_trunc('month', start_at) + interval '1 month';
- grace period = due_at + interval '3 days';
- khong dung dateadd/interval de sua timezone thieu trong input.

## 3.11 DATEDIFF, elapsed duration va calendar boundary

### Truc quan

Co it nhat ba cau hoi khac nhau:

1. Co bao nhieu ngay calendar giua hai date?
2. Bao nhieu giay/thoi gian vat ly da troi qua?
3. Co bao nhieu moc month/day/year da bi vuot qua?

Dung ham sai cau hoi se cho ket qua co ve hop ly nhung sai nghiep vu.

### PostgreSQL tinh duration

Voi date:

~~~sql
SELECT DATE '2025-03-10' - DATE '2025-03-01' AS elapsed_days;
~~~

Ket qua la integer 9. Voi timestamp:

~~~sql
SELECT
    TIMESTAMP '2025-03-01 10:00'
        - TIMESTAMP '2025-03-03 13:30' AS elapsed_interval,
    extract(epoch FROM (
        TIMESTAMP '2025-03-03 13:30'
        - TIMESTAMP '2025-03-01 10:00'
    )) AS elapsed_seconds;
~~~

Voi timestamptz, phep tru tinh tren instant; DST co the anh huong so giay. Ham age tra ve khoang theo calendar nam/thang/ngay, phu hop mot so bai toan tuoi lich:

~~~sql
SELECT age(DATE '2025-03-10', DATE '1990-03-15') AS calendar_age;
~~~

### DATEDIFF cua SQL Server khong phai duration tuyet doi

SQL Server DATEDIFF(datepart, startdate, enddate) tra ve so datepart boundaries bi cross. Hai timestamp chi cach nhau mot chut nhung cat qua midnight co the DATEDIFF(day) = 1. Vi vay mau tinh tuoi bang DATEDIFF(year, birthdate, current_date) co the tang them 1 truoc sinh nhat; can check month/day neu can tuoi chinh xac.

### Vi du shipping duration

Trong repository, sales.orders khong co ship_date. Neu bang that co shipped_at, co the viet:

~~~sql
SELECT
    order_id,
    shipped_at - ordered_at AS shipping_interval,
    extract(epoch FROM (shipped_at - ordered_at)) / 86400.0
        AS shipping_days
FROM sales.orders
WHERE shipped_at IS NOT NULL
  AND shipped_at >= ordered_at;
~~~

Trong PostgreSQL, khong so sanh interval voi integer mot cach tuy tien. Chon don vi va doi sang epoch hoac dung date difference neu chi quan tam calendar date.

### Khoang cach giua hai order lien tiep

~~~sql
WITH ordered AS (
    SELECT
        customer_id,
        order_id,
        ordered_at,
        lag(ordered_at) OVER (
            PARTITION BY customer_id
            ORDER BY ordered_at
        ) AS previous_ordered_at
    FROM sales.orders
)
SELECT
    customer_id,
    order_id,
    ordered_at - previous_ordered_at AS gap
FROM ordered
WHERE previous_ordered_at IS NOT NULL;
~~~

LAG la window function, khong phai ham date. Day la vi du cho thay date arithmetic thuong ket hop voi window, grouping va business key.

### Loi thuong gap

- Dung year difference de tinh tuoi chinh xac.
- Dung so ngay 30 cho moi thang.
- Dung timestamp local khong timezone de tinh SLA toan cau.
- Khong xu ly end < start, NULL, DST va ngay le.
- Chon datepart month roi ket luan da troi qua N thang day du.
- Dung now() trong migration/report ma khong ghi ro snapshot time.


# 4. Cac vi du SQL tong hop

Phan nay dung schema that cua repository. Chay bootstrap truoc:

~~~sql
\i sql/bootstrap/01_create_tables.sql
\i sql/bootstrap/02_seed_sales.sql
~~~

Neu dung psql, duong dan tren tinh tu current working directory. Cac query sau khong can ORM.

## 4.1 Tinh line total va lam tron

Schema: sales.order_items luu quantity, unit_price va discount_pct.

~~~sql
SELECT
    order_id,
    product_id,
    round(
        quantity * unit_price
        * (1 - coalesce(discount_pct, 0) / 100),
        2
    ) AS line_total
FROM sales.order_items
ORDER BY order_id, product_id;
~~~

Ket qua la numeric. Ham round o day la phep tinh tai row, khong phai format tien te. Neu can dau phay nghin hoac ky hieu tien, dung to_char o SELECT ngoai cung.

## 4.2 Bao cao theo thang tai Vietnam

~~~sql
SELECT
    date_trunc(
        'month',
        ordered_at,
        'Asia/Ho_Chi_Minh'
    ) AS month_bucket,
    count(*) AS order_count
FROM sales.orders
GROUP BY month_bucket
ORDER BY month_bucket;
~~~

month_bucket van la gia tri thoi gian, nen co the tiep tuc join, loc va sap xep. Neu PostgreSQL version khong co overload ba tham so, dung:

~~~sql
SELECT
    date_trunc(
        'month',
        ordered_at AT TIME ZONE 'Asia/Ho_Chi_Minh'
    ) AS local_month_bucket,
    count(*) AS order_count
FROM sales.orders
GROUP BY 1
ORDER BY 1;
~~~

O cach thu hai, bucket la timestamp without time zone, phu hop neu ta chi dang mo hinh hoa local business calendar.

## 4.3 Nhien thi ten thang nhung van sap xep bang date

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

month_bucket la khoa ky thuat; month_label chi la nhan. Neu label phu thuoc ngon ngu, co the format tai frontend.

## 4.4 Loc mot nam bang half-open interval

~~~sql
SELECT
    order_id,
    customer_id,
    ordered_at,
    order_status
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2026-01-01 00:00:00+07'
ORDER BY ordered_at;
~~~

Khoang dong-mo khong lap boundary voi nam sau va khong bo sot microsecond. Neu index tren ordered_at ton tai, day la hinh dang predicate phu hop voi B-tree.

## 4.5 Tim ngay dau va cuoi thang

~~~sql
WITH x AS (
    SELECT date_trunc(
        'month',
        TIMESTAMPTZ '2025-02-18 14:30:00+07',
        'Asia/Ho_Chi_Minh'
    ) AS start_at
)
SELECT
    start_at::date AS first_day,
    (start_at + interval '1 month' - interval '1 day')::date AS last_day,
    start_at + interval '1 month' AS next_start
FROM x;
~~~

Dung last_day khi can display. Dung next_start trong WHERE.

## 4.6 Tinh duration cua event

~~~sql
WITH events(event_id, started_at, ended_at) AS (
    VALUES
        (
            1,
            TIMESTAMPTZ '2025-02-28 09:00:00+07',
            TIMESTAMPTZ '2025-02-28 11:30:00+07'
        ),
        (
            2,
            TIMESTAMPTZ '2025-03-01 22:00:00+07',
            TIMESTAMPTZ '2025-03-02 01:00:00+07'
        )
)
SELECT
    event_id,
    ended_at - started_at AS elapsed_interval,
    round(
        (extract(epoch FROM (ended_at - started_at)) / 3600.0)::numeric,
        2
    ) AS elapsed_hours
FROM events
WHERE ended_at IS NOT NULL
  AND ended_at >= started_at;
~~~

Day la elapsed duration theo instant. Neu bai toan la "bao nhieu ngay lich co giao nhau", can mo hinh hoa khac.

# 5. Dieu gi xay ra ben trong?

Xem mot truy van loc don theo nam:

~~~text
Client
  |
  v
SQL text
  |
  v
Parser va analyzer
  - kiem tra syntax
  - resolve ten bang, cot, ham va type
  - tao bieu thuc logic
  |
  v
Planner / optimizer
  - doc statistics
  - uoc tinh cardinality va selectivity
  - so sanh sequential scan, index scan, bitmap scan
  |
  v
Execution plan
  - scan orders
  - ap predicate range
  - sort/group neu can
  |
  v
Buffer manager
  - tim page trong shared buffers
  - doc page tu storage neu chua co
  |
  v
Tuple visibility / MVCC
  - chi tra row ma snapshot hien tai duoc phep thay
  |
  v
Projection
  - extract, date_trunc, round, to_char
  |
  v
Result set
~~~

Trinh tu nay khong co nghia optimizer luon lam dung moi y dinh cua developer. Planner chi thay type, predicate, statistics va cost model. No khong biet "ngay kinh doanh cua chung ta la Vietnam" neu query khong noi ro.

## 5.1 Tai sao ham tren cot co the lam mat index

Voi index B-tree tren orders.ordered_at, index duoc sap xep theo gia tri ordered_at. Predicate:

~~~sql
ordered_at >= :start_at
AND ordered_at < :end_at
~~~

cho planner hai moc tren cung type. Planner co the tim nhanh phan range.

Predicate:

~~~sql
date_trunc('month', ordered_at) = :month
~~~

yeu cau tinh date_trunc cho gia tri truoc khi so sanh. PostgreSQL co the dung expression index neu bieu thuc va volatility phu hop, nhung index thuong tren ordered_at khong tu dong tro thanh index tren date_trunc(ordered_at). Thiet ke expression index chi sau khi do workload va can chap nhan chi phi write/storage.

## 5.2 Cardinality, selectivity va cost

- Cardinality la so row du kien hoac thuc te.
- Selectivity la ty le row thoa predicate.
- Index scan khong phai luon nhanh: neu predicate tra ve phan lon bang, seq scan co the re hon.
- Bang nho thuong duoc seq scan ngay ca khi co index vi chi phi random access va planner startup khong dang ke.
- Statistics cu hoac sai histogram co the lam estimated rows lech actual rows, dan den join/scan plan kem.

# 6. Mental models

1. Index khong phai mot bang nhanh hon. No la cau truc phu duoc duy tri de giam so page phai doc.

2. EXTRACT tra ve thanh phan; date_trunc tra ve bucket; to_char tra ve text; cast thay doi type.

3. Instant va wall-clock khong phai mot thu. Instant la diem tren timeline; wall-clock la cach diem do hien thi tai mot timezone.

4. Timezone la mot phan cua nghiep vu. "Ngay hom nay" khong co nghia neu chua noi ro timezone.

5. Khoang loc thoi gian nen la [start, exclusive_end). Boundary cuoi cung khong can chen vao 23:59:59.

6. DATEADD la cau hoi lich hay cau hoi elapsed? Cong 1 day va cong 24 hours co the khac nhau quanh DST.

7. Format la presentation. Neu mot gia tri da thanh text de hien thi, dung no lam du lieu trung gian cho tinh toan la mot dau hieu can xem lai.

8. ABS khong sua du lieu. No chi bo dau am; y nghia refund, reversal hay loi nhap lieu van can duoc mo hinh hoa.

9. DATEDIFF co the dem moc lich, khong phai do chinh xac khoang thoi gian. Luon viet ra cau hoi nghiep vu truoc khi chon ham.

# 7. So sanh cac khai niem de nham lan

## 7.1 EXTRACT, date_trunc, to_char va CAST

| Cong cu | Muc dich | Kieu ket qua | Noi dung noi bo | Su dung dien hinh |
| --- | --- | --- | --- | --- |
| EXTRACT | Lay nam, thang, gio, epoch | numeric | Doc mot field tu gia tri | group/filter/metric |
| date_trunc | Dua ve dau bucket | timestamp/timestamptz | Cat cac field nho hon | group theo ngay/thang |
| to_char | Hien thi theo pattern | text | Render value thanh chuoi | API label, report |
| CAST | Chuyen kieu | type dich | Ap dung quy tac cast | schema, predicate, API type |

## 7.2 date, timestamp without time zone, timestamptz

| Type | Co ngay | Co gio | Bieu dien instant | Vi du |
| --- | --- | --- | --- | --- |
| date | Co | Khong | Khong | ngay sinh |
| time | Khong | Co | Khong | gio mo cua local |
| timestamp | Co | Co | Khong tu no | wall-clock da co context |
| timestamptz | Co | Co | Co | payment event, created_at |

## 7.3 DATEDIFF, phep tru va age

| Cach | Tra loi cau hoi | Ket qua | Rui ro |
| --- | --- | --- | --- |
| date2 - date1 | Bao nhieu ngay lich giua hai date | integer | Khong co gio |
| timestamp2 - timestamp1 | Khoang thoi gian da troi qua | interval | Can doi epoch neu can so giay |
| extract(epoch FROM interval) | Bao nhieu giay | numeric | DST va timezone can ro |
| age(end, start) | Khoang calendar nam/thang/ngay | interval | Khong phai SLA elapsed |
| SQL Server DATEDIFF | Bao nhieu boundary datepart da vuot | integer | Khong phai duration tuyet doi |

## 7.4 Ten ham trong transcript va PostgreSQL

| SQL Server | PostgreSQL thuong dung | Ket qua PostgreSQL | Luu y |
| --- | --- | --- | --- |
| ROUND | round | numeric | Signature co the khac |
| ABS | abs | numeric/number | Khong sua nghiep vu |
| DAY/MONTH/YEAR | extract(day/month/year FROM ...) | numeric | Chuyen timezone neu can |
| DATEPART | extract | numeric | Week rule can kiem tra |
| DATENAME | to_char | text | Presentation |
| DATETRUNC | date_trunc | timestamp/timestamptz | Version/signature khac |
| EOMONTH | date_trunc + interval | date/timestamp | Dung exclusive next start khi loc |
| FORMAT | to_char | text | Khong dong nhat culture |
| CONVERT | CAST hoac :: | type dich | Style la dac thu SQL Server |
| DATEADD | + interval | date/time | Phan biet calendar/elapsed |
| DATEDIFF | tru, epoch, age | interval/numeric | Cau hoi nghiep vu khac |
| ISDATE | pg_input_is_valid/staging | boolean/validation flow | Khong co ham universal |

# 8. Goc nhin Backend Engineering

## 8.1 API va hop dong ngay gio

Tai boundary HTTP:

- nhan instant bang ISO 8601 co offset hoac UTC;
- parse mot lan va chuyen sang type co y nghia;
- khong de moi repository tu do chon timezone;
- response co the tra ISO UTC, hoac tra local time kem timezone/offset neu UI can.

Vi du service co the nhan from va to la Instant. Repository dung:

~~~sql
WHERE ordered_at >= :from_instant
  AND ordered_at < :to_instant
~~~

Service chiu trach nhiem chuyen "thang 2 tai Vietnam" thanh hai instant boundary. Database chiu trach nhiem loc theo type va index.

## 8.2 Transaction boundary

Date arithmetic co the tham gia transaction:

- tao order;
- tinh expiry;
- ghi outbox event;
- commit cung nhau.

Khong nen lay now() o nhieu service khac nhau va mong cac moc trung tuyet doi. Chon mot clock/snapshot trong transaction khi nghiep vu can nhat quan.

## 8.3 Pagination

Khong phan trang bang chuoi date da format:

~~~sql
ORDER BY to_char(ordered_at, 'YYYY-MM-DD HH24:MI:SS'), order_id
~~~

Hay dung keyset pagination tren type goc:

~~~sql
SELECT order_id, ordered_at, order_status
FROM sales.orders
WHERE (ordered_at, order_id) < (:last_ordered_at, :last_order_id)
ORDER BY ordered_at DESC, order_id DESC
LIMIT 50;
~~~

Cach nay giu thu tu chronologic va tranh format text. Can index phu hop, chang han B-tree tren ordered_at va order_id.

## 8.4 Bao cao va N+1

Một API dashboard co the can 12 thang. Khong goi 12 query rieng moi query dung EXTRACT. Dung mot query group by date_trunc, tra ve 12 row. N+1 khong chi la van de ORM; no la van de ranh gioi truy van va so round-trip.

## 8.5 Connection pool va TimeZone

Neu mot request thay doi SET TIME ZONE tren connection pooled ma khong reset, request sau co the nhan ket qua khac. Co ba cach:

- dat timezone mac dinh ro o connection;
- luon dung expression explicit AT TIME ZONE trong query quan trong;
- reset session state khi tra connection ve pool.

Khong coi timezone cua client la timezone cua database.

# 9. Goc nhin ORM: JPA/Hibernate

Raw SQL phai duoc hieu truoc ORM. JPA mapping co the dung:

~~~java
@Entity
class OrderEntity {
    @Id
    private Long orderId;

    private Instant orderedAt;

    private LocalDate businessDate;
}
~~~

Goi y:

- Instant phu hop cho instant toan cau;
- LocalDate phu hop ngay khong co gio;
- OffsetDateTime giu offset trong object, nhung database mapping van can quy uoc;
- tranh map event quan trong vao LocalDateTime neu thuc te can timezone.

JPQL co the loc bang range:

~~~java
@Query("""
    select o
    from OrderEntity o
    where o.orderedAt >= :from
      and o.orderedAt < :to
    order by o.orderedAt, o.orderId
    """)
List<OrderEntity> findOrders(
    Instant from,
    Instant to
);
~~~

Hibernate co the tao SQL range tren cot ordered_at. Kiem tra SQL that trong log va EXPLAIN; annotation khong bao dam index.

Date trunc khong portable trong JPQL. Mot truy van PostgreSQL co the dung function native:

~~~java
@Query("""
    select function('date_trunc', 'month', o.orderedAt), count(o)
    from OrderEntity o
    group by function('date_trunc', 'month', o.orderedAt)
    order by function('date_trunc', 'month', o.orderedAt)
    """)
List<Object[]> countByMonth();
~~~

Cach nay phu thuoc PostgreSQL va version. Neu can portability, co the group theo date bucket o application voi dataset nho, tao view/reporting table, hoac viet repository implementation theo dialect. Khong dung ORM de che mat type, timezone va execution plan.

# 10. Performance Engineering

## 10.1 EXPLAIN co ban

~~~sql
EXPLAIN (COSTS, VERBOSE)
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-01-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2026-01-01 00:00:00+07';
~~~

Doc:

- Seq Scan: doc nhieu/all page cua relation.
- Index Scan: di qua index roi lay tuple.
- Bitmap Index Scan + Bitmap Heap Scan: thuong dung khi co nhieu match va can tap page.
- rows: so row planner uoc tinh, khong phai ket qua chac chan.
- cost: don vi noi bo de so sanh plan, khong phai milliseconds.
- actual time/rows: chi co khi dung EXPLAIN ANALYZE.

Dung EXPLAIN ANALYZE tren SELECT an toan hon tren DML, nhung no van thuc thi truy van va co the ton tai tai nguyen:

~~~sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07';
~~~

Neu bang seed nho, planner co the chon Seq Scan. Day khong phai bang chung rang range predicate sai; hay test voi cardinality production.

## 10.2 Do selectivity

Predicate loc mot thang trong 10 nam co selectivity thap, index co the huu ich. Predicate loc mot nam trong bang chi co mot nam co selectivity cao theo nghia tra ve nhieu row; seq scan co the tot hon.

EXTRACT trong SELECT thuong vo hai hon EXTRACT trong WHERE. Ham tren cot trong WHERE can duoc xem xet cung:

- cardinality;
- expression index;
- generated column/materialized reporting key;
- range rewrite;
- timezone business.

## 10.3 Index goi y

~~~sql
CREATE INDEX IF NOT EXISTS idx_orders_ordered_at
ON sales.orders (ordered_at);
~~~

Query dung index hay khong la quyet dinh cua planner, khong phai cam ket. Sau khi tao index:

~~~sql
ANALYZE sales.orders;
~~~

Khong tao index cho moi ham. Moi index them chi phi INSERT/UPDATE, WAL, storage va vacuum. Date/time index can gan voi query production that.


# 11. Cau hoi phong van

Phan nay co 15 cau, chia theo muc do. Cac cau tra loi tap trung vao reasoning.

## Junior

### C1. ROUND khac FORMAT o diem nao?

**Tra loi:** round la phep tinh tren so va van tra ve so; FORMAT/to_char tao text de trinh bay. Khong dung text da format lam input cho phep tinh neu khong can thiet.

### C2. Khi nao dung date va khi nao dung timestamptz?

**Tra loi:** dung date cho ngay khong co gio nhu ngay sinh; dung timestamptz cho instant toan cau nhu payment, event, created_at. Chon timestamp without time zone cho wall-clock co context ro rang, khong phai de tranh hieu biet timezone.

### C3. EXTRACT(month FROM ordered_at) tra ve gi?

**Tra loi:** PostgreSQL tra ve numeric dai dien cho thang. Co the cast sang int neu API can integer. Voi timestamptz, ket qua phu thuoc timezone hien thi, nen phai chon timezone nghiep vu.

### C4. Tai sao dung AT TIME ZONE?

**Tra loi:** de chuyen mot instant sang wall-clock cua timezone cu the, hoac gan timezone cho timestamp without time zone theo ngu canh. No lam ro quy uoc thay vi phu thuoc session.

### C5. Tai sao predicate range thuong tot hon EXTRACT(year ...) = 2025?

**Tra loi:** range giu cot goc trong phep so sanh, cho planner co co hoi dung B-tree index; no cung tranh phai tinh ham tren tung row.

## Mid-level

### C6. ordered_at::date co phai luon la ngay UTC khong?

**Tra loi:** khong. Voi timestamptz, cast ve date phu thuoc TimeZone cua session. Neu can ngay Vietnam, chuyen AT TIME ZONE Asia/Ho_Chi_Minh truoc khi cast.

### C7. Vi sao <= 2025-02-28 23:59:59 kem an toan hon [start, next_start)?

**Tra loi:** timestamp co the co fractional seconds sau 23:59:59, nen predicate co the bo sot row. Dung >= start AND < next_start khong phu thuoc precision.

### C8. DATEDIFF(day) cua SQL Server co phai luon la so ngay da troi qua?

**Tra loi:** khong. No dem so boundary day bi vuot qua. Hai thoi diem cach nhau vai phut nhung qua midnight co the cho 1.

### C9. Khi nao mot function-on-column van co the dung index?

**Tra loi:** khi co expression index phu hop, generated column/indexed computed column theo DBMS, hoac optimizer co kha nang rewrite. Khong duoc gia dinh index thuong tren column se tu dong dung duoc.

### C10. Tai sao format o SQL de hien thi co the lam API cham?

**Tra loi:** database phai tao text cho moi row, ton CPU va allocation. Neu UI co the format o application va query can tra nhieu row, de database tra type goc thuong tot hon.

## Senior / Deep Understanding

### C11. Bao cao doanh thu theo ngay Vietnam can xu ly mot cot timestamptz nhu the nao?

**Tra loi:** xac dinh business timezone, chuyen instant sang timezone do truoc khi date_trunc/extract, group theo bucket date/time, va loc bang instant range da quy doi. Khong phu thuoc TimeZone mac dinh cua connection.

### C12. Date_trunc trong GROUP BY co van de gi voi DST?

**Tra loi:** bucket calendar phai gan voi timezone. Neu dung session timezone khac timezone nghiep vu, row gan boundary local co the vao ngay/thang khac. Dung overload co zone hoac trunc tren local timestamp, va test cac moc DST neu thi truong co DST.

### C13. So sanh cong interval 1 day voi 24 hours.

**Tra loi:** 1 day trong interval co y nghia calendar va co the giu wall-clock time qua DST; 24 hours la elapsed duration. Chon theo nghiep vu: reminder hang ngay hay timeout vat ly.

### C14. Tai sao luu raw date text va date typed trong pipeline import?

**Tra loi:** raw giup audit va reprocess; typed giup constraint, index va phep tinh. Tach staging/quarantine giup mot dong loi khong rollback ca batch va khong lam mat du lieu goc.

### C15. Khi planner chon Seq Scan cho query co index date, ban dieu tra gi?

**Tra loi:** kiem tra bang co nho khong, selectivity, statistics/analyze, estimated rows so voi actual rows, function/cast tren cot, type cua parameter, timezone boundary, visibility map, va chi phi random access. Khong tao index mu hoac ep hint truoc khi doc plan.

# 12. Cac dieu developer hay hieu sai

## Wrong idea: Them index luon lam query nhanh

**Vi sao sai:** index them write overhead, storage va random access. Neu predicate tra ve phan lon bang, seq scan co the re hon.

**Mental model dung:** index la mot cau truc bo sung de giam I/O cho workload cu the; do hieu qua bang EXPLAIN va metric production.

## Wrong idea: Timestamptz luu timezone goc cua chuoi

**Vi sao sai:** PostgreSQL luu instant; cach hien thi phu thuoc timezone session. Zone goc co the mat.

**Mental model dung:** neu can tai tao local time/zone ban dau, luu them zone_id.

## Wrong idea: Format ngay thanh text roi loc se de hon

**Vi sao sai:** mat type, ton CPU va co the mat index.

**Mental model dung:** loc bang range typed; format o SELECT cuoi hoac application.

## Wrong idea: Month 2 chi can MONTH(date) = 2

**Vi sao sai:** no gom tat ca thang 2 cua moi nam; ham tren cot co the lam query cham.

**Mental model dung:** neu co nam, dung [2025-02-01, 2025-03-01); neu can tat ca February, can business definition va co the dung expression index/reporting key.

## Wrong idea: DATEDIFF(year) cho tuoi chinh xac

**Vi sao sai:** year boundary co the da vuot truoc sinh nhat.

**Mental model dung:** tinh year difference roi giam 1 neu chua qua birthday, hoac dung date comparison ro rang.

## Wrong idea: ABS la cach sua doanh thu am

**Vi sao sai:** no xoa dau am va che dau refund/reversal/ETL bug.

**Mental model dung:** giu sign co y nghia, phan loai transaction type, chi dung ABS khi bai toan that su la distance/magnitude.

## Wrong idea: 1 month = 30 days

**Vi sao sai:** calendar month dai ngan khac nhau va co leap year.

**Mental model dung:** dung date_trunc + interval month, va viet boundary ro.

# 13. Tinh huong loi trong production

## 13.1 Doanh thu cua ngay bi tach sai timezone

**Hien tuong:** Dashboard Vietnam cua 01/03 thieu cac don luc 00:00-07:00.

**Nguyen nhan:** Query dung ordered_at::date trong session UTC, trong khi nguoi dung mong date Vietnam.

**Cach sua:** tao from_instant va to_instant bang timezone Asia/Ho_Chi_Minh, loc ordered_at theo range; hoac chuyen local timestamp explicit truoc khi group. Them test cho row tai boundary.

## 13.2 Bao cao thang cham sau khi doi query

**Hien tuong:** Query cu loc nam bang range mat 20 ms; query moi dung to_char(ordered_at, 'YYYY-MM') mat nhieu giay.

**Nguyen nhan:** format tung row va khong su dung index thuong.

**Cach sua:** range predicate; group bang date_trunc trong SELECT/GROUP BY; neu can reporting nhieu, tao summary table hoac expression index sau khi do workload.

## 13.3 Tinh expiry sai quanh DST

**Hien tuong:** Reminder hang ngay chay luc 12:00 mot so ngay, luc 11:00 sau khi doi DST.

**Nguyen nhan:** Dung 24 hours cho quy tac lich hang ngay.

**Cach sua:** luu zone cua user, tinh local calendar next occurrence, sau do chuyen thanh instant. Dung 24 hours chi cho timeout that su.

## 13.4 Import bi rollback ca batch

**Hien tuong:** Mot dong co 2025-02-30 lam ca 100000 dong insert fail.

**Nguyen nhan:** cast text truc tiep trong mot INSERT.

**Cach sua:** staging raw, validate theo batch, ghi invalid rows vao quarantine, chi insert rows valid. Giu source_row va error reason de audit.

## 13.5 Tuoi khach hang tang som mot nam

**Hien tuong:** User sinh 15/09 bi hien 35 tuoi vao 14/09.

**Nguyen nhan:** dung DATEDIFF year hoặc date_part year don gian.

**Cach sua:** tinh so nam, sau do so sanh birthday nam hien tai voi current date trong timezone nghiep vu.

# 14. Hands-on Lab PostgreSQL

Lab day du nam trong sql/querying/03_number_date_time.sql. Chay tren PostgreSQL local.

## Setup

Tao bang tam co event timestamp, amount va raw date. Neu chay lai trong cung session, xoa bang tam cu truoc:

~~~sql
DROP TABLE IF EXISTS lab_events;

CREATE TEMP TABLE lab_events (
    event_id integer PRIMARY KEY,
    occurred_at timestamptz NOT NULL,
    ended_at timestamptz,
    amount numeric(12,3),
    raw_date text,
    raw_number text
);

INSERT INTO lab_events VALUES
    (1, '2025-01-31 23:30:00+07', '2025-02-01 01:00:00+07',
     3.516, '2025-01-31', '12.345'),
    (2, '2025-02-01 00:05:00+07', '2025-02-01 00:20:00+07',
     -10.250, '2025-02-30', '-8.50'),
    (3, '2025-02-28 12:00:00+07', '2025-03-01 12:30:00+07',
     100.005, '2025-02-28', 'bad'),
    (4, '2025-03-01 00:00:00+07', NULL,
     NULL, NULL, '42');
~~~

## Experiment 1 - Round va ABS

**Prediction:** row 1 se thanh 3.52 neu round 2 chu so; amount am se abs thanh so duong.

**Run:**

~~~sql
SELECT
    event_id,
    amount,
    round(amount, 2) AS rounded_amount,
    abs(amount) AS magnitude
FROM lab_events
ORDER BY event_id;
~~~

**Observe:** NULL van la NULL. ABS khong cho biet ly do amount am.

**Explanation:** round/abs la numeric computation; khong tao text.

## Experiment 2 - Timezone va business date

**Prediction:** event 1 co the nam o ngay 31/01 hoac 01/02 tuy timezone hien thi.

**Run:**

~~~sql
SELECT
    event_id,
    occurred_at,
    occurred_at AT TIME ZONE 'UTC' AS utc_wall_clock,
    occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh' AS vn_wall_clock,
    (occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS vn_date
FROM lab_events
ORDER BY event_id;
~~~

**Observe:** so sanh utc_wall_clock, vn_wall_clock va vn_date.

**Explanation:** instant giong nhau, wall-clock khac nhau. Business date can chon timezone.

## Experiment 3 - Extract va trunc

**Prediction:** event 1 va event 2 deu co month bucket thang 01/2025 va 02/2025 theo Vietnam; date_trunc tra ve moc dau thang.

**Run:**

~~~sql
SELECT
    event_id,
    extract(year FROM occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int AS year_number,
    extract(month FROM occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::int AS month_number,
    date_trunc(
        'month',
        occurred_at,
        'Asia/Ho_Chi_Minh'
    ) AS month_bucket
FROM lab_events
ORDER BY occurred_at;
~~~

**Observe:** extract la numeric/integer sau cast; month_bucket la timestamp/timestamptz.

## Experiment 4 - Start/end month

**Prediction:** thang 02/2025 co ngay dau 01 va ngay cuoi 28.

**Run:**

~~~sql
WITH x AS (
    SELECT date_trunc(
        'month',
        TIMESTAMPTZ '2025-02-28 12:00:00+07',
        'Asia/Ho_Chi_Minh'
    ) AS start_at
)
SELECT
    start_at::date AS first_day,
    (start_at + interval '1 month' - interval '1 day')::date AS last_day,
    start_at + interval '1 month' AS next_start
FROM x;
~~~

**Observe:** next_start la boundary de dung trong WHERE, khong phai timestamp cuoi cung can hard-code.

## Experiment 5 - Elapsed duration

**Prediction:** event 1 keo dai 1.5 gio; event 4 co ended_at NULL nen khong tinh duoc.

**Run:**

~~~sql
SELECT
    event_id,
    ended_at - occurred_at AS elapsed_interval,
    extract(epoch FROM ended_at - occurred_at) / 3600.0
        AS elapsed_hours
FROM lab_events
WHERE ended_at IS NOT NULL;
~~~

**Observe:** interval co the hien thi dang days/hours; epoch cho so giay.

## Experiment 6 - Format va cast

**Prediction:** display_time la text; vn_date la date. Hai cot co the in giong nhau nhung co type khac.

**Run:**

~~~sql
SELECT
    event_id,
    to_char(
        occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh',
        'YYYY-MM-DD HH24:MI:SS'
    ) AS display_time,
    (occurred_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AS vn_date
FROM lab_events
ORDER BY event_id;
~~~

**Observe:** dung pg_typeof neu can:

~~~sql
SELECT
    pg_typeof(to_char(occurred_at, 'YYYY-MM-DD')) AS formatted_type,
    pg_typeof(occurred_at::date) AS cast_type
FROM lab_events
LIMIT 1;
~~~

## Experiment 7 - Validate raw date

**Prediction:** 2025-02-30 va not-a-date khong hop le; NULL khong phai mot date hop le.

**Run tren PostgreSQL hien dai:**

~~~sql
SELECT
    event_id,
    raw_date,
    pg_input_is_valid(raw_date, 'date') AS valid_date
FROM lab_events
ORDER BY event_id;
~~~

**Observe:** Neu server khong co pg_input_is_valid, bo qua query nay va dung staging/application validation. Khong cast truc tiep toan bo raw_date khi chua co quy trinh xu ly loi.

## Experiment 8 - EXPLAIN range

**Prediction:** bang nho co the Seq Scan; day khong phai loi.

**Run:**

~~~sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, ordered_at
FROM sales.orders
WHERE ordered_at >= TIMESTAMPTZ '2025-02-01 00:00:00+07'
  AND ordered_at <  TIMESTAMPTZ '2025-03-01 00:00:00+07';
~~~

**Observe:** node scan, estimated rows, actual rows, Buffers. Tao index roi EXPLAIN lai chi de so sanh, khong ep ket qua:

~~~sql
CREATE INDEX IF NOT EXISTS idx_lab_orders_ordered_at
ON sales.orders (ordered_at);

ANALYZE sales.orders;
~~~


# 15. Bai tap

Khong xem ngay dap an. Viet prediction va ly do truoc khi chay.

## Level 1 - Recall

1. Phan biet date, timestamp without time zone va timestamptz.
2. ROUND tra ve type gi trong PostgreSQL?
3. to_char dung de tinh toan hay presentation?
4. Vi sao date_trunc khac extract?
5. Viet PostgreSQL tuong duong cho DATEADD 7 days.
6. Predicate half-open co dang nao?
7. Vi sao ABS khong phai cach sua refund?
8. DATEDIFF year co the sai tuoi o truoc birthday vi sao?

## Level 2 - Apply

1. Viet query dem so don theo thang Vietnam, group theo bucket date va hien thi month label.
2. Viet query lay tat ca don trong quy 2/2025 ma van cho planner co co hoi dung index.
3. Cho started_at va ended_at, tinh elapsed minutes va loai bo row end truoc start.
4. Cho raw_date text, thiet ke query/flow tach valid rows va invalid rows.
5. Viet query tinh ngay dau va exclusive next start cho thang cua mot parameter.
6. Chuyen mot output month_name thanh query sap xep dung chronologic ma khong ORDER BY text.
7. Giai thich ket qua cua cast timestamptz ve date khi session timezone la UTC va Asia/Ho_Chi_Minh.
8. Viet query tim khoang cach giua hai order lien tiep cua moi customer bang LAG.

## Level 3 - Engineering

1. API bao cao nhan year=2025, month=2, timezone=Asia/Ho_Chi_Minh. Thiet ke service boundary va SQL predicate.
2. He thong thanh toan luu created_at la timestamp without time zone. Danh gia rui ro va de xuat migration an toan.
3. Import 10 trieu dong co date text khong dong nhat. Thiet ke staging, quarantine, metric loi va cach reprocess.
4. Query dung to_char trong WHERE chay cham sau khi bang tang 100 lan. De xuat cach do va sua.
5. Business noi gia han hang thang vao 9:00 local time. So sanh interval 30 days, interval 1 month va local calendar scheduling.
6. Planner chon Seq Scan du co index ordered_at. Lap checklist chan doan khong dung force index.
7. Dashboard can 10 nam du lieu theo month va market timezone. Chon query online, summary table hay materialized view; neu ro trade-off.
8. JPA method dung LocalDateTime cho payment event va client o nhieu timezone. Viet risk assessment va contract mapping moi.

# 16. Thach thuc debug

## Challenge 1 - Sai index do format

~~~sql
SELECT count(*)
FROM sales.orders
WHERE to_char(ordered_at, 'YYYY-MM') = :month_text;
~~~

Hoi:

- Tai sao co the cham?
- Rewrite predicate cho mot thang cu the.
- Khi nao expression index la lua chon hop ly?

## Challenge 2 - Sai business date

~~~sql
SELECT ordered_at::date, count(*)
FROM sales.orders
GROUP BY ordered_at::date
ORDER BY ordered_at::date;
~~~

Hoi:

- Query phu thuoc state nao?
- Sua de group theo ngay Vietnam.
- Test boundary nao can co?

## Challenge 3 - Sai tuoi

~~~sql
SELECT
    extract(year FROM current_date)
    - extract(year FROM birth_date) AS age
FROM customers;
~~~

Hoi:

- Sai o truoc birthday nhu the nao?
- Viet cach sua bang birthday nam hien tai.
- Neu customer timezone khac nhau, current date can tinh theo timezone nao?

## Challenge 4 - Import atomic fail

~~~sql
INSERT INTO clean_orders(order_id, order_date)
SELECT
    source_id,
    raw_order_date::date
FROM import_orders;
~~~

Hoi:

- Mot raw date loi anh huong transaction ra sao?
- Thiet ke staging/quarantine.
- Khi nao dung pg_input_is_valid va khi nao validate o application?

# 17. Kiem tra kien thuc

## Multiple choice

### K1. Ket qua cua to_char(timestamp, pattern) la gi?

A. date
B. numeric
C. text
D. interval

### K2. Predicate nao phu hop nhat de lay nam 2025?

A. extract(year FROM ordered_at) = 2025
B. to_char(ordered_at, 'YYYY') = '2025'
C. ordered_at >= start_2025 AND ordered_at < start_2026
D. ordered_at::date BETWEEN date '2025-01-01' AND date '2025-12-31'

### K3. Timestamptz nen dung cho truong hop nao?

A. Ngay sinh khong co gio
B. Payment event can mot instant toan cau
C. Ten thang hien thi
D. So luong san pham

### K4. Ham nao tra ve dau bucket thang?

A. extract
B. to_char
C. date_trunc
D. abs

### K5. Vi sao khong hard-code 23:59:59 lam end?

A. Khong hop le SQL
B. Co the bo sot fractional seconds
C. Luon nhanh hon
D. Vi date khong co timezone

### K6. DATEDIFF trong SQL Server can canh bao dieu gi?

A. Luon tra interval
B. Dem datepart boundary, khong phai luon elapsed duration
C. Chi dung cho string
D. Luon theo UTC

## True/False

### K7. Format va cast la cung mot thao tac.

### K8. ordered_at::date co the phu thuoc TimeZone session.

### K9. ABS(-10) cho thay giao dich do la refund.

### K10. Seq Scan trong bang nho luon la loi.

## Short answer

### K11. Giai thich vi sao report theo thang nen group bang bucket date thay vi month_name.

### K12. Neu can tinh timeout 24 gio, nen phan biet gi voi lich hang ngay?

### K13. Neu cast raw text sai lam transaction fail, pipeline nao an toan hon?

## Predict the output

### K14. Session TimeZone la Asia/Ho_Chi_Minh. Ket qua cua bieu thuc sau co ngay nao?

~~~sql
SELECT
    TIMESTAMPTZ '2025-02-28 23:30:00+00'::date;
~~~

### K15. Ket qua duration la bao nhieu giay?

~~~sql
SELECT extract(epoch FROM (
    TIMESTAMP '2025-03-01 10:00'
    - TIMESTAMP '2025-03-01 09:30'
));
~~~

## Query analysis

### K16. Hay neu hai ly do query sau co the cham va viet lai predicate:

~~~sql
SELECT *
FROM sales.orders
WHERE date_trunc('month', ordered_at) = TIMESTAMP '2025-02-01';
~~~

# 18. Tom tat

## Core Ideas

- Numeric computation va display formatting la hai muc dich khac.
- Date/time type phai phan anh y nghia: calendar date, local wall-clock hay global instant.
- Chuyen timezone truoc khi extract/trunc neu report co business timezone.
- Dung date_trunc cho bucket, extract cho field, to_char cho text, cast cho type.
- Loc timestamp bang range dong-mo.
- DATEDIFF, phep tru va age tra loi cac cau hoi thoi gian khac nhau.
- Raw input can staging va validation, khong cast mu quang trong production.

## Key Terms

round, abs, date, time, timestamp, timestamptz, interval, timezone, AT TIME ZONE, extract, date_part, date_trunc, to_char, CAST, CONVERT, DATEADD, DATEDIFF, ISDATE, pg_input_is_valid, selectivity, sargability, half-open interval, calendar duration.

## Rules of Thumb

- Luu instant bang timestamptz khi he thong phan tan.
- Dung date cho ngay khong co gio.
- Format o boundary cuoi cung.
- Dung [start, next_start) de loc thoi gian.
- Khong dung month/day text lam khoa sort.
- Khong ABS du lieu khi chua biet y nghia dau.
- Luon xem EXPLAIN thay vi doan index se duoc dung.
- Neu nhan thang hoac ngay trong nghiep vu, hoi timezone va calendar rule truoc.

## Things Worth Memorizing

- EXTRACT(field FROM source).
- date_trunc(field, source).
- date + integer va timestamp + interval.
- date2 - date1 tra integer days.
- CAST(value AS type) va PostgreSQL ::.
- Range: column >= start AND column < exclusive_end.

## Things Must Be Understood

- Timestamptz va cach hien thi theo session.
- Calendar duration khac elapsed duration.
- Function-on-column va optimizer.
- DATEDIFF boundary semantics.
- Validation pipeline va data quality.
- Y nghia nghiep vu cua timezone.

# 19. Cheat sheet

~~~text
Tinh so:
  round(amount, 2)
  abs(amount)

Lay field:
  extract(year FROM ts)
  extract(month FROM ts)
  extract(isodow FROM ts)

Bucket:
  date_trunc('day', ts)
  date_trunc('month', ts, 'Asia/Ho_Chi_Minh')

Format:
  to_char(ts, 'YYYY-MM-DD HH24:MI:SS')
  to_char(amount, 'FM999G999G990D00')

Cast:
  CAST(value AS date)
  value::date

Ngay dau/cuoi thang:
  start = date_trunc('month', ts)
  next_start = start + interval '1 month'
  last_day = (next_start - interval '1 day')::date

Loc thoi gian:
  ts >= :start
  AND ts < :exclusive_end

Duration:
  end_ts - start_ts
  extract(epoch FROM end_ts - start_ts)

Validate raw:
  pg_input_is_valid(raw_text, 'date')
  staging -> quarantine -> typed table
~~~

# 20. Ket noi toi chu de tiep theo

~~~text
Kieu du lieu va NULL
        |
        v
CASE / COALESCE / NULLIF
        |
        v
Constraints va data quality
        |
        v
Index va execution plan
        |
        v
Transactions, MVCC va isolation
        |
        v
Reporting tables, partitioning va timezone design
~~~

Bai tiep theo nen hoc NULL, CASE va conditional logic. Ly do: date parsing, amount calculation va report deu phai xu ly missing value. Sau do quay lai index/optimizer de hieu expression index, statistics va plan stability. Khi da vung SQL, hoc transaction/MVCC de biet date/time consistency trong concurrency va tiep theo la partitioning, reporting va replication.

# References

1. PostgreSQL Documentation - Date/Time Functions and Operators: https://www.postgresql.org/docs/current/functions-datetime.html
2. PostgreSQL Documentation - Date/Time Types: https://www.postgresql.org/docs/current/datatype-datetime.html
3. PostgreSQL Documentation - Data Type Formatting Functions: https://www.postgresql.org/docs/current/functions-formatting.html
4. PostgreSQL Documentation - Mathematical Functions and Operators: https://www.postgresql.org/docs/current/functions-math.html
5. PostgreSQL Documentation - Data validity checking functions: https://www.postgresql.org/docs/current/functions-info.html
6. PostgreSQL Documentation - SQL expressions and casts: https://www.postgresql.org/docs/current/sql-expressions.html
7. PostgreSQL Documentation - Date/time input interpretation and invalid input: https://www.postgresql.org/docs/current/datetime-invalid-input.html
8. Microsoft Learn - Date and time data types and functions: https://learn.microsoft.com/en-us/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql?view=sql-server-ver17
9. Microsoft Learn - DATENAME: https://learn.microsoft.com/en-us/sql/t-sql/functions/datename-transact-sql?view=sql-server-ver17
10. Microsoft Learn - DATETRUNC: https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver17
11. Microsoft Learn - FORMAT: https://learn.microsoft.com/en-us/sql/t-sql/functions/format-transact-sql?view=sql-server-ver17
12. Microsoft Learn - CAST and CONVERT: https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?view=sql-server-ver17
13. Microsoft Learn - ISDATE: https://learn.microsoft.com/en-us/sql/t-sql/functions/isdate-transact-sql?view=sql-server-ver17
14. PostgreSQL Documentation - EXPLAIN: https://www.postgresql.org/docs/current/using-explain.html

# Transcript Coverage Map

| Transcript topic | Document section | Expanded? | Notes |
| --- | --- | --- | --- |
| 065 ROUND va ABS | 3.1, 4.1, 6, 12 | Yes | Them numeric type, NULL, rounding policy va rui ro nghiep vu |
| 066 Date & Time | 3.2, 8.1, 9 | Yes | Them PostgreSQL date/time types, instant, wall-clock va timezone |
| 067 Overview Date & Time Functions | 1, 2, 3, 20 | Yes | To chuc lai thanh extraction, bucket, formatting, arithmetic, validation |
| 068 DAY, MONTH, YEAR | 3.3, 4.2 | Yes | Dung EXTRACT va business timezone |
| 069 DATEPART | 3.4, 7.4 | Yes | Mapping sang EXTRACT, ISO week/isodow va portability |
| 070 DATENAME | 3.4, 3.7, 7.1 | Yes | Mapping sang to_char, text chi dung cho presentation |
| 071 DATETRUNC | 3.5, 4.2, 5.1 | Yes | Them bucket, grouping, version/vendor note va index |
| 072 EOMONTH | 3.6, 4.5 | Yes | Them start/last/next boundary va half-open interval |
| 073 Date extraction use cases | 3.3, 4.2, 8 | Yes | Sua khuyen nghi loc bang MONTH thanh range predicate |
| 074 Compare extract functions | 7.1, 7.4, 19 | Yes | Bang mapping SQL Server/PostgreSQL va decision rule |
| 075 Formatting & Casting intro | 3.7, 3.8 | Yes | Tach presentation text voi type conversion |
| 076 FORMAT | 3.7, 4.3, 8 | Yes | Mapping to_char, locale, performance va sort |
| 077 CONVERT | 3.8, 7.4 | Yes | CAST/:: portable va style la dac thu SQL Server |
| 078 CAST | 3.8, 4.3 | Yes | Them timezone-sensitive cast va join key |
| 079 DATEADD | 3.10, 19 | Yes | Mapping + interval, calendar vs elapsed |
| 080 DATEDIFF | 3.11, 7.3, 12 | Yes | Sua boundary semantics, age caveat va duration |
| 081 ISDATE | 3.9, 14, 16 | Yes | Mapping pg_input_is_valid/staging/quarantine |
| 082 Summary | 18, 19, 20 | Yes | Compressed recap, lab, exercises va next topics |
