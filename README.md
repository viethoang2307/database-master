# Database Master

Curriculum học Database Engineering theo hướng Backend, dùng PostgreSQL làm database chuẩn chạy chính.

Repository này tái cấu trúc một khóa SQL lớn thành tài liệu học có thứ tự, SQL executable, lab, exercises và production notes. Mục tiêu là hiểu cả câu lệnh SQL, mô hình quan hệ, query planner, storage behavior, transaction và cách các quyết định database ảnh hưởng đến backend service.

## Quick start

Yêu cầu:

- Docker Desktop với Docker Compose.
- `psql` là tùy chọn; mọi lệnh chính có thể chạy qua container.

```powershell
Copy-Item .env.example .env
./scripts/bootstrap.ps1
./scripts/check.ps1
```

Kết nối thủ công:

```powershell
docker compose exec postgres psql -U db_student -d database_master
```

Dừng container nhưng giữ dữ liệu:

```powershell
docker compose down
```

Xóa toàn bộ dữ liệu lab chỉ khi thực sự muốn reset:

```powershell
./scripts/reset.ps1 -ConfirmReset
```

## Học theo thứ tự

1. Đọc [ROADMAP.md](ROADMAP.md).
2. Chạy bootstrap và đọc lesson tương ứng trong `docs/`.
3. Chạy SQL example trước khi xem solution.
4. Làm exercises và debugging challenges.
5. Dùng `EXPLAIN` để kiểm chứng giả thuyết về performance.

Foundation Sprint hiện bao gồm SQL/DBMS fundamentals, PostgreSQL setup, query lifecycle, `SELECT`, DDL, constraints, DML, transactions, filtering và `NULL`.

## Nguyên tắc của project

- PostgreSQL là canonical dialect.
- SQL Server/T-SQL trong transcript được chuyển đổi, không copy máy móc.
- Performance claims phải được kiểm chứng bằng execution plan và dữ liệu thực nghiệm.
- Constraint và transaction boundary thuộc database design, không chỉ là trách nhiệm của ORM.
- Raw transcript không được commit; [transcript coverage map](docs/transcript-coverage.md) ghi lại phạm vi đã xử lý.

