# Lesson 1 — Database, DBMS, SQL và PostgreSQL

## Tổng quan lesson

Transcript bắt đầu từ động lực ra đời của database: application và business tạo ra nhiều dữ liệu hơn mức có thể quản lý thực tế bằng các file rời rạc. Lesson này sửa cách giải thích đơn giản “database là một container” và giới thiệu những thành phần mà backend engineer thật sự vận hành.

### Điều kiện tiên quyết

Biết sử dụng command line cơ bản, hiểu biến trong programming và có hình dung sơ bộ về table là đủ. Không yêu cầu kiến thức ORM.

### Mục tiêu học tập

Sau lesson này, bạn có thể:

- Định nghĩa database, DBMS, SQL, schema, relation, tuple và attribute.
- Giải thích vì sao DBMS không chỉ là một file format.
- Phân biệt PostgreSQL server, database, schema và table.
- Xác định công việc nào thuộc application và công việc nào thuộc PostgreSQL.
- Kết nối đến lab database và xác minh đúng database, role và server đang dùng.

## Bức tranh lớn

~~~text
Backend application
        |
        | parameterized SQL over a connection
        v
PostgreSQL server process
        |
        +--> database: database_master
                  |
                  +--> schema: sales
                            |
                            +--> tables, indexes, constraints
~~~

Database là một collection logic của các object có liên quan. DBMS là software parse SQL, lưu và đọc dữ liệu, enforce permission và constraint, điều phối công việc đồng thời, đồng thời khôi phục sau failure. PostgreSQL là một DBMS; `database_master` là một database do PostgreSQL server quản lý.

## Khái niệm: database và DBMS

### Trực giác

Một file có thể chứa bytes. DBMS gán meaning và operation có kiểm soát cho các bytes đó: nó có thể từ chối foreign key không hợp lệ, cô lập hai transaction, khôi phục thay đổi đã commit sau crash và chọn access path cho query.

### Định nghĩa chính xác

- **Database** là collection có tổ chức của persistent data và metadata.
- **DBMS** là software định nghĩa, lưu trữ, query và quản lý database.
- **SQL** là declarative language dùng để định nghĩa structure, thao tác data và query relational data. Bản thân SQL không quy định mọi chi tiết implementation của DBMS.

### Vì sao cần

Backend system cần state dùng chung, bền vững, hỗ trợ đồng thời và có thể query. Một collection JSON file không tự cung cấp constraint, transaction, index, recovery hoặc concurrent update an toàn.

### Cơ chế

1. Client mở connection đến server.
2. Client gửi SQL và parameter values.
3. PostgreSQL parse và analyze statement dựa trên catalog metadata.
4. Planner chọn execution plan.
5. Executor đọc hoặc ghi pages thông qua buffer manager.
6. Với write, PostgreSQL ghi đủ thông tin vào WAL để hỗ trợ durability/recovery và làm thay đổi visible theo transaction rules.

### Ghi chú production

Database không chỉ là “persistence layer”. Nó là một phần của correctness boundary. Service-level validation giúp trả lỗi thân thiện hơn, nhưng chỉ database constraint mới bảo vệ dữ liệu khi service khác, script, job hoặc race condition cùng ghi vào các table.

## Khái niệm: schema, table, row và column

Trong relational model, table biểu diễn một relation, row biểu diễn một tuple, còn column biểu diễn một attribute có declared type. PostgreSQL schema cung cấp namespace bên trong database; `sales.orders` nghĩa là table `orders` trong schema `sales`.

Các từ này liên quan nhưng không thể dùng thay thế cho nhau:

| Term | Ý nghĩa | Ví dụ |
| --- | --- | --- |
| Server | PostgreSQL instance nhận connection | Docker service `postgres` |
| Database | Logical database được connection chọn | `database_master` |
| Schema | Namespace bên trong database | `sales` |
| Table | Persistent relation gồm rows và columns | `sales.orders` |
| Row/tuple | Một record trong relation | Order `1001` |
| Column/attribute | Vị trí của một typed value | `ordered_at` |

## Ví dụ SQL

~~~sql
SELECT
    current_database() AS database_name,
    current_schema() AS default_schema,
    current_user AS connected_role,
    version() AS server_version;
~~~

Kết quả kỳ vọng: một row xác định database hiện tại, schema hiện tại, role đang kết nối và PostgreSQL version. Đây là thông tin hữu ích khi query cho kết quả khác nhau vì bạn vô tình chạy trên sai database, role hoặc server version.

## Hành vi bên trong

PostgreSQL lưu định nghĩa object trong system catalog. Khi analyze `sales.orders`, nó resolve tên table có schema-qualified, kiểm tra tên column và type, đồng thời verify privilege. Catalog là metadata được parser, planner và administration tool sử dụng; nó không phải business data.

## Góc nhìn Backend và ORM

~~~text
Controller -> service transaction -> repository/ORM -> connection pool -> PostgreSQL
~~~

JPA/Hibernate ẩn connection và quá trình tạo SQL, nhưng nó vẫn gửi SQL đến DBMS. Mapping `@ManyToOne` không thay thế foreign key, và entity validation annotation không thay thế database `CHECK` hoặc `NOT NULL` constraint.

## Các hiểu lầm thường gặp

**“SQL chính là database.”** SQL là một language. PostgreSQL mới là DBMS thực thi language đó.

**“Database tự động đảm bảo security.”** Security cần roles, privileges, network controls, secret management, auditing và query construction an toàn. DBMS cung cấp các cơ chế; production configuration quyết định kết quả.

**“ORM là source of truth.”** Database schema đã deploy và các constraint của nó mới là authority cuối cùng đối với dữ liệu được lưu.

## Lab

Chạy:

~~~powershell
./scripts/bootstrap.ps1
~~~

Sau đó kiểm tra:

~~~sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema IN ('sales', 'lab')
ORDER BY table_schema, table_name;
~~~

## Mental models

- Database là durable shared state; DBMS là system giúp state đó queryable, consistent và recoverable.
- Schema là namespace, tự nó không phải security boundary.
- SQL mô tả kết quả mong muốn; optimizer chọn implementation.

## Câu hỏi phỏng vấn

1. **Junior — Database khác DBMS như thế nào?** Database là data được tổ chức; DBMS là software quản lý storage, query, constraint, concurrency và recovery.
2. **Junior — Schema trong PostgreSQL là gì?** Là namespace bên trong database, dùng để nhóm các object như table, view và function.
3. **Mid — Vì sao vẫn đặt constraint trong database khi API đã validate input?** Nhiều writer và race có thể bypass API validation; database constraint bảo vệ invariant tại final write boundary.
4. **Senior — Vì sao cùng một SQL query có thể chạy khác performance sau khi chuyển server?** Planner statistics, indexes, data distribution, configuration, PostgreSQL version và hardware có thể làm thay đổi plan và I/O cost.
5. **Senior — Vì sao SQL được gọi là declarative?** SQL mô tả kết quả hoặc operation thay vì chỉ định toàn bộ algorithm; DBMS có thể chọn giữa nhiều execution strategy hợp lệ.

## Tài liệu tham khảo

- [PostgreSQL Architecture](https://www.postgresql.org/docs/current/tutorial-arch.html)
- [PostgreSQL Database Access Control](https://www.postgresql.org/docs/current/ddl-priv.html)
- [PostgreSQL Schemas](https://www.postgresql.org/docs/current/ddl-schemas.html)
