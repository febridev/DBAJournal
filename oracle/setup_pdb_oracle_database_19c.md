# Setup PDB on Oracle Database 19c

This is guide or runbook for setup PDB on oracle database 19c.

## Create Pluggable Database

- Login as `oracle` user

```bash
su - oracle
```

- Connect to oracle services

```bash
sqlplus / as sysdba
```

- Make sure oracle services is UP

```sql
SELECT instance_name, status FROM v$instance;

-- Expected Results
INSTANCE_NAME    STATUS
---------------- ------------
orademo          OPEN

-- Execute startup if you nned start the services
startup
```

- Create pluggable database and user

```sql
-- Recommendation for ASM / DMF
CREATE PLUGGABLE DATABASE OT_PDB
  ADMIN USER ot_admin IDENTIFIED BY "StrengthPassword";

-- IF NOT USING ASM
CREATE PLUGGABLE DATABASE OT_PDB
  ADMIN USER ot_admin IDENTIFIED BY "StrengthPassword"
  FILE_NAME_CONVERT = ('/oradata/ORADEMO/pdbseed/', '/oradata/ORADEMO/sales_pdb/');
```

- Check Results

```sql
SHOW PDBs;
-- Your's PDB will be show with status MOUNTED
--     PDB_ID PDB_NAME                       STATUS
-- ---------- ------------------------------ --------
--          2 PDB$SEED                       READ ONLY
--          3 SALES_PDB                      MOUNTED
```

- Set TNS For Connect to PDB

```bash
su - oracle

cd $ORACLE_HOME

cd network/admin

cp samples/tnsnames.ora .

# EDIT sample tnsnames.ora
vi tnsnames.ora

## ADJUST VALUE
<YOUR_TNS_NAME> =
 (DESCRIPTION =
  (ADDRESS = (PROTOCOL = TCP)(HOST = <YOUR_HOSTNAME>)(PORT = 1521))
  (CONNECT_DATA =
   (SERVER = DEDICATED)
   (SERVICE_NAME = <YOUR_SERVICE_NAME>)
  )
)
```

All value you can changes from `lsnrctl status`

- Test Connection TO PDB Database using Admin User PDB
  For example in this case admin user is `PDBADMIN`

```bash
sqlplus PDBADMIN/"Your_Password"@TNSNAME
```

IF Successfull you can see like this

```bash
SQL*Plus: Release 19.0.0.0.0 - Production on Sat Jun 21 14:11:47 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Last Successful login time: Sat Jun 21 2025 13:53:17 +00:00

Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL>
```

## ALL COMMAND RELATED PLUGGABLE DATABASE

```sql
-- 1. Terhubung ke CDB sebagai SYSDBA
sqlplus / as sysdba

-- 2. Cek status CDB dan PDB yang ada
SELECT NAME, OPEN_MODE FROM V$DATABASE;
SHOW PDBs;

-- 3. Buat PDB baru
CREATE PLUGGABLE DATABASE SALES_PDB
  ADMIN USER sales_admin IDENTIFIED BY "PasswordAndaYangKuat123"
  -- Hapus baris FILE_NAME_CONVERT jika DB_CREATE_FILE_DEST sudah diatur ke diskgroup ASM
  -- FILE_NAME_CONVERT = ('/oradata/ORADEMO/pdbseed/', '/oradata/ORADEMO/sales_pdb/'); -- Sesuaikan path ASM jika diperlukan
;

-- 4. Verifikasi status PDB (seharusnya MOUNTED)
SHOW PDBs;

-- 5. Buka PDB
ALTER PLUGGABLE DATABASE SALES_PDB OPEN;

-- 6. Verifikasi status PDB (seharusnya READ WRITE)
SHOW PDBs;

-- 7. (Opsional, tapi direkomendasikan) Konfigurasi PDB agar terbuka otomatis saat CDB startup
ALTER PLUGGABLE DATABASE SALES_PDB SAVE STATE;

-- 8. Keluar dari SQL*Plus
EXIT;

-- 9. (Untuk testing) Terhubung langsung ke PDB
sqlplus sales_admin/"PasswordAndaYangKuat123"@SALES_PDB

-- 10. Verifikasi Anda berada di PDB
SHOW CON_NAME;

-- 11. Buat objek (contoh)
CREATE TABLE employees (id NUMBER PRIMARY KEY, name VARCHAR2(100));
INSERT INTO employees VALUES (1, 'John Doe');
COMMIT;
SELECT * FROM employees;

-- 12. Keluar dari sesi PDB
EXIT;
```
