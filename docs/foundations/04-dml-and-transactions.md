# Lesson 4 — DML và Transaction Boundary

## Tổng quan lesson

Data Manipulation Language thay đổi row. Transcript giới thiệu `INSERT`, `UPDATE` và `DELETE`; backend engineer còn phải hiểu atomicity, retry, concurrent writer và boundary tại đó một nhóm statement trở thành một business operation.

### Mục tiêu học tập

- Dùng `INSERT`, `UPDATE`, `DELETE` và PostgreSQL `ON CONFLICT` an toàn.
- Giải thích autocommit khác explicit transaction như thế nào.
- Chọn transaction boundary cho một service operation nhiều bước.
- Mô tả ở mức cao cách WAL, MVCC và lock hỗ trợ write.
- Nhận diện race condition không thể sửa chỉ bằng application validation.

## Trực giác

Transaction là một logical unit of work. Khi đặt order, việc tạo order, thêm item và reserve inventory phải cùng visible hoặc cùng không visible. Transaction không tự động trở thành distributed transaction xuyên qua mọi service; nó chỉ bao phủ session/resource tham gia vào database transaction đó.

## DML cơ bản

~~~sql
INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1001, 1, 1)
ON CONFLICT (order_id, product_id)
DO UPDATE SET reserved_quantity = EXCLUDED.reserved_quantity,
              status = 'active';

UPDATE lab.inventory_reservations
SET status = 'fulfilled'
WHERE order_id = 1001
  AND product_id = 1;

DELETE FROM lab.inventory_reservations
WHERE status = 'released';
~~~

Predicate của `UPDATE` và `DELETE` là một phần của safety contract. Trước khi chạy production, hãy kiểm tra predicate bằng `SELECT`, dùng transaction khi phù hợp và verify affected-row count.

## Transaction mechanics

~~~sql
BEGIN;

INSERT INTO lab.inventory_reservations (order_id, product_id, reserved_quantity)
VALUES (1002, 3, 1)
ON CONFLICT (order_id, product_id)
DO UPDATE SET reserved_quantity = EXCLUDED.reserved_quantity;

UPDATE lab.inventory_reservations
SET status = 'fulfilled'
WHERE order_id = 1002
  AND product_id = 3;

COMMIT;
~~~

Nếu bất kỳ bước bắt buộc nào fail, service phải rollback transaction và report/retry theo error class. Autocommit có nghĩa mỗi statement có thể được commit riêng, không an toàn khi nhiều statement phải tạo thành một operation bảo toàn invariant.

## Điều gì xảy ra bên trong?

Ở mức cao, PostgreSQL:

1. Gán snapshot/identity cho transaction.
2. Thực thi row change và ghi thông tin WAL để đảm bảo durability/recovery.
3. Duy trì metadata về visibility của row version bằng MVCC thay vì ghi đè trực tiếp view của mọi reader.
4. Dùng lock và conflict detection để điều phối operation đồng thời.
5. Khi commit, làm kết quả của transaction visible theo isolation rule.
6. Về sau reclaim row version đã obsolete thông qua vacuum.

Đây là approximation để học; behavior chính xác phụ thuộc operation và isolation level. PostgreSQL mặc định `READ COMMITTED` không có nghĩa là “không còn concurrency issue”; nó định nghĩa visibility model, không tự serialize business invariant ở application level.

## Production scenario: inventory race

Hai request cùng đọc `available = 1`, cùng quyết định có thể reserve item rồi cùng ghi success. Application-side check có thể race. Các hướng xử lý gồm atomic conditional update, row lock với `SELECT ... FOR UPDATE`, serializable transaction kèm retry hoặc data model biểu đạt invariant. Lựa chọn đúng phụ thuộc contention và business semantics.

## Tác động performance

- Transaction lớn giữ resource lâu hơn, tăng rollback cost và có thể làm chậm vacuum progress.
- Batch DML giảm round trip nhưng phải có giới hạn để transaction không phình quá lớn.
- Index tăng tốc predicate nhưng thêm write work và WAL/index maintenance.
- Serialization/deadlock failure được retry phải an toàn theo idempotency rule.

## Góc nhìn ORM

Spring `@Transactional` định nghĩa transaction boundary quanh method được proxy, nhưng self-invocation, asynchronous execution và nhiều data source có thể làm behavior thực tế khác đi. Hãy verify transaction propagation, isolation và connection usage thay vì coi annotation là magic.

## So sánh: application validation và database enforcement

| Approach | Điểm mạnh | Hạn chế |
| --- | --- | --- |
| API validation | Feedback nhanh, error thân thiện | Có thể bị bypass hoặc race với writer khác |
| Service transaction | Gom các statement liên quan | Chỉ bao phủ resource được enlist trong transaction đó |
| Database constraint | Enforce invariant tại write boundary | Tự nó không giải thích business intent cho user |
| Lock/isolation strategy | Kiểm soát visibility/conflict đồng thời | Tăng contention và có thể cần retry |

## Sai lầm thường gặp

- Mở transaction quanh toàn bộ HTTP request, bao gồm cả remote call.
- Coi deadlock hoặc serialization failure là bug không thể xảy ra thay vì outcome có thể retry.
- Retry non-idempotent `INSERT` mà không có request/idempotency key.
- Quên rằng PostgreSQL statement fail sẽ khiến transaction hiện tại ở trạng thái aborted cho đến khi rollback.
- Update row mà không kiểm tra affected-row count.

## Lab

Chạy `sql/labs/02_constraints_and_rollback.sql`. Script commit một reservation hợp lệ, cố ý vi phạm `CHECK` rồi rollback. So sánh kết quả với các statement trong `sql/foundations/03_dml_and_transactions.sql`, nơi rollback toàn bộ demonstration.

## Mental models

- Transaction là correctness boundary, không chỉ là performance wrapper.
- `COMMIT` làm một nhóm database change trở thành một outcome durable/visible; nó không undo external side effect đã gửi sang system khác.
- MVCC cung cấp view của row version cho transaction; nó không loại bỏ nhu cầu suy luận về invariant và conflict.

## Câu hỏi phỏng vấn

1. **Junior — `COMMIT` làm gì?** Nó kết thúc transaction hiện tại thành công và làm change durable/visible theo rule của PostgreSQL.
2. **Junior — Vì sao autocommit nguy hiểm trong order-placement flow?** Mỗi statement có thể commit độc lập, để lại partial state nếu statement sau fail.
3. **Mid — Service nên làm gì sau deadlock hoặc serialization failure?** Abort transaction, sau đó có thể retry toàn bộ transaction với bounded backoff nếu operation an toàn để retry.
4. **Mid — `ON CONFLICT` giải quyết vấn đề gì?** Nó biến uniqueness conflict thành quyết định insert-or-update rõ ràng, tránh race mong manh của check-then-insert.
5. **Senior — Vì sao database transaction không tự bao gồm message broker call?** Broker và database có commit protocol độc lập; cross-system atomicity cần pattern rõ ràng như outbox và reliable publication.

## Tài liệu tham khảo

- [PostgreSQL Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)
- [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [PostgreSQL `INSERT ... ON CONFLICT`](https://www.postgresql.org/docs/current/sql-insert.html)
- [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL `VACUUM`](https://www.postgresql.org/docs/current/sql-vacuum.html)
