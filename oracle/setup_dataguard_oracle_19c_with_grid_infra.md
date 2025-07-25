# Oracle Database Dataguard 19c With GRID Infrastructure & ASSM
This markdown is related with setup oracle 19c dataguard with already setup GRID Infra and ASM. This configuration is setup dataguard physical standby

## Primary Instance Configuration

### Change Parameter On 
```bash
su - oracle
```
```sql
sqlplus / as sysdba

-- 1. Mengidentifikasi semua database unik dalam konfigurasi Data Guard
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(FEBRIDEVDEMO_PRIMARY,FEBRIDEVDEMO_STANDBY)' SCOPE=BOTH;

-- 2. Mengatur tujuan archive log lokal primary (ke FRA)
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=FEBRIDEVDEMO_PRIMARY' SCOPE=BOTH;

-- 3. Mengatur tujuan pengiriman archive log ke Standby
-- 'SERVICE=FEBRIDEVDEMO_STANDBY' merujuk ke TNS alias yang kita buat.
-- 'DB_UNIQUE_NAME=FEBRIDEVDEMO_STANDBY' mengidentifikasi tujuan spesifik.
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=FEBRIDEVDEMO_STANDBY ASYNC NOAFFIRM VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=FEBRIDEVDEMO_STANDBY' SCOPE=BOTH;

-- 4. Mengaktifkan tujuan archive log ini
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE SCOPE=BOTH;

-- 5. Memastikan password file digunakan untuk otentikasi remote
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE SCOPE=SPFILE;

-- 6. Mengatur server yang akan menyediakan archive log yang hilang ke primary (saat primary berperan sebagai standby)
ALTER SYSTEM SET FAL_SERVER=FEBRIDEVDEMO_STANDBY SCOPE=BOTH;

-- 7. Mengatur client yang akan meminta archive log yang hilang dari primary (saat primary berperan sebagai primary)
ALTER SYSTEM SET FAL_CLIENT=FEBRIDEVDEMO_PRIMARY SCOPE=BOTH;

-- 8. Mengaktifkan manajemen file standby secara otomatis oleh database
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO SCOPE=SPFILE;

-- 9. Mengaktifkan Data Guard Broker (akan digunakan nanti untuk manajemen mudah)
ALTER SYSTEM SET DG_BROKER_START=TRUE SCOPE=BOTH;

-- 10. Mengatur konversi nama file untuk RMAN DUPLICATE dan manajemen file standby
-- Ini sangat penting jika Primary dan Standby memiliki jalur ASM yang berbeda
-- (misalnya, perbedaan di DB_UNIQUE_NAME di jalur ASM).
-- Contoh: +DATA/FEBRIDEVDEMO_PRIMARY/datafile menjadi +DATA/FEBRIDEVDEMO_STANDBY/datafile
ALTER SYSTEM SET DB_FILE_NAME_CONVERT='FEBRIDEVDEMO_PRIMARY','FEBRIDEVDEMO_STANDBY' SCOPE=SPFILE;
ALTER SYSTEM SET LOG_FILE_NAME_CONVERT='FEBRIDEVDEMO_PRIMARY','FEBRIDEVDEMO_STANDBY' SCOPE=SPFILE;

-- Opsional tapi direkomendasikan: Pastikan Flashback Database aktif dan recovery area cukup
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST='+FRA' SCOPE=BOTH;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE=20G SCOPE=BOTH;
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE FLASHBACK ON;
ALTER DATABASE OPEN;
exit;
```



[oracle@vmoradb1 rdbms]$ echo $ORACLE_SID
febridevdemo
[oracle@vmoradb1 rdbms]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Thu Jul 10 02:50:12 2025
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.


Connected to:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> SHOW PARAMETER db_unique_name;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_unique_name                       string      febridevdemo
SQL> SHOW PARAMETER instance_name;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
instance_name                        string      febridevdemo
SQL> SELECT name, db_unique_name FROM v$database;

NAME      DB_UNIQUE_NAME
--------- ------------------------------
FEBRIDEV  febridevdemo

SQL>

srvctl add database -d FEBRIDEVDEMO_PRIMARY -o /u01/19c/oracle_base/oracle/db_home -p '/tmp/init_new_primary.ora' -n FEBRIDEV -a 'DATA,FRA' -role PRIMARY -s MOUNT -pwfile '/u01/19c/oracle_base/oracle/db_home/dbsorapwFEBRIDEVDEMO'


srvctl config database -d FEBRIDEVDEMO_PRIMARY
Database unique name: FEBRIDEVDEMO_PRIMARY
Database name: FEBRIDEVDEMO
Oracle home: /u01/19c/oracle_base/oracle/db_home
Oracle user: oracle
Spfile: /tmp/init_new_primary.ora
Password file: /u01/19c/oracle_base/oracle/db_home/dbsorapwFEBRIDEVDEMO
Domain:
Start options: mount
Stop options: immediate
Database role: PRIMARY
Management policy: AUTOMATIC
Disk Groups: DATA,FRA
Services:
OSDBA group:
OSOPER group:
Database instance: FEBRIDEVDEMO


srvctl config database -d FEBRIDEVDEMO_PRIMARY
Database unique name: FEBRIDEVDEMO_PRIMARY
Database name: FEBRIDEV
Oracle home: /u01/19c/oracle_base/oracle/db_home
Oracle user: oracle
Spfile: /tmp/init_new_primary.ora
Password file: /u01/19c/oracle_base/oracle/db_home/dbsorapwFEBRIDEVDEMO
Domain:
Start options: mount
Stop options: immediate
Database role: PRIMARY
Management policy: AUTOMATIC
Disk Groups: DATA,FRA
Services:
OSDBA group:
OSOPER group:
Database instance: FEBRIDEVDEMO

CREATE SPFILE FROM PFILE='/tmp/new_initparam.ora';

CREATE PFILE='/tmp/new_initparam.ora' FROM SPFILE;

Database unique name: febridevdemo
Database name: febridev
Oracle home: /u01/19c/oracle_base/oracle/db_home
Oracle user: oracle
Spfile: +DATA/FEBRIDEVDEMO/PARAMETERFILE/spfile.269.1205900889
Password file:
Domain:
Start options: open
Stop options: immediate
Database role: PRIMARY
Management policy: AUTOMATIC
Disk Groups: DATA,FRA
Services:
OSDBA group:
OSOPER group:
Database instance: febridevdemo


srvctl add database -d febridev_standby -o /u01/app/oracle/product/19.0.0/dbhome_1 -p +DATA/FEBRIDEV_STANDBY/SPFILE/spfile.300.9876543210 -n febridev -a DATA

srvctl add database \
    -db febridev_standby \
    -oraclehome /u01/19c/oracle_base/oracle/db_home \
    -spfile +DATA/FEBRIDEVDEMO/PARAMETERFILE/spfile.270.1206072589 \
    -pwfile /u01/19c/oracle_base/oracle/db_home/dbs/orapwfebridevdemo \
    -dbname febridev \
    -diskgroup DATA

srvctl add database \
    -d febridev_standby \
    -o /u01/19c/oracle_base/oracle/db_home \
    -p +DATA/FEBRIDEVDEMO/PARAMETERFILE/spfile.270.1206072589 \
    -n febridev \
    -a DATA \
    -r oracle

srvctl add database \
-d febridev_standby \
-o /u01/19c/oracle_base/oracle/db_home \
-p +DATA/FEBRIDEVDEMO/PARAMETERFILE/spfile.270.1206072589 \
-n febridev \
-a DATA \
-r oracle \
-pwfile /u01/19c/oracle_base/oracle/db_home/dbs/orapwfebridevdemo