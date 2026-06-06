-- ==============================================================================
-- NAMA SCRIPT  : setup_retail_schema.sql
-- DESKRIPSI    : Full dummy schema generation untuk Oracle 19c Non-CDB (ASM)
-- EKSEKUSI     : Jalankan via SQL*Plus sebagai SYSDBA (sqlplus / as sysdba)
-- ==============================================================================

SET SERVEROUTPUT ON;
SET ECHO ON;

-- ------------------------------------------------------------------------------
-- BAGIAN 1: INFRASTRUKTUR & USER (Membutuhkan akses SYSDBA)
-- ------------------------------------------------------------------------------

PROMPT Memulai pembuatan Tablespace di ASM Disk Group +DATA...
CREATE TABLESPACE ts_retail_data 
DATAFILE '+DATA' SIZE 200M AUTOEXTEND ON NEXT 50M MAXSIZE 2G
LOGGING
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
SEGMENT SPACE MANAGEMENT AUTO;

PROMPT Membuat User Schema svc_retail...
CREATE USER svc_retail IDENTIFIED BY "RetailAdmin2026!"
DEFAULT TABLESPACE ts_retail_data
QUOTA UNLIMITED ON ts_retail_data;

PROMPT Memberikan Grants kepada svc_retail...
GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE MATERIALIZED VIEW, 
      CREATE SYNONYM, CREATE PROCEDURE, CREATE TRIGGER TO svc_retail;

-- Pindah ke schema yang baru dibuat untuk pembuatan objek
ALTER SESSION SET CURRENT_SCHEMA = svc_retail;


-- ------------------------------------------------------------------------------
-- BAGIAN 2: DDL - PEMBUATAN TABEL DAN PARTISI
-- ------------------------------------------------------------------------------
PROMPT Membangun struktur tabel...

-- 1. REGIONS
CREATE TABLE regions (
    region_id NUMBER PRIMARY KEY,
    region_name VARCHAR2(50) NOT NULL
);

-- 2. LOCATIONS
CREATE TABLE locations (
    location_id NUMBER PRIMARY KEY,
    region_id NUMBER,
    city VARCHAR2(50) NOT NULL,
    address VARCHAR2(100),
    CONSTRAINT fk_loc_region FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- 3. DEPARTMENTS
CREATE TABLE departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(50) NOT NULL,
    location_id NUMBER,
    CONSTRAINT fk_dept_loc FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

-- 4. EMPLOYEES
CREATE TABLE employees (
    emp_id NUMBER PRIMARY KEY,
    emp_name VARCHAR2(100) NOT NULL,
    department_id NUMBER,
    hire_date DATE DEFAULT SYSDATE,
    salary NUMBER(10,2),
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 5. CUSTOMERS
CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100) NOT NULL,
    join_date DATE DEFAULT SYSDATE
);

-- 6. PRODUCTS 
CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(100) NOT NULL,
    price NUMBER(10,2) NOT NULL,
    category VARCHAR2(50)
);

-- 7. PROMOTIONS
CREATE TABLE promotions (
    promo_id NUMBER PRIMARY KEY,
    promo_code VARCHAR2(20) UNIQUE,
    discount_pct NUMBER(3,2)
);

-- 8. ORDERS (Tabel Berpartisi berdasarkan Bulan)
CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    emp_id NUMBER,
    order_date DATE NOT NULL,
    status VARCHAR2(20) DEFAULT 'PENDING',
    CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_ord_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
)
PARTITION BY RANGE (order_date) (
    PARTITION p_2025_h2 VALUES LESS THAN (TO_DATE('01-JAN-2026', 'DD-MON-YYYY')),
    PARTITION p_2026_h1 VALUES LESS THAN (TO_DATE('01-JUL-2026', 'DD-MON-YYYY')),
    PARTITION p_2026_h2 VALUES LESS THAN (TO_DATE('01-JAN-2027', 'DD-MON-YYYY')),
    PARTITION p_max VALUES LESS THAN (MAXVALUE)
);

-- 9. ORDER_ITEMS
CREATE TABLE order_items (
    item_id NUMBER PRIMARY KEY,
    order_id NUMBER,
    product_id NUMBER,
    quantity NUMBER(4) DEFAULT 1,
    unit_price NUMBER(10,2),
    CONSTRAINT fk_oi_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_oi_prod FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 10. PAYMENTS 
CREATE TABLE payments (
    payment_id NUMBER PRIMARY KEY,
    order_id NUMBER,
    payment_method VARCHAR2(50) NOT NULL,
    amount NUMBER(10,2) NOT NULL,
    payment_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- ------------------------------------------------------------------------------
-- BAGIAN 3: DML - GENERATOR DATA OTOMATIS (50-100 Baris per Tabel)
-- ------------------------------------------------------------------------------
PROMPT Memulai injeksi dummy data...

DECLARE
    v_methods SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('QRIS', 'Bank Jago', 'Bank Mandiri', 'Kartu Kredit', 'Flip', 'Cash');
    v_categories SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('Elektronik', 'Pakaian', 'Kebutuhan Harian', 'Aksesoris');
BEGIN
    -- 1. Regions (50 data)
    FOR i IN 1..50 LOOP
        INSERT INTO regions VALUES (i, 'Region Kode ' || i);
    END LOOP;
    
    -- 2. Locations (100 data)
    FOR i IN 1..100 LOOP
        -- region_id diacak antara 1 sampai 50
        INSERT INTO locations VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 51)), 'Kota ' || i, 'Jalan Bisnis No. ' || i);
    END LOOP;
    
    -- 3. Departments (50 data)
    FOR i IN 1..50 LOOP
        -- location_id diacak antara 1 sampai 100
        INSERT INTO departments VALUES (i, 'Departemen ' || i, TRUNC(DBMS_RANDOM.VALUE(1, 101)));
    END LOOP;
    
    -- 4. Employees (100 data)
    FOR i IN 1..100 LOOP
        -- departemen_id diacak 1 sampai 50
        INSERT INTO employees VALUES (i, 'Pegawai ' || i, TRUNC(DBMS_RANDOM.VALUE(1, 51)), SYSDATE - DBMS_RANDOM.VALUE(1, 1000), ROUND(DBMS_RANDOM.VALUE(5000000, 20000000)));
    END LOOP;
    
    -- 5. Customers (100 data)
    FOR i IN 1..100 LOOP
        INSERT INTO customers VALUES (i, 'Pelanggan ' || i, SYSDATE - DBMS_RANDOM.VALUE(1, 700));
    END LOOP;
    
    -- 6. Products (100 data)
    FOR i IN 1..100 LOOP
        INSERT INTO products VALUES (i, 'Produk SKU-' || i, ROUND(DBMS_RANDOM.VALUE(10000, 1500000),-3), v_categories(TRUNC(DBMS_RANDOM.VALUE(1, 5))));
    END LOOP;
    
    -- 7. Promotions (50 data)
    FOR i IN 1..50 LOOP
        INSERT INTO promotions VALUES (i, 'PROMO2026_' || i, ROUND(DBMS_RANDOM.VALUE(0.05, 0.40), 2));
    END LOOP;
    
    -- 8. Orders (100 data tersebar di tahun 2025-2026 untuk menguji partisi)
    FOR i IN 1..100 LOOP
        -- customer_id dan emp_id 1-100
        INSERT INTO orders VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 101)), TRUNC(DBMS_RANDOM.VALUE(1, 101)), SYSDATE - DBMS_RANDOM.VALUE(1, 500), 'COMPLETED');
    END LOOP;
    
    -- 9. Order Items (100 data)
    FOR i IN 1..100 LOOP
        -- order_id dan product_id 1-100
        INSERT INTO order_items VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 101)), TRUNC(DBMS_RANDOM.VALUE(1, 101)), TRUNC(DBMS_RANDOM.VALUE(1, 5)), 
            (SELECT price FROM products WHERE product_id = i)); -- Ambil harga produk sesuai i agar valid
    END LOOP;
    
    -- 10. Payments (100 data)
    FOR i IN 1..100 LOOP
        INSERT INTO payments VALUES (i, TRUNC(DBMS_RANDOM.VALUE(1, 101)), v_methods(TRUNC(DBMS_RANDOM.VALUE(1, 7))), 
            ROUND(DBMS_RANDOM.VALUE(50000, 2000000)), SYSDATE - DBMS_RANDOM.VALUE(1, 500));
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('SUKSES: Dummy data berhasil di-generate dan Foreign Key terintegrasi.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        ROLLBACK;
END;
/


-- ------------------------------------------------------------------------------
-- BAGIAN 4: OBJEK LANJUTAN (VIEW, SYNONYM, MATERIALIZED VIEW)
-- ------------------------------------------------------------------------------
PROMPT Membuat View, MV, dan Synonym...

-- View
CREATE OR REPLACE VIEW v_successful_transactions AS
SELECT o.order_id, c.customer_name, e.emp_name, p.payment_method, p.amount, o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN employees e ON o.emp_id = e.emp_id
JOIN payments p ON o.order_id = p.order_id
WHERE o.status = 'COMPLETED';

-- Materialized View
CREATE MATERIALIZED VIEW mv_daily_sales
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
AS
SELECT TRUNC(order_date) AS sales_date, SUM(amount) AS total_revenue, COUNT(payment_id) AS total_trx
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY TRUNC(order_date);

-- Synonym
CREATE SYNONYM catalog_items FOR products;


-- ------------------------------------------------------------------------------
-- BAGIAN 5: PACKAGE, FUNCTION, PROCEDURE, DAN TRIGGER
-- ------------------------------------------------------------------------------
PROMPT Membuat Programmatic Objects (PL/SQL)...

-- Trigger
CREATE OR REPLACE TRIGGER trg_update_order_status
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    UPDATE orders
    SET status = 'PAID'
    WHERE order_id = :NEW.order_id;
END;
/

-- Package Specification
CREATE OR REPLACE PACKAGE pkg_retail_ops AS
    FUNCTION get_total_order_value(p_order_id NUMBER) RETURN NUMBER;
    PROCEDURE add_new_product(p_name VARCHAR2, p_price NUMBER, p_category VARCHAR2);
END pkg_retail_ops;
/

-- Package Body
CREATE OR REPLACE PACKAGE BODY pkg_retail_ops AS

    -- Function: Mengambil total harga dari order tertentu
    FUNCTION get_total_order_value(p_order_id NUMBER) RETURN NUMBER IS
        v_total NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(quantity * unit_price), 0)
        INTO v_total
        FROM order_items
        WHERE order_id = p_order_id;
        
        RETURN v_total;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END get_total_order_value;

    -- Procedure: Memasukkan data produk baru
    PROCEDURE add_new_product(p_name VARCHAR2, p_price NUMBER, p_category VARCHAR2) IS
        v_new_id NUMBER;
    BEGIN
        SELECT NVL(MAX(product_id), 0) + 1 INTO v_new_id FROM products;
        
        INSERT INTO products (product_id, product_name, price, category)
        VALUES (v_new_id, p_name, p_price, p_category);
        
        COMMIT;
    END add_new_product;

END pkg_retail_ops;
/

PROMPT =========================================================
PROMPT SETUP SELESAI. SILAKAN CEK OBJEK DI SCHEMA SVC_RETAIL.
PROMPT =========================================================
