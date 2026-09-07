/* ==============================================================================
   BAGIAN 1: DIEKSEKUSI SEBAGAI SYSDBA ATAU ADMINISTRATOR DATABASE
   ============================================================================== */

-- 1. Membuat Tablespace
-- Catatan: Pastikan path datafile disesuaikan dengan environment server Anda.
CREATE TABLESPACE ts_golden_warehouse 
DATAFILE 'ts_golden_warehouse_01.dbf' SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 1G
LOGGING
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- 2. Membuat User (Schema) dan memberikan hak akses
CREATE USER golden_warehouse IDENTIFIED BY "GoldenW4rehouse2026!"
DEFAULT TABLESPACE ts_golden_warehouse
QUOTA UNLIMITED ON ts_golden_warehouse;

-- Memberikan system privileges yang dibutuhkan untuk membuat semua objek
GRANT CREATE SESSION TO golden_warehouse;
GRANT CREATE TABLE TO golden_warehouse;
GRANT CREATE VIEW TO golden_warehouse;
GRANT CREATE SEQUENCE TO golden_warehouse;
GRANT CREATE PROCEDURE TO golden_warehouse;
GRANT CREATE TRIGGER TO golden_warehouse;
GRANT CREATE SYNONYM TO golden_warehouse;
GRANT CREATE MATERIALIZED VIEW TO golden_warehouse;

/* ==============================================================================
   BAGIAN 2: DIEKSEKUSI SEBAGAI USER 'GOLDEN_WAREHOUSE'
   (Jalankan perintah: CONNECT golden_warehouse/GoldenW4rehouse2026!)
   ============================================================================== */

-- 3. Membuat Sequence
CREATE SEQUENCE seq_customer_id START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_product_id START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_sales_id START WITH 1000 INCREMENT BY 1 NOCACHE;

-- 4 & 5. Membuat Tabel, Constraint (Primary Key) 
CREATE TABLE dim_customer (
    customer_id   NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    region        VARCHAR2(50),
    join_date     DATE DEFAULT SYSDATE
);

CREATE TABLE dim_product (
    product_id    NUMBER PRIMARY KEY,
    product_name  VARCHAR2(100) NOT NULL,
    category      VARCHAR2(50),
    price         NUMBER(10,2) NOT NULL
);

-- Membuat Tabel Fakta dengan PARTITION (Range Partitioning berdasarkan tanggal)
CREATE TABLE fact_sales (
    sale_id       NUMBER,
    sale_date     DATE NOT NULL,
    customer_id   NUMBER NOT NULL,
    product_id    NUMBER NOT NULL,
    qty           NUMBER(5) NOT NULL,
    total_amount  NUMBER(15,2),
    -- Constraints
    CONSTRAINT pk_fact_sales PRIMARY KEY (sale_id),
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
)
PARTITION BY RANGE (sale_date) (
    PARTITION p_2025_q4 VALUES LESS THAN (TO_DATE('01-JAN-2026', 'DD-MON-YYYY')),
    PARTITION p_2026_q1 VALUES LESS THAN (TO_DATE('01-APR-2026', 'DD-MON-YYYY')),
    PARTITION p_2026_q2 VALUES LESS THAN (TO_DATE('01-JUL-2026', 'DD-MON-YYYY')),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);

-- 6. Membuat Index
-- Local Partitioned Index sangat disarankan untuk tabel berpartisi di Data Warehouse
CREATE INDEX idx_sales_date ON fact_sales(sale_date) LOCAL;
CREATE INDEX idx_customer_region ON dim_customer(region);

-- 7. Membuat Trigger 
-- Trigger untuk auto-generate sale_id menggunakan sequence dan kalkulasi total_amount
CREATE OR REPLACE TRIGGER trg_fact_sales_bi
BEFORE INSERT ON fact_sales
FOR EACH ROW
DECLARE
    v_price NUMBER(10,2);
BEGIN
    -- Auto generate ID
    IF :NEW.sale_id IS NULL THEN
        :NEW.sale_id := seq_sales_id.NEXTVAL;
    END IF;
    
    -- Kalkulasi otomatis total_amount jika masih kosong
    IF :NEW.total_amount IS NULL THEN
        SELECT price INTO v_price FROM dim_product WHERE product_id = :NEW.product_id;
        :NEW.total_amount := :NEW.qty * v_price;
    END IF;
END;
/

-- 8. INSERT Data (Sample Data ~10 baris per tabel)
-- Insert Dimensi Customer
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'PT Maju Jaya', 'Jakarta', TO_DATE('15-JAN-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'CV Abadi Makmur', 'Surabaya', TO_DATE('20-FEB-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Toko Sentosa', 'Bandung', TO_DATE('10-MAR-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Budi Santoso', 'Semarang', TO_DATE('05-APR-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Siti Aminah', 'Medan', TO_DATE('12-MAY-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'UD Barokah', 'Jakarta', TO_DATE('25-JUN-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Agus Supriyanto', 'Bali', TO_DATE('08-JUL-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Megah Elektronik', 'Surabaya', TO_DATE('19-AUG-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Inti Sari', 'Bandung', TO_DATE('30-SEP-2025', 'DD-MON-YYYY'));
INSERT INTO dim_customer (customer_id, customer_name, region, join_date) VALUES (seq_customer_id.NEXTVAL, 'Global Mandiri', 'Makassar', TO_DATE('11-OCT-2025', 'DD-MON-YYYY'));

-- Insert Dimensi Product
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'Laptop Pro 15', 'Electronics', 15000000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'Wireless Mouse', 'Accessories', 250000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'Mechanical Keyboard', 'Accessories', 800000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'Monitor 27 inch', 'Electronics', 3500000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'USB-C Hub', 'Accessories', 450000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'Server Rack 42U', 'Hardware', 8500000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'Networking Switch 24P', 'Hardware', 4200000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'UPS 1000VA', 'Electronics', 1200000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'External HDD 2TB', 'Storage', 1100000);
INSERT INTO dim_product (product_id, product_name, category, price) VALUES (seq_product_id.NEXTVAL, 'SSD NVMe 1TB', 'Storage', 1800000);

-- Insert Fakta Sales (Bervariasi tanggalnya agar masuk ke partisi yang berbeda)
-- Trigger akan menghitung total_amount secara otomatis
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('15-NOV-2025', 'DD-MON-YYYY'), 1, 100, 5); -- Masuk p_2025_q4
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('12-DEC-2025', 'DD-MON-YYYY'), 2, 103, 10); -- Masuk p_2025_q4
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('05-JAN-2026', 'DD-MON-YYYY'), 3, 101, 20); -- Masuk p_2026_q1
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('18-FEB-2026', 'DD-MON-YYYY'), 4, 104, 15); -- Masuk p_2026_q1
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('22-MAR-2026', 'DD-MON-YYYY'), 5, 102, 8);  -- Masuk p_2026_q1
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('10-APR-2026', 'DD-MON-YYYY'), 6, 108, 12); -- Masuk p_2026_q2
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('25-MAY-2026', 'DD-MON-YYYY'), 7, 109, 5);  -- Masuk p_2026_q2
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('02-JUN-2026', 'DD-MON-YYYY'), 8, 105, 2);  -- Masuk p_2026_q2
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('15-JUL-2026', 'DD-MON-YYYY'), 9, 106, 4);  -- Masuk p_max
INSERT INTO fact_sales (sale_date, customer_id, product_id, qty) VALUES (TO_DATE('20-AUG-2026', 'DD-MON-YYYY'), 10, 107, 7); -- Masuk p_max

COMMIT;

-- 9. Membuat View
CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT 
    s.sale_id,
    s.sale_date,
    c.customer_name,
    c.region,
    p.product_name,
    p.category,
    s.qty,
    s.total_amount
FROM fact_sales s
JOIN dim_customer c ON s.customer_id = c.customer_id
JOIN dim_product p ON s.product_id = p.product_id;

-- 10. Membuat Materialized View
-- Digunakan untuk menyimpan agregat penjualan per bulan (cocok untuk dashboard)
CREATE MATERIALIZED VIEW mv_monthly_sales_agg
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT 
    TO_CHAR(sale_date, 'YYYY-MM') as sale_month,
    SUM(total_amount) as total_revenue,
    SUM(qty) as total_items_sold
FROM fact_sales
GROUP BY TO_CHAR(sale_date, 'YYYY-MM');

-- 11. Membuat Synonym
-- Alias agar user tidak perlu mengetik nama tabel yang panjang
CREATE SYNONYM syn_sales FOR fact_sales;

-- 12. Membuat Standalone Function
-- Fungsi untuk mendapatkan nama customer berdasarkan ID
CREATE OR REPLACE FUNCTION fn_get_customer_name(p_cust_id IN NUMBER) 
RETURN VARCHAR2 
IS
    v_name VARCHAR2(100);
BEGIN
    SELECT customer_name INTO v_name FROM dim_customer WHERE customer_id = p_cust_id;
    RETURN v_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Customer Not Found';
END fn_get_customer_name;
/

-- 13. Membuat Standalone Procedure
-- Prosedur untuk me-refresh Materialized View secara manual
CREATE OR REPLACE PROCEDURE sp_refresh_sales_mv IS
BEGIN
    DBMS_MVIEW.REFRESH('mv_monthly_sales_agg', 'C');
    DBMS_OUTPUT.PUT_LINE('Materialized View berhasil di-refresh pada: ' || SYSTIMESTAMP);
END sp_refresh_sales_mv;
/

-- 14. Membuat Package (Spesifikasi & Body)
-- Package digunakan untuk mengelompokkan bisnis logik warehouse
CREATE OR REPLACE PACKAGE pkg_warehouse_ops AS
    PROCEDURE add_new_product(p_name VARCHAR2, p_category VARCHAR2, p_price NUMBER);
    FUNCTION get_total_sales_by_region(p_region VARCHAR2) RETURN NUMBER;
END pkg_warehouse_ops;
/

CREATE OR REPLACE PACKAGE BODY pkg_warehouse_ops AS
    -- Procedure Body
    PROCEDURE add_new_product(p_name VARCHAR2, p_category VARCHAR2, p_price NUMBER) IS
    BEGIN
        INSERT INTO dim_product (product_id, product_name, category, price)
        VALUES (seq_product_id.NEXTVAL, p_name, p_category, p_price);
        COMMIT;
    END add_new_product;

    -- Function Body
    FUNCTION get_total_sales_by_region(p_region VARCHAR2) RETURN NUMBER IS
        v_total NUMBER(15,2);
    BEGIN
        SELECT NVL(SUM(s.total_amount), 0)
        INTO v_total
        FROM fact_sales s
        JOIN dim_customer c ON s.customer_id = c.customer_id
        WHERE c.region = p_region;
        
        RETURN v_total;
    END get_total_sales_by_region;
END pkg_warehouse_ops;
/
