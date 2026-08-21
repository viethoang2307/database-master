# Database Master

Curriculum học Database Engineering theo hướng Backend, dùng PostgreSQL làm Database chuẩn để thực hành.

Repository này tái cấu trúc một khóa học SQL lớn thành tài liệu có thứ tự, SQL có thể chạy được, lab, bài tập và ghi chú production. Mục tiêu là hiểu cả câu lệnh SQL, mô hình quan hệ, query planner, cách lưu trữ, transaction và ảnh hưởng của các quyết định Database lên backend service.

## Bắt đầu nhanh

Yêu cầu:

- Docker Desktop có Docker Compose.
- `psql` là tùy chọn; các lệnh chính có thể chạy qua container.

~~~powershell
Copy-Item .env.example .env
./scripts/bootstrap.ps1
./scripts/check.ps1
~~~

Kết nối thủ công:

~~~powershell
docker compose exec postgres psql -U db_student -d database_master
~~~

Dừng container nhưng giữ dữ liệu:

~~~powershell
docker compose down
~~~

Xóa toàn bộ dữ liệu lab chỉ khi thực sự muốn reset:

~~~powershell
./scripts/reset.ps1 -ConfirmReset
~~~

## Cách học

1. Đọc [ROADMAP.md](ROADMAP.md).
2. Chạy bootstrap và đọc lesson tương ứng trong `docs/`.
3. Chạy SQL example trước khi xem solution.
4. Làm exercises và debugging challenges.
5. Dùng `EXPLAIN` để kiểm chứng giả thuyết về performance.

Foundation Sprint hiện bao gồm SQL/DBMS fundamentals, PostgreSQL setup, query lifecycle, `SELECT`, DDL, constraints, DML, transactions, filtering và `NULL`.

Querying Sprint đã bắt đầu với [JOIN, anti-join và set operators](docs/querying/01-joins-and-set-operators.md), kèm [bài tập](exercises/querying-exercises.md) và [SQL lab](sql/querying/01_joins_and_sets.sql).

## Nguyên tắc của project

- PostgreSQL là dialect chuẩn để chạy code.
- SQL Server/T-SQL trong transcript được chuyển đổi có giải thích, không copy máy móc.
- Performance claims phải được kiểm chứng bằng execution plan và dữ liệu thực nghiệm.
- Constraint và transaction boundary thuộc database design, không chỉ là trách nhiệm của ORM.
- Raw transcript không được commit; [transcript coverage map](docs/transcript-coverage.md) ghi lại phạm vi đã xử lý.
- Phần giải thích viết bằng tiếng Việt; SQL keywords và thuật ngữ kỹ thuật phổ biến được giữ bằng English để dễ tra cứu và phỏng vấn.
