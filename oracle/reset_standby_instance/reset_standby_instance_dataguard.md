# Disconnect or Reset Instances Standby Oracle Dataguard
Oracle Version 19c

1. Isolasi Primary: Stop send redo log from primary to standby (to make sure primary doesn't hang or create error when standby instance down)
2. Verify Standby: Make sure you on STANDBY instance 
3. Drop Database (Decommission): use RMAN for drop datafiles,controlfiles
4. Drop database services on ASM level
5. Tidy up config file: remove password file, entry oratab, parameter file and directory admin or audit manually 
6. Clean the network: clean TNS and listener to make sure doesn't have ghost config or entry. 


## PRIMARY INSTANCES

1. Isolasi Primary: Stop send redo log from primary to standby (to make sure primary doesn't hang or create error when standby instance down)
```sql
-- Cek dest id mana yang mengarah ke standby server tersebut
SHOW PARAMETER log_archive_dest;

-- Misal dest_2 adalah yang mengarah ke standby yang mau dihapus
-- Matikan pengiriman log
ALTER SYSTEM SET log_archive_dest_state_2 = DEFER SCOPE=BOTH;

-- Opsional: Kosongkan konfigurasi dest_2 agar bersih total
ALTER SYSTEM SET log_archive_dest_2 = '' SCOPE=BOTH;
```

## STANDBY INSTANCES

2. Verify Standby: Make sure you on STANDBY instance 
```bash
su - oracle
sqlplus / as sysdba
```

```sql
-- CRITICAL CHECK: Pastikan ini benar-benar STANDBY
SELECT NAME, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;

-- Hasil harus: PHYSICAL STANDBY
-- Jika hasil PRIMARY, BERHENTI SEKARANG.
```

3. Drop Database (Decommission): use RMAN for drop datafiles,controlfiles, and spfile full clean 
```bash
su - oracle
sqlplus / as sysdba
```
```sql
SHUTDOWN IMMEDIATE;
STARTUP MOUNT EXCLUSIVE RESTRICT;
EXIT;
```

```bash
rman target /
```
```sql
-- Perintah ini akan menghapus seluruh datafiles, redo logs, 
-- control files, dan spfile yang sedang digunakan.
DROP DATABASE INCLUDING BACKUPS NOPROMPT;
EXIT;
```

4. Drop database services on ASM level
```bash
su - grid
srvctl status database -d <SID_STANDBY>
-- Stop dulu (jika belum mati)
srvctl stop database -d <SID_STANDBY> -o immediate

-- Remove entry dari registry
srvctl remove database -d <SID_STANDBY> -f

```

5. Tidy up config file: remove password file, entry oratab, parameter file and directory admin or audit manually 
```bash
su - grid
asmcmd
ls -l +DATA

-- Jika folder ORCL masih ada, hapus paksa
cd +DATA
rm -rf <STANDBY_SID>

-- Lakukan hal sama untuk diskgroup RECO atau FRA
ls -l +RECO/
rm -rf <STANDBY_SID>

su - oracle
cd $ORACLE_HOME/dbs

# Hapus file init text pointer (yang isinya spfile='+DATA/...')
rm -f init<STANDBY_SID>.ora

# Hapus password file
rm -f orapw<STANDBY_SID>

# Hapus lock file
rm -f lk<STANDBY_SID>
```

6. Clean the network: clean TNS and listener to make sure doesn't have ghost config or entry. 
```bash
su - grid
cd $ORACLE_HOME
cd network/admin
# remove all LISTENTER RELATED SID STANDBY
```
