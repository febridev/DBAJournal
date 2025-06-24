# Runbook ArchiveLog On Oracle Database 19c Oracle Linux 8

This Runbook is help setup archive log on oracle database 19c and setup the RMAN BACKUP.

## Setup Archive Log

- Check ArchiveLog Status

```bash
su - oracle
sqlplus / as sysdba
SELECT LOG_MODE FROM V$DATABASE;
```

If Results

```bash
LOG_MODE
------------
NOARCHIVELOG
```

That's mean NO ArchiveLog Enable or Active

- Enable ArchiveLog

  - Shutdown Database

    ```bash
    su - oracle
    sqlplus / as sysdba
    SHUTDOWN IMMEDIATE;
    ```

  - Up Database To `MOUNT`

  ```sql
  STARTUP MOUNT;
  ```

  - ENABLE Archive Log

  ```sql
  ALTER DATABASE ARCHIVELOG;
  ```

  - OPEN Database

  ```sql
  ALTER DATABASE OPEN;
  ```

  - Check ArchiveLog Status

  ```bash
  su - oracle
  sqlplus / as sysdba
  ```

  ```sql
  SELECT LOG_MODE FROM V$DATABASE;
  ```

  Make sure the results is `ARCHIVELOG`

## Setup Archive Log TO ASM DISK

- Check Current Configuration

```bash
su - oracle
sqlplus / as sysdba

```

- Check Current FRA ASM DISK Configuration

```sql
SHOW PARAMETER DB_RECOVERY_FILE_DEST;
SHOW PARAMETER DB_RECOVERY_FILE_DEST_SIZE;
```

In my case is already set on FRA ASM DISK

```sql

SQL> SHOW PARAMETER DB_RECOVERY_FILE_DEST;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_recovery_file_dest                string      +FRA
db_recovery_file_dest_size           big integer 9G
SQL> SHOW PARAMETER DB_RECOVERY_FILE_DEST_SIZE;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_recovery_file_dest_size           big integer 9G
```

- If not set on ASM, Run This Command

```sql
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST='+FRA' SCOPE=BOTH;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE='100G' SCOPE=BOTH; -- Adjust The Size with your disks
```

- Changes Format ArchiveLog (Optional)

```bash
su - oracle
sqlplus / as sysdba
```

Example

```sql
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='ARC%T_%S_%R.ARC' SCOPE=SPFILE;
```

Restart Required

```sql
SHUTDOWN IMMEDIATE;
STARTUP;
```
