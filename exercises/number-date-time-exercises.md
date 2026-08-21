# Bai tap - Ham so, ngay gio, dinh dang va casting

> Hay viet du doan ket qua va ly do truoc khi chay SQL. Bai tap dung PostgreSQL va schema sales trong repository.

## Level 1 - Recall

1. Phan biet date, timestamp without time zone va timestamptz.
2. ROUND tra ve type gi? ABS co lam thay doi sign co y nghiep vu khong?
3. EXTRACT khac date_trunc o dau?
4. to_char khac CAST o muc dich va kieu ket qua nhu the nao?
5. Viet bieu thuc PostgreSQL cong 7 ngay va cong 1 thang.
6. Predicate half-open co dang nao? Tai sao dung exclusive end?
7. DATEDIFF cua SQL Server co phai luon la elapsed duration khong?
8. PostgreSQL co ham ISDATE y het SQL Server khong?

## Level 2 - Apply

9. Viet query dem don theo thang tai Asia/Ho_Chi_Minh, group bang date bucket va tra ve month label.
10. Viet query lay tat ca don trong quy 2 nam 2025 ma khong dung extract tren cot trong WHERE.
11. Cho started_at va ended_at, tinh elapsed minutes va loai row co ended_at NULL hoac nho hon started_at.
12. Viet query lay ngay dau, ngay cuoi va exclusive next start cua thang tu mot parameter.
13. Viet query format ordered_at thanh chuoi ISO de export, nhung sap xep bang timestamp goc.
14. Viet query tim order co ordered_at nam 2025 tai Vietnam, dung boundary instant ro rang.
15. Viet query tim khoang cach giua hai order lien tiep cua moi customer bang LAG.
16. Cho bang import_orders(source_row, raw_order_date), thiet ke flow tach valid row va invalid row. Neu PostgreSQL khong co pg_input_is_valid thi lam gi?

## Level 3 - Engineering

17. API nhan year, month va timezone. Thiet ke cach service chuyen input thanh from_instant/to_instant va viet SQL repository.
18. He thong thanh toan dang map LocalDateTime vao created_at. Phan tich loi khi deploy sang region khac va de xuat type/model moi.
19. Query dung to_char trong WHERE cham sau khi bang tang 100 lan. Viet lai, neu expression index la lua chon thi neu trade-off.
20. Business noi gia han hang thang luc 09:00 local time. So sanh 30 days, 1 calendar month, 24 hours va scheduler theo zone.
21. Mot bao cao dung ordered_at::date nhung so lieu sai quanh 00:00. Viet test boundary va cach sua.
22. Planner chon Seq Scan du co index ordered_at. Lap checklist chan doan: size, selectivity, statistics, estimated/actual rows, predicate va timezone.
23. Import 10 trieu dong co date text khong dong nhat. Thiet ke staging, quarantine, retry, metric data quality va audit.
24. Dashboard 10 nam theo thang va nhieu market timezone. Chon query online, summary table hay materialized view; giai thich consistency va refresh trade-off.

## Debugging prompts

25. Tim loi va sua:

~~~sql
SELECT *
FROM sales.orders
WHERE to_char(ordered_at, 'YYYY-MM') = '2025-02';
~~~

26. Tim loi timezone:

~~~sql
SELECT ordered_at::date, count(*)
FROM sales.orders
GROUP BY ordered_at::date;
~~~

27. Tim loi tinh tuoi:

~~~sql
SELECT extract(year FROM current_date)
     - extract(year FROM birth_date) AS age
FROM customers;
~~~

28. Tim loi import atomic:

~~~sql
INSERT INTO clean_orders(order_id, order_date)
SELECT source_id, raw_order_date::date
FROM import_orders;
~~~

# Goi y tu kiem tra

- Kieu cua expression la gi?
- Ham co nam tren column trong WHERE khong?
- Timezone nao dang quyet dinh business date?
- Boundary co bi lap hoac bo sot fractional seconds khong?
- Day la calendar question hay elapsed-time question?
- Dung data raw/typed va quarantine da tach chua?
