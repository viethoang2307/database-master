# Lesson 2 - Data Transformation va String Functions

## 1. Lesson Overview

Du lieu trong he thong that hiem khi sach ngay tu dau. Ten nguoi dung co the co khoang trang o dau hoac cuoi chuoi, email co the bi viet hoa, so dien thoai co dau gach, va mot cot co the chua ca gia tri thuc su lan chuoi rong. Neu dua nguyen du lieu do vao bao cao, tim kiem hoac API, ket qua co the khong nhat quan.

Lesson nay reconstruct transcript 056-064 thanh mot bai hoc ve **data transformation** va **string functions** trong PostgreSQL. Ta se hoc cach doc du lieu chuoi, tao mot representation sach hon cho output, phat hien loi chat luong du lieu, va danh gia tac dong cua viec boc ham quanh cot trong query.

Day la mot diem giao giua SQL co ban va production engineering:

- Trong ETL, ham chuoi giup tao lop du lieu da chuan hoa.
- Trong API, ham chuoi giup tao display label hoac normalize input.
- Trong search, cach normalize phai di cung voi index va uniqueness policy.
- Trong data quality, ham chuoi giup phat hien va do luong dirty data, nhung khong tu dong thay the cho data contract.

### Dieu kien tien quyet

Ban nen nam:

- SELECT, WHERE, ORDER BY va alias.
- NULL va three-valued logic.
- Kieu text, numeric va boolean.
- Primary key, foreign key o muc nhan biet.
- CTE hoac subquery o muc co ban la loi the, nhung khong bat buoc.
- Cach chay mot script PostgreSQL va doc ket qua query.

### Muc tieu hoc tap

Sau lesson nay, ban co the:

1. Giai thich data transformation khac voi thay doi du lieu goc nhu the nao.
2. Phan biet scalar/single-row function, aggregate function va window function.
3. Du doan thu tu tinh cua nested function.
4. Dung CONCAT va CONCAT_WS an toan khi input co NULL.
5. Su dung UPPER, LOWER, TRIM, LTRIM, RTRIM va REPLACE cho cac bai toan du lieu thuc te.
6. Phan biet length/char_length voi octet_length trong PostgreSQL.
7. Nhan dien khac biet giua PostgreSQL length va SQL Server LEN.
8. Dung LEFT, RIGHT va SUBSTRING voi vi tri 1-based cua PostgreSQL.
9. Phat hien leading/trailing whitespace va tao cot cleaned de kiem tra.
10. Giai thich tai sao lower(column) trong WHERE co the lam ordinary index khong dung duoc.
11. Chon giua transformation o read time, write boundary, generated column va expression index.
12. Doc mot EXPLAIN don gian va de xuat cach kiem thu truoc khi sua production query.

## 2. Big Picture

~~~text
Nguon du lieu / HTTP request / file import
                    |
                    v
          Raw hoặc staging representation
                    |
                    v
       SQL expression + string functions
                    |
          +---------+----------+
          |                    |
          v                    v
   Clean projection       Data-quality flags
          |                    |
          +---------+----------+
                    v
       API / report / warehouse / search
                    |
                    v
       Constraint + index + monitoring policy
~~~

Trong flow nay, ham chuoi thuong khong tu minh ghi du lieu. Mot SELECT co the tao ra representation da trim, da lower hoac da thay the de hien thi. Mot UPDATE, pipeline hoac application boundary moi la noi bien doi do duoc commit vao storage. Hai muc dich nay phai duoc tach bach:

- **Presentation transformation**: chi lam sach output cho mot query cu the.
- **Canonicalization**: dua du lieu ve dang chuan de so sanh, uniqueness, join hoac search.
- **Data repair**: sua du lieu da ton tai va can mot migration/backfill co audit.
- **Validation**: phat hien input khong dung, sau do reject, quarantine hoac cho phep theo policy.

Cung mot ham lower co the an toan trong display nhung nguy hiem neu dung lam identity normalization ma khong co policy ve locale, Unicode, uniqueness va index.

## 3. Concept-by-Concept Explanation

## Concept 1 - Data transformation

### Truc giac

Data transformation la viec tao ra mot bieu dien du lieu phu hop hon voi muc dich tiep theo. Vi du, ten nguoi dung co khoang trang thua co the duoc trim khi hien thi; email co the duoc lower de so sanh; so dien thoai co dau gach co the bo dau gach de dua vao canonical format.

### Dinh nghia formal

Trong query, transformation la mot bieu thuc nhan input tu mot hoac nhieu column/value va tra ve mot value moi. Transformation co the la deterministic, nhu trim mot text, hoac phu thuoc vao database locale, nhu upper/lower trong mot so truong hop.

Transformation trong SELECT khong lam thay doi row dang luu. Transformation trong UPDATE, generated column, ETL job hoac application code moi co the thay doi representation duoc persistence.

### Vi sao ton tai

Neu khong co mot buoc transformation ro rang, moi consumer se tu tu xu ly:

- API A trim ten, API B khong trim.
- Search lower email o mot noi nhung khong lower o noi khac.
- Bao cao dem hai version cua cung mot gia tri.
- Import tao ra du lieu kho so sanh voi du lieu cu.

SQL functions tao ra mot noi de bieu dat transformation gan voi data source. Tuy nhien, ham chuoi khong tu dong tao ra data contract. Team van phai quyet dinh khi nao reject, khi nao sua, va representation nao la source of truth.

### Co che

1. Xac dinh input raw va invariant mong muon.
2. Tao expression transformation.
3. Chay tren mau nho va kiem tra edge case: NULL, chuoi rong, Unicode, whitespace, gia tri qua dai.
4. Quyet dinh output chi de doc hay se ghi lai.
5. Neu ghi lai, dung transaction, migration, audit va rollback plan.
6. Neu query thuong xuyen can expression do, can danh gia generated column hoac expression index.

### Vi du

~~~sql
SELECT
    customer_id,
    full_name AS raw_name,
    btrim(full_name) AS display_name,
    lower(btrim(email)) AS lookup_email
FROM sales.customers
ORDER BY customer_id;
~~~

Query tao ra ba representation nhung khong sua cot goc. Day la cach an toan de quan sat truoc khi co migration.

### Hanh vi ben trong

PostgreSQL parse query, resolve ten column va kieu, sau do planner tao plan. Trong execution, moi row duoc dua qua cac expression trong target list. Ham btrim, lower va concat chay tren gia tri cua row; ket qua duoc gui vao projection. Neu khong co UPDATE/INSERT, heap page khong bi ghi lai chi vi SELECT co transformation.

### Tac dong hieu nang

- CPU tang theo so row va do dai chuoi.
- I/O van co the lon neu query phai scan nhieu row.
- Transformation trong SELECT thuong anh huong CPU/output, khong nhat thiet anh huong kha nang tim row.
- Transformation trong WHERE co the lam mat kha nang dung ordinary index neu planner khong co index phu hop.
- Transformation co the lam thay doi cardinality neu dung trong GROUP BY, DISTINCT hoac join key.

### Sai lam pho bien

- Trim trong SELECT va tuong rang data trong table da duoc sua.
- Lower moi text de chuan hoa ma khong xac dinh locale va business rule.
- Dung replace de sua hang loat du lieu ma khong co backup/audit.
- Ghi de cot raw, lam mat bang chung ve input.
- Dung function tren column trong WHERE ma khong kiem tra plan.

### Production notes

Giữ raw value khi can forensic hoac trace input. Neu co canonical value, dat ten ro rang nhu email_normalized, phone_e164 hoac name_cleaned; dung constraint, test va monitoring de bao ve invariant. Transformation cho display khong nen vo tinh tro thanh identity rule.

## Concept 2 - Cac loai SQL function

### Truc giac

Co ham xu ly tung row mot, co ham gom nhieu row, va co ham giu row shape nhung tinh tren mot cua so row. Vi du, lower(full_name) cho mot output moi row; sum(total_amount) gom nhieu order; row_number() tinh thu hang nhung van tra ve nhieu row.

### Dinh nghia formal

- **Scalar hoac single-row function**: moi lan danh gia nhan input cua mot row va tra ve mot gia tri cho row do. Vi du: upper(text), length(text), substring(text from start).
- **Aggregate hoac multi-row function**: nhan tap row trong mot group va tra ve mot ket qua cho group. Vi du: sum, count, avg.
- **Window/analytic function**: tinh tren mot window cua nhieu row nhung van tra ve ket qua gan voi moi row, khac voi aggregate o shape output.

Transcript noi single-row thuong danh cho data engineer va multi-row thuong danh cho analyst. **Note: day la cach phan loai de day, khong phai ranh gioi nghe nghiep.** Backend engineer, analyst va data engineer deu co the dung ca ba loai.

### Vi sao ton tai

Database can bieu dat hai nhu cau khac nhau:

- Chuyen doi gia tri cua row ma khong lam mat row shape.
- Rut gon nhieu row thanh metric.
- Tinh metric theo partition nhung van giu chi tiet tung row.

Hieu shape output quan trong hon viec hoc thuoc ten ham.

### Co che

Voi scalar function, executor danh gia expression cho moi row pass filter. Voi aggregate, executor tao state cho group, cap nhat state khi doc row, roi tra ket qua khi group ket thuc. Voi window function, executor can co window definition, thu tu va partition de tinh output theo frame.

### Vi du

~~~sql
SELECT
    o.order_id,
    lower(o.order_status) AS status_for_display,
    sum(o.total_amount) OVER (
        PARTITION BY o.customer_id
    ) AS customer_total
FROM sales.orders AS o
ORDER BY o.customer_id, o.order_id;
~~~

lower la scalar function. sum over la window function: tong duoc lap lai tren moi order cua cung customer, khong lam giam so row.

### Hanh vi ben trong

Scalar expression thuong duoc tinh trong projection/filter. Aggregate va window co the can memory, sort, hash hoac state management. Do do, khong nen suy ra moi function co cung chi phi chi vi chung deu goi la function.

### Tac dong hieu nang

Chi phi phu thuoc so row, kich thuoc input, do dai text, so group, order cua window va memory. Ham string tren 10 row khac hoan toan ham string tren hang tram trieu row.

### Sai lam pho bien

- Goi moi function la aggregate.
- Nham aggregate voi window function vi ca hai deu tinh tren nhieu row.
- Dung scalar function trong GROUP BY ma khong can thiet.
- Khong nhin shape output, dan den duplicate hoac mat row.
- Tin rang function deterministic trong moi locale/database.

### Production notes

Khi review query, hoi ba cau: ham nhan bao nhieu row, tra ve bao nhieu row, va chay o buoc nao cua plan? Day la cach noi function voi cardinality va latency.

## Concept 3 - Nested function va thu tu danh gia

### Truc giac

Ham ben ngoai nhan ket qua cua ham ben trong. Cac lop transformation nen duoc doc tu trong ra ngoai.

### Dinh nghia formal

Voi bieu thuc F(G(x)), database danh gia G(x) de tao intermediate value, sau do dua intermediate value vao F. NULL, type conversion va edge case cua ham trong co the thay doi ket qua ham ngoai.

### Vi sao ton tai

Du lieu thuc te hiem khi du mot buoc la xong. Ta co the can trim truoc khi lay prefix, lower truoc khi so sanh, hoac replace truoc khi length.

### Co che

~~~sql
SELECT
    length(lower(left('Maria', 2))) AS result;
~~~

Thu tu logic:

1. left('Maria', 2) tra ve Ma.
2. lower('Ma') tra ve ma.
3. length('ma') tra ve 2.

### Vi du production

~~~sql
SELECT
    customer_id,
    left(btrim(full_name), 2) AS name_prefix,
    substring(btrim(full_name) FROM 2) AS name_without_first_char
FROM sales.customers;
~~~

Neu khong btrim truoc, leading space co the tro thanh prefix va lam substring cat sai ky tu mong muon.

### Hanh vi ben trong

Planner co the rewrite expression khi an toan, nhung semantics cua ham va NULL van phai duoc giu. Khong nen dua ra gia dinh rang database luon materialize mot temporary column cho moi ham; executor co the tinh expression theo plan implementation.

### Tac dong hieu nang

Nhieu ham long nhau lam tang CPU tren moi row. Ham ben trong co the lam mat indexability truoc khi ham ngoai duoc xem xet. Neu expression duoc lap lai nhieu lan, CTE, subquery, generated column hoac expression index co the giup code ro hon; nhung phai do performance thay vi tu dong them abstraction.

### Sai lam pho bien

- Cat ky tu truoc khi trim.
- Dung length raw text lam count sau khi da transform.
- Khong xu ly NULL o lop trong.
- Lap lai mot expression dai trong nhieu noi ma khong dat ten intermediate.
- Viet nested expression kho debug trong query production.

### Production notes

Khi expression dai, dung CTE hoac subquery de dat ten raw_value, cleaned_value, normalized_value. Trong PostgreSQL hien dai, CTE co the duoc inline tuy plan; muc dich dau tien la readability, khong phai ep materialize.

## Concept 4 - CONCAT va CONCAT_WS

### Truc giac

CONCAT noi nhieu gia tri thanh mot chuoi. CONCAT_WS noi voi mot separator va co xu ly NULL tien ich hon cho label.

### Dinh nghia formal

Trong PostgreSQL, concat nhan cac gia tri, chuyen chung sang text va bo qua argument NULL. concat_ws(separator, ...) cung bo qua argument NULL, nhung separator NULL lam ket qua NULL. Toan tu || co semantics khac: neu mot operand NULL thi ket qua thuong la NULL.

PostgreSQL docs dinh nghia concat/concat_ws; cac DBMS khac co the khac. SQL Server CONCAT chuyen NULL thanh chuoi rong, con toan tu + phu thuoc semantics/session setting va khong nen suy ra tu PostgreSQL.

### Vi sao ton tai

Ghep first name, country, code hoac label la nhu cau thuong gap. Xu ly NULL ro rang tranh output co chuoi "null", dau cach thua hoac mat ca label.

### Co che

~~~sql
SELECT
    concat(btrim(full_name), ' - ', country) AS label_using_concat,
    concat_ws(' - ', btrim(full_name), country) AS label_using_concat_ws,
    btrim(full_name) || ' - ' || country AS label_using_operator
FROM sales.customers;
~~~

Voi country NULL, concat van bo qua argument NULL nhung van giu separator literal da truyen; concat_ws bo qua field NULL cung separator lien quan; || co the cho NULL. Vi vay phai chon semantics co chu y.

### Performance implications

Ghep chuoi la CPU va tao allocation cho output. Neu chi tao display label trong mot page nho, chi phi thuong khong dang ke; neu scan hang trieu row de export, output size va CPU co the lon. Ghep column trong WHERE cung co the lam mat index tren column goc.

### Common mistakes

- Dung concat khi can phan biet NULL va chuoi rong.
- Ghep email/phone ma khong co canonical policy.
- Dung separator co dinh khi mot field NULL ma khong test output.
- Dung || va mong NULL tu dong duoc bo qua.
- Ghep input user vao SQL thay vi parameterize; ham chuoi khong thay the parameter binding.

### Production notes

Dung concat_ws cho display label co separator. Dung cot normalized rieng cho identity/search. Khong luu full label neu no co the suy ra tu cac cot va can cap nhat dong bo, tru khi co ly do read-performance ro rang.

## Concept 5 - UPPER va LOWER

### Truc giac

UPPER va LOWER thay doi case cua chuoi. Chung huu ich de tao display, grouping hoac comparison theo policy.

### Dinh nghia formal

PostgreSQL upper va lower chuyen doi theo database locale/collation rules. Ket qua khong phai la quy tac universal cho moi ngon ngu, moi Unicode grapheme hoac moi DBMS.

### Vi sao ton tai

Input viet hoa khong nhat quan co the lam sai grouping va exact comparison. Vi du, lookup email theo lower policy co the tranh bo sot input co case khac nhau, nhung email case sensitivity phai duoc team quyet dinh theo domain.

### Co che

~~~sql
SELECT
    customer_id,
    upper(btrim(full_name)) AS shouting_name,
    lower(btrim(email)) AS lookup_email
FROM sales.customers;
~~~

Day la projection. No khong tu dong ghi lower(email) vao table.

### Internal behavior

Executor doc text, ap dung case mapping theo collation/locale, tao gia tri text moi. Neu ham duoc dung trong predicate, planner can tinh expression de so sanh cho moi candidate row, tru khi co expression index hoac cot normalized phu hop.

### Performance implications

Lower/upper tren nhieu text co chi phi CPU. Ordinary index tren email raw khong luon phuc vu predicate lower(email). Trong PostgreSQL, co the dung expression index:

~~~sql
CREATE INDEX customers_lower_email_idx
ON sales.customers (lower(email));
~~~

Nhung index nay co write/storage overhead va van can kiem tra plan.

### Common mistakes

- Nghĩ upper/lower la normalization day du cho Unicode.
- Dung lower(email) lam uniqueness ma khong co unique expression index/constraint policy.
- Lower gia tri de display va lam mat case ma user muon thay.
- Tao index nhung khong dung dung expression, vi du index email raw trong khi query lower(email).

### Production notes

Cho login/search, xac dinh identity policy truoc: trim hay khong, case folding nao, Unicode normalization nao, va NULL co hop le khong. Sau do enforce o write boundary va test uniqueness. Hien thi co the giu original value.

## Concept 6 - TRIM, LTRIM va RTRIM

### Truc giac

TRIM don leading/trailing character theo quy tac duoc chi dinh. Trong su dung thong thuong, trim whitespace o hai dau chuoi.

### Dinh nghia formal

PostgreSQL trim/btrim bo mot chuoi ky tu dai nhat o dau va cuoi, gom cac ky tu duoc chi dinh; mac dinh la space. ltrim va rtrim chi xu ly mot dau. Trim khong xoa khoang trang giua cac tu va khong mac dinh xu ly moi whitespace Unicode/tab/newline.

### Vi sao ton tai

Leading/trailing spaces thuong xuat hien do import fixed-width, copy/paste, CSV hoac input form. Chung lam sai exact comparison, prefix, length va output.

### Co che

~~~sql
WITH sample(raw_name) AS (
    VALUES (' John '), ('Maria'), ('  An  ')
)
SELECT
    raw_name,
    btrim(raw_name) AS trimmed_name,
    ltrim(raw_name) AS left_trimmed,
    rtrim(raw_name) AS right_trimmed,
    char_length(raw_name) <> char_length(btrim(raw_name)) AS has_edge_space
FROM sample;
~~~

Predicate phat hien du lieu dirty:

~~~sql
SELECT customer_id, full_name
FROM sales.customers
WHERE full_name <> btrim(full_name);
~~~

Trong PostgreSQL, so sanh voi NULL khong tra TRUE. Neu can audit NULL rieng, dung IS NULL.

### Internal behavior

Ham doc chuoi tu dau/cuoi va tao gia tri moi. Do dai chuoi anh huong CPU, nhung trim thuong re hon so voi I/O cua mot full table scan. Trim trong WHERE co the lam ordinary index khong dung duoc cho lookup exact.

### Performance implications

- Dung trim trong SELECT tren page nho thuong hop ly.
- Dung trim trong WHERE tren table lon can index strategy.
- Neu invariant la khong co edge space, enforce o write boundary va co check constraint khi phu hop.
- Internal whitespace can regexp_replace, nhung regex co the dat hon trim thong thuong.

### Common mistakes

- Nghĩ trim xoa moi khoang trang trong chuoi.
- Dung trim de sua du lieu nhung khong commit data repair.
- Khong xu ly chuoi rong sau trim.
- Trim column trong join key va khong co generated/normalized value.
- Quen NULL khong bang chuoi rong.

### Production notes

Hay tao cot cleaned trong audit query truoc khi update. Chay migration theo batch neu table lon, ghi metric so row bi sua, va xac nhan unique/index sau backfill. Khong silent trim du lieu co y nghia nhu password, token hoac signed payload.

## Concept 7 - REPLACE

### Truc giac

REPLACE tim moi occurrence cua mot substring va thay bang substring moi. Neu replacement la chuoi rong, no xoa occurrence do.

### Dinh nghia formal

PostgreSQL replace(text, from, to) thay the tat ca occurrence cua from trong text. Day la thay the theo substring, khong phai parser hieu format dien thoai, email hay URL.

### Vi sao ton tai

REPLACE phu hop voi transformation cuc bo nhu bo dau gach trong phone demo, doi extension trong filename, hoac sua delimiter da biet. No khong duoc coi la domain validator.

### Vi du

~~~sql
SELECT
    replace('090-123-4567', '-', '') AS digits_only_demo,
    replace('invoice.txt', '.txt', '.csv') AS renamed_demo;
~~~

Voi du lieu table:

~~~sql
SELECT
    customer_id,
    phone,
    replace(phone, '-', '') AS phone_without_dashes
FROM sales.customers
WHERE phone IS NOT NULL;
~~~

### Internal behavior

Executor quet chuoi va tao output moi. PostgreSQL replace thay tat ca occurrence. Neu from la chuoi rong, khong nen suy dien business behavior ma khong doc docs va test; cac ham/DBMS co the co edge semantics khac nhau.

### Performance implications

Chi phi gan theo do dai input va output. Output dai hon input co the tang memory/network. Dung replace trong predicate co the lam mat ordinary index. Neu can search canonical phone, luu canonical representation hoac tao expression index sau khi xem xet policy.

### Common mistakes

- Replace moi ky tu khong phai digit va goi la phone validation.
- Replace substring trong ten san pham, URL hoac ma don hang ma khong co domain rule.
- Dung replace trong UPDATE tren cot raw va khong co audit.
- Khong test multiple occurrence, NULL, empty string.
- Khong phan biet display format voi storage format.

### Production notes

So dien thoai production nen co policy ro rang, vi du E.164, va validation library/domain rule phu hop. REPLACE co the la mot buoc trong pipeline, khong phai toan bo pipeline.

## Concept 8 - LENGTH, CHAR_LENGTH va OCTET_LENGTH

### Truc giac

Do dai chuoi co it nhat hai y nghia: so ky tu ma nguoi dung thay, hoac so byte ma storage/network su dung.

### Dinh nghia formal

Trong PostgreSQL:

- length(text) va char_length(text) dem so character.
- octet_length(text) dem so byte.
- character length khong nhat thiet bang so grapheme ma user nhin thay; mot emoji co the gom nhieu code point.

Transcript dung LEN. **Note: trong SQL Server, LEN bo qua trailing spaces. PostgreSQL length(text) la ham khac va dem character, ke ca trailing spaces trong text.** Khi chuyen transcript SQL Server sang PostgreSQL, phai doi LEN thanh length/char_length va viet test edge case.

### Vi du

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

Voi text co ky tu non-ASCII, byte_count co the lon hon character_count. Dung octet_length khi can uoc luong payload/storage; dung char_length khi rule noi ve so ky tu.

### Internal behavior

Database doc va dem chuoi theo representation va encoding. Dem character va dem byte la hai operation khac. Function nay khong tu dong validate max length theo UX hay byte limit cua external service.

### Performance implications

Dem length can doc phan chuoi; tren mot cot lon co the ton CPU. Predicate length(column) > n thuong can xem nhieu row. Neu can enforce do dai input, CHECK constraint hoac application validation phu hop hon viec scan moi lan.

### Common mistakes

- Dung byte length thay cho character length trong UI validation.
- Tin SQL Server LEN va PostgreSQL length cung semantics trailing space.
- Nghĩ length(NULL) la 0; trong SQL, ket qua la NULL.
- Dung length de thay the email/phone validator.
- Khong test Unicode va trailing spaces.

### Production notes

Ghi ro rule la characters, bytes hay grapheme clusters. Neu external API co byte limit, dung octet_length o boundary. Neu database column la varchar(n), van doc vendor docs va test, vi semantic length constraint co the phu thuoc DBMS.

## Concept 9 - LEFT va RIGHT

### Truc giac

LEFT lay n character o dau chuoi; RIGHT lay n character o cuoi chuoi. Chung huu ich cho prefix/suffix, nhung ket qua phu thuoc whitespace va viec n co nam trong range hay khong.

### Dinh nghia formal

PostgreSQL left(text, n) va right(text, n) lam viec theo character count. Vi tri khong dung trong LEFT/RIGHT; n la so ky tu. PostgreSQL con co semantics cho n am, nhung lesson tap trung n khong am de tranh nham.

### Vi du

~~~sql
SELECT
    customer_id,
    left(btrim(full_name), 2) AS first_two_chars,
    right(btrim(full_name), 2) AS last_two_chars
FROM sales.customers
ORDER BY customer_id;
~~~

Phai trim truoc neu business muon lay ky tu cua ten sach. Neu khong, leading space co the tro thanh first character.

### Internal behavior

Executor tinh btrim neu co, sau do dem/tach character de tao output. Ham tren column trong WHERE, vi du left(code, 3) = 'ABC', thuong khong map truc tiep vao ordinary index; prefix search co the can range predicate, collation policy hoac expression index.

### Performance implications

Dung LEFT/RIGHT o projection page nho thuong on. Dung tren toan bo table de loc co the ton CPU va I/O. Index prefix phu thuoc DBMS, collation va pattern; khong tu dong suy ra rang left(column, 3) luon dung B-tree.

### Common mistakes

- Cat prefix truoc khi trim.
- Nham character voi byte.
- Dung RIGHT de an secret nhung van tra full value trong API/log.
- Khong quy dinh n khi chuoi ngan hon n.
- Dung prefix lam identity duy nhat.

### Production notes

An so the thanh toan chi nen expose 4 digit cuoi neu policy cho phep, nhung access control va logging van quan trong. LEFT/RIGHT la presentation helper, khong phai security boundary.

## Concept 10 - SUBSTRING

### Truc giac

SUBSTRING lay mot doan text bat dau tu vi tri cu the. No phu hop khi can bo ky tu dau, lay doan ma o giua, hoac tach segment co format on dinh.

### Dinh nghia formal

PostgreSQL dung substring(text FROM start FOR count), vi tri start la 1-based. Co the bo qua FOR count de lay den het chuoi; substr(text,start,count) la spelling thay the trong PostgreSQL. SQL Server thuong dung SUBSTRING(expression, start, length), nen syntax trong transcript can chuyen khi viet PostgreSQL.

### Vi du

~~~sql
SELECT
    customer_id,
    substring(btrim(full_name) FROM 2) AS without_first_character,
    substring(btrim(email) FROM 1 FOR 5) AS email_prefix
FROM sales.customers;
~~~

Task bo ky tu dau khong nen hard-code count bang mot gia tri nho. Dung substring(... FROM 2) de lay phan con lai; PostgreSQL tu ket thuc khi vuot do dai, khong nem loi chi vi count lon hon phan con lai.

### Internal behavior

Executor xac dinh start/count, dem theo character va tao text output. Nested btrim -> substring co nghia btrim chay truoc. Vi tri nam ngoai range co the cho chuoi rong hoac phan cat rong tuy input, can test thay vi doan.

### Performance implications

Giong LEFT/RIGHT: chi phi theo do dai input/output va so row. Dung substring trong predicate co the lam ordinary index khong phuc vu. Neu format co cau truc on dinh va query thuong xuyen, xem xet cot parsed/generated hoac expression index.

### Common mistakes

- Dung vi tri 0 vi quen PostgreSQL la 1-based.
- Cat raw value co leading space.
- Dung substring de parse format phuc tap thay vi parser/domain validation.
- Hard-code length ma khong test chuoi ngan.
- Ghi output substring de thay raw data trong migration ma khong co audit.

### Production notes

SUBSTRING tot cho projection va format don gian. Voi email, URL, phone, currency code hoac identifier co quy tac phuc tap, nen parse va validate o domain boundary; SQL expression khong tu dong dam bao input hop le.

## 4. SQL Examples

### 4.1 Tao display label ma khong sua du lieu

~~~sql
SELECT
    c.customer_id,
    c.full_name AS raw_name,
    btrim(c.full_name) AS clean_name,
    concat_ws(' / ', btrim(c.full_name), c.country) AS display_label
FROM sales.customers AS c
ORDER BY c.customer_id;
~~~

Schema: dung sales.customers tu bootstrap cua repository. Expected result: moi customer co ten sach hon; country NULL khong tao them separator rong trong concat_ws. Query chi tao result, khong UPDATE table.

### 4.2 Tao cot audit de phat hien whitespace

~~~sql
SELECT
    c.customer_id,
    c.full_name,
    btrim(c.full_name) AS proposed_name,
    char_length(c.full_name) AS raw_length,
    char_length(btrim(c.full_name)) AS cleaned_length,
    c.full_name IS NULL AS is_null,
    c.full_name IS NOT NULL
        AND c.full_name <> btrim(c.full_name) AS has_edge_whitespace
FROM sales.customers AS c
ORDER BY c.customer_id;
~~~

Expected result: row co khoang trang dau/cuoi co has_edge_whitespace = true. NULL duoc danh dau rieng, khong bi nham voi chuoi rong.

### 4.3 Normalize mot lookup key

~~~sql
SELECT
    c.customer_id,
    lower(btrim(c.email)) AS normalized_email
FROM sales.customers AS c
WHERE c.email IS NOT NULL;
~~~

Day la representation de kiem tra/search. Khong tu dong ket luan hai email lower cung la cung user neu domain policy chua quy dinh.

### 4.4 Prefix, suffix va substring

~~~sql
SELECT
    c.customer_id,
    btrim(c.full_name) AS clean_name,
    left(btrim(c.full_name), 2) AS prefix_two,
    right(btrim(c.full_name), 2) AS suffix_two,
    substring(btrim(c.full_name) FROM 2) AS without_first
FROM sales.customers AS c
ORDER BY c.customer_id;
~~~

Expected result phu thuoc seed data. Diem can kiem tra la prefix/suffix duoc tinh sau trim va substring bat dau tu 1-based position 2.

### 4.5 Data repair co kiem soat

Khong chay UPDATE truc tiep tren production chi vi thay query SELECT cho ket qua dep. Quy trinh an toan hon:

~~~sql
BEGIN;

CREATE TEMP TABLE customer_name_review AS
SELECT
    customer_id,
    full_name AS old_name,
    btrim(full_name) AS proposed_name
FROM sales.customers
WHERE full_name IS NOT NULL
  AND full_name <> btrim(full_name);

SELECT * FROM customer_name_review ORDER BY customer_id;

-- Chi sau khi review va test invariant:
-- UPDATE sales.customers AS c
-- SET full_name = r.proposed_name
-- FROM customer_name_review AS r
-- WHERE c.customer_id = r.customer_id;

ROLLBACK;
~~~

Trong lab co the thay ROLLBACK bang COMMIT sau khi da co migration plan, audit va backup strategy. Vi du nay nhan manh transaction boundary, khong phai khuyen khich sua raw data tuy y.

## 5. What Happens Internally?

~~~text
Client
  |
  v
SQL text
  |
  v
Parser + analyzer
  |  resolve function name, argument type, column
  v
Planner / optimizer
  |  choose scan, filter, projection, index possibility
  v
Executor
  |  read rows/pages and evaluate expressions
  v
btrim -> lower -> substring -> output tuple
  |
  v
Network result or DML/WAL if statement changes data
~~~

### Buoc 1 - Parse va bind

Parser doc SQL grammar. Analyzer tim ham phu hop, resolve overload, column va data type. Day la ly do cung ten ham co the co syntax hoac implicit cast khac nhau giua DBMS.

### Buoc 2 - Plan

Planner xem predicate, statistics, index va cost. SELECT list nhu lower(full_name) thuong khong quyet dinh row nao duoc doc; WHERE lower(email) = ... lai lien quan truc tiep den access path.

### Buoc 3 - Doc page

Executor co the sequential scan, index scan hoac bitmap scan tuy plan. Buffer manager lay page tu shared buffers/cache hoac storage. Ham chuoi chay tren gia tri da doc vao executor.

### Buoc 4 - Evaluate expression

Voi scalar function, expression duoc danh gia cho moi candidate row. NULL semantics duoc giu theo function/operator. Vi du, lower(NULL) la NULL; length(NULL) la NULL; predicate WHERE can TRUE moi giu row.

### Buoc 5 - Tra output

Projection tao output tuple. Neu la SELECT, ket qua gui cho client. Neu la UPDATE/INSERT, thay doi row di qua concurrency control va WAL theo semantics cua PostgreSQL; string function tu than khong lam phat sinh persistence.

### Function tren column va index

Query sau can transform email cua tung candidate:

~~~sql
SELECT customer_id
FROM sales.customers
WHERE lower(email) = 'alice@example.com';
~~~

Ordinary index tren email khong phai luc nao cung dung duoc de tra lower(email). Hai huong thuong gap:

~~~sql
CREATE INDEX customers_lower_email_idx
ON sales.customers (lower(email));
~~~

Hoac tao cot normalized duoc cap nhat o write boundary, sau do index cot do. Expression index tang chi phi write va storage, va chi co ich neu query expression giong expression index. Luon verify bang EXPLAIN.

## 6. Mental Models

- Ham chuoi la expression, khong phai phep mau sua storage.
- Cleaned value va raw value la hai loai thong tin khac nhau; hay giu ca hai khi can audit.
- Doc nested function tu trong ra ngoai.
- CONCAT la chon quy tac NULL; || la mot operator co quy tac khac.
- Trim xu ly edge characters, khong phai lam sach moi thu.
- Character count khac byte count.
- Vi tri substring cua PostgreSQL bat dau tu 1.
- Function tren column co the doi access path tu index lookup sang scan.
- Normalization cho search can di kem uniqueness, locale va index policy.
- EXPLAIN cho biet planner dang lam gi; no khong thay the cho data contract.

## 7. Compare Similar Concepts

### 7.1 CONCAT, CONCAT_WS va || trong PostgreSQL

| Cong cu | Xu ly NULL | Separator | Typical use | Can than |
| --- | --- | --- | --- | --- |
| CONCAT | Bo qua argument NULL | Tu truyen nhu mot argument | Noi nhieu value | Phan biet NULL va empty string |
| CONCAT_WS | Bo qua argument NULL | Separator dau tien | Label co delimiter | Separator NULL lam ket qua NULL |
| || | Operand NULL co the lam ket qua NULL | Tu tu viet | Noi chuoi don gian | Khac semantics concat; phai test |

### 7.2 Do dai chuoi

| Ham | Don vi | PostgreSQL | Typical use |
| --- | --- | --- | --- |
| length/char_length | Character | Dem character | Rule ve so ky tu |
| octet_length | Byte | Dem byte | Payload/storage limit |
| SQL Server LEN | Character theo SQL Server | Bo qua trailing spaces | Chi dung khi viet T-SQL va da doc vendor docs |

### 7.3 Trim va replace

| Ham | Pham vi | Vi du | Khong nen nham voi |
| --- | --- | --- | --- |
| btrim/trim | Dau va cuoi | ' John ' -> 'John' | Xoa whitespace o giua |
| ltrim | Dau trai | '  John' -> 'John' | Chuan hoa ca chuoi |
| rtrim | Dau phai | 'John  ' -> 'John' | Validation domain |
| replace | Moi substring match | '090-123' -> '090123' | Phone parser/validator |

### 7.4 Transformation o read time va write time

| Noi thuc hien | Uu diem | Rui ro | Khi dung |
| --- | --- | --- | --- |
| SELECT projection | Khong sua raw data | Lap lai CPU, moi consumer co the khac | Display, audit, exploration |
| Application boundary | Policy gan domain | Co the bi bypass boi job khac | Canonical input |
| UPDATE migration | Sua du lieu ton tai | Lock, audit, rollback, duplicate | Data repair co ke hoach |
| Generated column | Consistent derived value | Storage/write overhead, vendor-specific | Derived key query thuong xuyen |
| Expression index | Query expression nhanh hon khi phu hop | Them storage/write cost, expression phai match | Lookup normalized |

## 8. Backend Engineering Perspective

~~~text
HTTP request
      |
      v
Controller: validate shape
      |
      v
Service: decide canonicalization policy
      |
      v
Repository: parameterized SQL / ORM query
      |
      v
Database: function + plan + index + transaction
      |
      v
DTO: display representation, khong expose raw secret
~~~

### API va input boundary

Trim ten co the la UX policy. Trim password/token co the lam thay doi credential, nen khong ap dung may moc. Email normalization can xac dinh login identity, uniqueness va reset-password behavior; phai viet thanh domain rule va test.

### Search va latency

Query lower(email) tren table lon co the lam request latency tang vi scan nhieu row. Giai phap khong phai them moi index mot cach mu quang; can xem query exact, expression index, normalized column, selectivity, statistics va EXPLAIN.

### Batch cleanup

Data repair nen chay ngoai request path, theo batch, co metric va retry strategy. Goi trim cho moi row trong HTTP request khong phai cach tot de sua hang tram nghin row.

### ORM va N+1

String function khong tu tao N+1. Tuy nhien, ORM co the sinh query function trong moi request hoac load entity roi transform trong Java cho tung row. Hay project dung column can thiet, push transformation xuong DB khi phu hop, va kiem tra so query/plan thay vi doan qua ten method.

## 9. ORM Perspective

### Raw SQL

~~~sql
SELECT c.customer_id, lower(btrim(c.email)) AS normalized_email
FROM sales.customers AS c
WHERE lower(btrim(c.email)) = lower(btrim(:email));
~~~

### JPQL/Hibernate

~~~java
@Query("""
    select c
    from Customer c
    where lower(trim(c.email)) = lower(trim(:email))
    """)
Optional<Customer> findByNormalizedEmail(@Param("email") String email);
~~~

JPQL co cac ham portable nhu LOWER, UPPER, TRIM, LENGTH, SUBSTRING, CONCAT o muc nhat dinh. Syntax SQL generated phu thuoc dialect. Neu dung function PostgreSQL rieng, co the can function registration hoac native query.

### Can biet gi khi dung Spring Data

- Method name query khong tu dong tao expression index.
- Query lower(trim(email)) can index dung expression hoac cot normalized.
- Lazy loading va projection la van de khac voi string function, nhung deu anh huong API latency.
- Bat SQL logging o moi truong phu hop, dung p6spy/datasource proxy neu can, va doc EXPLAIN query that.
- Parameterize input; khong noi chuoi SQL trong application.

## 10. Performance Engineering

### Sargability

Mot predicate de planner dung index thuong can co dang phu hop voi key/index. So sanh:

~~~sql
-- Co the khong dung ordinary index tren email:
WHERE lower(email) = 'alice@example.com'

-- Neu policy cho phep va input da normalized o application:
WHERE email_normalized = 'alice@example.com'
~~~

Hoac voi PostgreSQL:

~~~sql
CREATE INDEX customers_lower_trim_email_idx
ON sales.customers (lower(btrim(email)));
~~~

Expression index phai khop expression logic. Khong nen tao index chi vi query co function; hay do workload, selectivity, write rate va plan.

### EXPLAIN

~~~sql
EXPLAIN (COSTS OFF)
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = 'alice@example.com';
~~~

Doc plan theo thu tu:

1. Scan node nao doc table/index?
2. Predicate nam o Index Cond hay Filter?
3. Row estimate co hop ly khong?
4. Co Sort, Hash, Materialize hay row explosion khong?
5. Query thuc te co can BUFFERS va ANALYZE khong?

Dung EXPLAIN ANALYZE tren query SELECT read-only hoac transaction co rollback. EXPLAIN ANALYZE thuc thi query; khong chay tuy tien tren UPDATE/DELETE production.

~~~sql
BEGIN;

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = 'alice@example.com';

ROLLBACK;
~~~

Voi table nho, planner van co the chon sequential scan vi re hon index scan. Do khong phai bang chung index vo dung; do la cost-based choice.

### Cardinality va selectivity

- Email thuong co selectivity cao neu unique, nen lookup co the loi tu index.
- Country hoac first character co selectivity thap, index co the khong dang ke.
- Ham length/replace co the khong co statistics tot cho expression neu khong co generated column/index analyze.
- Khong phat minh benchmark number; do bang execution plan va production telemetry.

## 11. Common Interview Questions

### Junior

1. **CONCAT khac || trong PostgreSQL o diem nao?**
   CONCAT bo qua argument NULL; || co the lam ca expression thanh NULL khi operand NULL.

2. **TRIM co xoa khoang trang o giua chuoi khong?**
   Khong. No tap trung vao dau/cuoi theo tap ky tu duoc chi dinh.

3. **PostgreSQL SUBSTRING bat dau tu vi tri nao?**
   Vi tri 1.

4. **length va octet_length khac nhau the nao?**
   length/char_length dem character; octet_length dem byte.

5. **lower(column) trong SELECT co sua column khong?**
   Khong, no chi tao gia tri projection.

### Mid-level

6. **Tai sao lower(email) co the lam ordinary index tren email khong dung duoc?**
   Gia tri can so sanh la expression, khong phai raw key; planner co the phai tinh cho nhieu row. Dung expression index hoac normalized column neu workload can.

7. **Khi nao dung CONCAT_WS?**
   Khi can noi nhieu field voi separator va muon bo qua field NULL mot cach ro rang.

8. **Tai sao phai trim truoc LEFT(full_name, 2)?**
   Leading space se bi coi la character dau tien va lam sai prefix business.

9. **Vi sao transformation trong SELECT an toan hon UPDATE?**
   SELECT khong thay doi persistence; UPDATE can lock/WAL/audit va co the anh huong invariant.

10. **Aggregate function khac window function o shape output the nao?**
    Aggregate rut gon row theo group; window van tra ket qua cho tung row.

### Senior / Deep Understanding

11. **Index expression lower(btrim(email)) co nhung trade-off gi?**
    Tang storage va chi phi insert/update; query phai dung expression phu hop; planner van can statistics va co the chon scan voi table nho.

12. **Co nen lower moi email khi luu khong?**
    Chi khi domain policy xac dinh case folding, uniqueness va display. Giu raw value neu can va luu canonical value co ten/constraint ro rang.

13. **Tai sao replace khong phai validator quan trong trong phone normalization?**
    Replace chi thay substring; no khong kiem tra country code, length, extension, digit semantics hay format hop le.

14. **Tai sao EXPLAIN ANALYZE can than voi DML?**
    No thuc thi statement. UPDATE/DELETE co the thay doi data, tao lock va WAL. Dung transaction/rollback khi test va khong chay blind tren production.

15. **Khi nao generated column tot hon expression index?**
    Khi can expose canonical value cho nhieu consumer, can constraint/unique tren value do, hoac muon query don gian. Van phai can nhac storage, write cost va tinh vendor-specific.

## 12. Common Misconceptions

## Things Developers Often Get Wrong

### Sai: Them string function vao SELECT la da clean data

Vi sao sai: SELECT chi tao output. Raw storage van giu gia tri cu.

Mental model dung: phan biet projection, data repair va canonical storage.

### Sai: LOWER la quy tac case-insensitive universal

Vi sao sai: locale, collation, Unicode va domain rule anh huong ket qua.

Mental model dung: case folding la policy; test input thuc te va enforce o boundary.

### Sai: TRIM xoa moi whitespace

Vi sao sai: trim chu yeu xu ly edge characters theo tap quy dinh; no khong sua internal whitespace, tab/newline theo moi mong muon.

Mental model dung: dung trim cho edge; dung regex/domain parser cho format phuc tap.

### Sai: length luon la so byte

Vi sao sai: PostgreSQL length text dem character; octet_length moi dem byte.

Mental model dung: viet ro don vi trong ten cot, test Unicode.

### Sai: SQL Server LEN va PostgreSQL length la mot

Vi sao sai: SQL Server LEN bo qua trailing spaces; PostgreSQL length(text) co semantics khac.

Mental model dung: doc vendor docs truoc khi migrate syntax.

### Sai: Moi function tren column deu lam query full scan

Vi sao sai: expression index, generated column hoac rewrite co the cho planner access path phu hop; nhung khong phai tu dong.

Mental model dung: kiem tra predicate, index expression va EXPLAIN.

### Sai: REPLACE co the validate phone/email

Vi sao sai: no chi thay substring, khong hieu domain.

Mental model dung: normalize la mot buoc; validation la mot buoc khac.

### Sai: LEFT/RIGHT co the an secret mot cach an toan

Vi sao sai: ham chi tao output; log, authorization, query va transport van la security concerns.

Mental model dung: masking can data minimization, access control va review logging.

## 13. Failure Scenarios

### Scenario 1 - Login cham sau khi them lower

~~~text
Table sales.customers: lon
Query: WHERE lower(email) = lower(:input)
Index: chi co tren email raw
~~~

Van de: planner co the khong dung raw index cho expression va phai scan/tinh lower tren nhieu row. Cach dieu tra: EXPLAIN, actual rows, buffers, query frequency. Cach sua: normalized column hoac expression index, them uniqueness policy, benchmark voi workload that.

### Scenario 2 - Label bi sai khi country NULL

~~~sql
SELECT full_name || ' - ' || country
FROM sales.customers;
~~~

Van de: trong PostgreSQL, operand NULL co the lam ket qua NULL. Dung concat_ws neu muon bo qua NULL separator field, hoac CASE/COALESCE neu business muon label mac dinh cu the. Khong chon COALESCE chi de lam query khong null ma khong xac dinh y nghia.

### Scenario 3 - Prefix sai do dirty whitespace

~~~sql
SELECT left(full_name, 2)
FROM sales.customers;
~~~

Mot ten co leading space se co prefix bat dau bang space. Trieu chung: grouping/prefix report sai va substring tiep theo sai. Cach sua: btrim truoc, audit raw data, sau do quyet dinh co backfill hay khong.

### Scenario 4 - UPDATE replace pha du lieu hien thi

~~~sql
UPDATE products
SET product_name = replace(product_name, 'old', 'new');
~~~

Van de: substring co the xuat hien trong mot tu hop le, uppercase khac, hoac ten can giu raw. Cach sua: preview SELECT, gioi han predicate, backup/audit, transaction, review sample va migration idempotency. Neu chi can report moi, tao projection thay vi sua raw.

## 14. Hands-on Lab

Lab dung PostgreSQL va khong phu thuoc seed ngoai tru experiment 6. Chay tung block trong cung mot psql session de temp table ton tai.

### Setup

~~~sql
CREATE TEMP TABLE lab_contacts (
    contact_id integer PRIMARY KEY,
    raw_name text,
    country text,
    phone text,
    note text
) ON COMMIT DROP;

INSERT INTO lab_contacts (contact_id, raw_name, country, phone, note)
VALUES
    (1, ' John ', 'VN', '090-123-4567', '  welcome  '),
    (2, 'Maria', NULL, '0901234567', 'active'),
    (3, '  Đặng An  ', 'VN', NULL, E'line1\nline2');
~~~

### Experiment 1 - NULL va noi chuoi

#### Prediction

Voi contact 2, concat_ws co giu separator thua khong? Toan tu || tra ve gi?

#### Run

~~~sql
SELECT
    contact_id,
    concat_ws(' - ', btrim(raw_name), country) AS with_ws,
    concat(btrim(raw_name), ' - ', country) AS with_concat,
    btrim(raw_name) || ' - ' || country AS with_operator
FROM lab_contacts
ORDER BY contact_id;
~~~

#### Observe

So sanh dong country NULL va doc ky output cua ba cot.

#### Explanation

concat_ws bo qua argument NULL; concat bo qua NULL argument nhung literal separator van la argument rieng; || co semantics NULL propagation trong PostgreSQL. Chon ham theo output contract, khong theo thoi quen.

### Experiment 2 - Audit whitespace

#### Prediction

Row nao co raw_name khac btrim(raw_name)? Chuoi rong co tu dong duoc coi la NULL khong?

#### Run

~~~sql
SELECT
    contact_id,
    raw_name,
    btrim(raw_name) AS clean_name,
    char_length(raw_name) AS raw_chars,
    char_length(btrim(raw_name)) AS clean_chars,
    raw_name <> btrim(raw_name) AS has_edge_space,
    raw_name = '' AS is_empty,
    raw_name IS NULL AS is_null
FROM lab_contacts
ORDER BY contact_id;
~~~

#### Observe

Chu y is_empty va is_null la hai khai niem khac. Chuoi co newline trong note khong duoc sua boi btrim neu newline nam ben trong.

#### Explanation

SQL co NULL rieng, khong dong nghia chuoi rong. Trim chi xu ly edge theo rule, khong chuan hoa toan bo whitespace.

### Experiment 3 - REPLACE va case

#### Prediction

Phone co dau gach se thay doi the nao? upper/lower co sua raw_name khong?

#### Run

~~~sql
SELECT
    contact_id,
    phone,
    replace(phone, '-', '') AS phone_digits_demo,
    upper(btrim(raw_name)) AS upper_name,
    lower(btrim(raw_name)) AS lower_name
FROM lab_contacts
ORDER BY contact_id;
~~~

#### Observe

Raw columns van giu nguyen. Kiem tra phone NULL va chuoi khong co dau gach.

#### Explanation

Ham tra output moi; NULL input thuong cho NULL output voi replace. Replace khong phai phone validator.

### Experiment 4 - Character va byte

#### Prediction

Voi ten co ky tu non-ASCII, char_length co bang octet_length khong?

#### Run

~~~sql
SELECT
    contact_id,
    raw_name,
    char_length(raw_name) AS character_count,
    octet_length(raw_name) AS byte_count
FROM lab_contacts
ORDER BY contact_id;
~~~

#### Observe

So sanh row 3 voi row 1. Khong dung mot con so cho ca UI character limit va network byte limit.

#### Explanation

PostgreSQL text duoc luu theo encoding; character count va byte count la hai metric khac.

### Experiment 5 - LEFT, RIGHT va SUBSTRING

#### Prediction

Neu khong btrim, prefix cua row 1 va row 3 co the bat dau bang gi?

#### Run

~~~sql
SELECT
    contact_id,
    raw_name,
    left(raw_name, 2) AS raw_prefix,
    left(btrim(raw_name), 2) AS clean_prefix,
    right(btrim(raw_name), 2) AS clean_suffix,
    substring(btrim(raw_name) FROM 2) AS without_first
FROM lab_contacts
ORDER BY contact_id;
~~~

#### Observe

Vi tri substring la 1-based. So sanh raw_prefix va clean_prefix.

#### Explanation

Btrim nen nam o lop trong khi business muon thao tac tren ten sach. substring FROM 2 lay tu ky tu thu hai den het.

### Experiment 6 - Function predicate va expression index

#### Prediction

Voi table sales.customers nho, sau khi tao expression index planner co chac chan dung index khong?

#### Run

~~~sql
EXPLAIN (COSTS OFF)
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = 'alice@example.com';

CREATE INDEX IF NOT EXISTS sales.lab_customers_lower_email_idx
ON sales.customers (lower(btrim(email)));

ANALYZE sales.customers;

EXPLAIN (COSTS OFF)
SELECT customer_id
FROM sales.customers
WHERE lower(btrim(email)) = 'alice@example.com';

DROP INDEX IF EXISTS sales.lab_customers_lower_email_idx;
~~~

#### Observe

Doc scan node, Filter/Index Cond va row estimate. Table nho co the van chon sequential scan.

#### Explanation

Expression index mo ra access path, khong ep planner phai dung no. Cost, table size, statistics va selectivity quyet dinh plan. Luon xem query workload that truoc khi giu index.

## 15. Exercises

### Level 1 - Recall

1. Data transformation trong SELECT co sua du lieu goc khong?
2. Phan biet scalar function, aggregate function va window function.
3. CONCAT_WS dung separator o vi tri nao?
4. TRIM mac dinh xu ly phan nao cua chuoi trong PostgreSQL?
5. length va octet_length do gi?
6. Vi tri bat dau cua PostgreSQL SUBSTRING la bao nhieu?
7. Vi sao chuoi rong khac NULL?
8. REPLACE co phai la phone validator khong? Giai thich ngan gon.

### Level 2 - Apply

1. Viet query tao display label tu full_name va country, bo qua country NULL ma khong sua table.
2. Viet query phat hien customer co leading/trailing whitespace trong full_name.
3. Viet query lay 3 ky tu dau va 3 ky tu cuoi cua full_name sau khi trim.
4. Viet query chuyen email thanh lookup key lower va trim, chi lay row email khong NULL.
5. Viet query dem ca character count va byte count cua note.
6. Giai thich ket qua cua concat, concat_ws va || khi country NULL.
7. Viet query bo dau gach khoi phone chi de preview, khong UPDATE.
8. Sua query substring de bo ky tu dau ma khong phu thuoc count co dinh.

### Level 3 - Engineering

1. Login query dung lower(btrim(email)) tren bang 100 trieu row. De xuat index/storage policy va cach verify.
2. Team muon trim tat ca ten trong production ngay trong request. Phan tich rui ro va thiet ke batch repair an toan.
3. Product name can thay substring pro thanh premium. Neu replace co the sua nham tu, ban thiet ke migration/validation the nao?
4. External API gioi han 256 bytes, UI gioi han 100 ky tu. Chon ham va boundary validation phu hop.
5. ORM sinh lower(trim(email)) nhung query van cham. Lap checklist dieu tra tu SQL generated den EXPLAIN.
6. Data team noi LEN va length giong nhau khi migrate SQL Server sang PostgreSQL. Viet test edge cases de chan regression.

## 16. Debugging Challenges

### Challenge 1

~~~sql
SELECT customer_id
FROM sales.customers
WHERE trim(lower(email)) = :input;
~~~

Hay chi ra van de ve input normalization, NULL, index va cach sua.

### Challenge 2

~~~sql
SELECT full_name || ', ' || country AS customer_label
FROM sales.customers;
~~~

Hay giai thich khi country NULL va dua ra hai cach sua voi semantics khac nhau.

### Challenge 3

~~~sql
UPDATE sales.customers
SET full_name = trim(full_name);
~~~

Hay review rui ro production, cach preview, transaction, audit va dieu kien WHERE.

### Challenge 4

~~~sql
SELECT left(full_name, 2), length(full_name)
FROM sales.customers
WHERE length(full_name) > 0;
~~~

Hay tim cac van de ve NULL, whitespace, Unicode, prefix va performance; sau do de xuat query ro hon.

## 17. Knowledge Check

Bo cau hoi rieng nam trong [knowledge-check-strings.md](knowledge-check-strings.md), dap an nam trong [knowledge-check-strings-answers.md](knowledge-check-strings-answers.md).

## 18. Summary

### Core Ideas

- Transformation tao representation moi; SELECT khong tu dong sua storage.
- Scalar, aggregate va window function co shape output khac nhau.
- Nested function doc tu trong ra ngoai.
- NULL semantics cua CONCAT, CONCAT_WS va || khac nhau.
- Trim chi xu ly edge characters theo rule.
- Character count va byte count khac nhau.
- PostgreSQL SUBSTRING bat dau tu 1.
- Function tren column co the anh huong access path va index.

### Key Terms

Data transformation, scalar function, aggregate, window function, NULL propagation, CONCAT_WS, case folding, collation, trim, replace, character length, byte length, substring, expression index, generated column, sargability, selectivity, EXPLAIN.

### Rules of Thumb

- Preview bang SELECT truoc khi UPDATE.
- Normalize identity o mot boundary ro rang va enforce bang constraint/index khi can.
- Dung concat_ws cho label co separator va NULL.
- Dung char_length cho character rule, octet_length cho byte rule.
- Trim truoc prefix/substring neu whitespace la dirty data.
- Khong tin function index ma chua xem EXPLAIN.
- Khong coi replace la validator.

### Things Worth Memorizing

- PostgreSQL substring position la 1-based.
- length/char_length dem character; octet_length dem byte.
- SQL Server LEN bo qua trailing spaces.
- Expression index phai phu hop voi expression query.
- EXPLAIN ANALYZE thuc thi statement.

### Things Must Be Understood

- Khi nao representation moi chi la display va khi nao la canonical identity.
- NULL, empty string va whitespace tac dong den business semantics.
- Vi sao planner chon scan/index dua tren cost, khong dua tren cam ket cua developer.
- Trade-off giua raw data, normalized column, generated column va expression index.

## 19. Cheat Sheet

### PostgreSQL string functions

~~~sql
SELECT
    concat(a, b),
    concat_ws(' / ', a, b),
    upper(value),
    lower(value),
    btrim(value),
    ltrim(value),
    rtrim(value),
    replace(value, 'old', 'new'),
    length(value),
    char_length(value),
    octet_length(value),
    left(value, 2),
    right(value, 2),
    substring(value FROM 2),
    substring(value FROM 1 FOR 5);
~~~

### Audit whitespace

~~~sql
WHERE value IS NOT NULL
  AND value <> btrim(value)
~~~

### Canonical lookup expression

~~~sql
lower(btrim(email))
~~~

### Expression index PostgreSQL

~~~sql
CREATE INDEX customers_lower_trim_email_idx
ON sales.customers (lower(btrim(email)));
~~~

### Kiem tra plan

~~~sql
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT ...
~~~

Nho: EXPLAIN ANALYZE chay query that.

## 20. Connections to Future Topics

~~~text
String functions
      |
      v
Data quality + NULL/CASE
      |
      v
Numeric/date transformation + casting
      |
      v
GROUP BY + aggregate functions
      |
      v
Window functions
      |
      v
Expression index + execution plan
      |
      v
ETL, constraints, transactions va data warehouse
~~~

String transformation la mot gateway vao query processing sau hon. Khi da hieu expression va NULL, ban de hoc numeric/date functions va CASE. Khi da hieu function tren column anh huong index, ban co nen tang de hoc optimizer, statistics va expression index. Khi transformation duoc dua vao pipeline, transaction, idempotency va data quality monitoring tro thanh phan production bat buoc.

## References

- [PostgreSQL string functions and operators](https://www.postgresql.org/docs/current/functions-string.html)
- [PostgreSQL collation support](https://www.postgresql.org/docs/current/collation.html)
- [PostgreSQL indexes on expressions](https://www.postgresql.org/docs/current/indexes-expressional.html)
- [PostgreSQL using EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html)
- [PostgreSQL conditional expressions and NULL behavior](https://www.postgresql.org/docs/current/functions-conditional.html)
- [Microsoft SQL Server LEN](https://learn.microsoft.com/en-us/sql/t-sql/functions/len-transact-sql?view=sql-server-ver17)
- [Microsoft SQL Server CONCAT](https://learn.microsoft.com/en-us/sql/t-sql/functions/concat-transact-sql?view=sql-server-ver17)
- [Microsoft SQL Server SUBSTRING](https://learn.microsoft.com/en-us/sql/t-sql/functions/substring-transact-sql?view=sql-server-ver17)

## Transcript Coverage Map

| Transcript topic | Document section | Expanded | Notes |
| --- | --- | --- | --- |
| 056 - What is Data Transformation | Concepts 1, 5, 8, 13 | Yes | Them distinction giua projection, canonicalization va data repair |
| 057 - SQL Functions | Concept 2, 3 | Yes | Them scalar, aggregate, window va nested evaluation |
| 058 - CONCAT | Concept 4, SQL examples, lab | Yes | Them CONCAT_WS, NULL behavior va production label |
| 059 - UPPER and LOWER | Concept 5, performance | Yes | Them locale, identity policy va expression index |
| 060 - TRIM | Concept 6, lab, failure scenarios | Yes | Them ltrim/rtrim, edge whitespace va audit |
| 061 - REPLACE | Concept 7, lab | Yes | Them all-occurrence semantics va validator boundary |
| 062 - LEN | Concept 8 | Yes | Sua LEN sang PostgreSQL length/char_length, them octet_length |
| 063 - LEFT and RIGHT | Concept 9, lab | Yes | Them trim order, prefix performance va security note |
| 064 - SUBSTRING | Concept 10, lab | Yes | Sua syntax PostgreSQL, 1-based position va dynamic count |
