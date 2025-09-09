# Oracle Database Dataguard 19c With GRID Infrastructure & ASSM
This markdown is related with setup oracle 19c dataguard with already setup GRID Infra and ASM. This configuration is setup dataguard physical standby

## Pre-Requisite
- **Setup Archive Log**
[setup_archivelog.md](oracle\setup_archivelog.md)

- **Setup Or Check param** `db_unique_name`
[set_param_db_unique_name](oracle\set_param_db_unique_name.md)

- **Set TNS For both instancs (Primary And Secondary)**
This is example `tnsnames.ora` between primary and secondary instance.
```text
# Alias untuk konek ke Primary Database
primary_tns_alias =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = primary_server_ip_or_scan_ip)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = primary_db_service_name) -- Example: orcl
    )
  )

# Alias untuk konek ke Standby Database
standby_tns_alias =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = standby_server_ip_or_scan_ip)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = standby_db_service_name) -- Service name standby bisa sama atau beda
    )
  )
```
Test TNS-PING 
```bash
# From primary
tnsping standby_tns_alias

# From standby
tnsping primary_tns_alias
```

- **Set Listener**
```bash
su - grid
```

```text
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = your_db_name)
      (ORACLE_HOME = /u01/app/oracle/product/19.0.0/dbhome_1)
      (SID_NAME = your_sid) -- SID from primary / standby instances
    )
  )
```
Reload Listener
```bash
su - grid
lsnrctl reload
```

## Primary Instance Configuration

```bash
su - oracle
```

- **Set Identify db_unique_name into data guard configuration**
```sql
sqlplus / as sysdba
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(nt19c2_pri,nt19c2_std)' SCOPE=BOTH;
```

- **Set Archive Log for primary instance, basically if using ASM is must be using ASM** 
```sql
-- Example:
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST' SCOPE=BOTH;
```
If you need check this parameter `USE_DB_RECOVERY_FILE_DEST` is correct path you can running this command

```sql
show parameter DB_RECOVERY;
```

- **Set destination redo log (add standby instances destination)**
This part is important cause we will add standbby instances on primary instances 
```sql
-- Change 'standby_tns_alias' with alias TNS for standby database 
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=standby_tns_alias ASYNC VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=standby_db_unique_name';
```
  - `ASYNC`: Mode Asynchronous, common usecase. for maximum data protection without impact to performa, `SYNC` still can use it.
  - `DB_UNIQUE_NAME`: Must be align with `DB_UNIQUE_NAME` on standby instance.

- **Enable destination send log** `LOG_ARCHIVE_DEST_2`

```sql
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
```

- **Set Remote Login From Primary**
This is important cause standby instances will be using same credential access remotely to primary instances.
The Value is between `EXCLUSIVE` or `SHARED`
```sql
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE SCOPE=SPFILE;
```

- **Restart Primary instance database**
```sql
SHUTDOWN IMMEDIATE;
STARTUP;
```

- **Copy the password file from primary to standby instances**
The default location if on file system is will be `$ORACLE_HOME/dbs`.
And the file must be copy `initxxx.ora`,`orapwxxx`.
If the path is under `+ASM` make sure you copy to standby instance is on `+ASM` standby instances

- **Set Parameter** `FAL_SERVER` **on primary instance,for fetch archive log, for help standby instances.**
```sql
ALTER SYSTEM SET FAL_SERVER=standby_tns_alias;
```

- **Set parameter** `STANDBY_FILE_MANAGEMENT`
Set to AUTO, for if any more datafile in primary will be set automate to replicate to standby (is recommend for ASM).
```sql
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;
```

## Standby Instance Configuration
- **Create PFILE For Standby**
In this case I will create `initnt19c2STANDBY.ora` copy from pfile primary instance.
```bash
cp initnt19c2.ora initnt19c2STANDBY.ora
```
put the parameter adjust with standby instances. for example `db_unique_name,audit_file etc`

- Stop Standby Instance if running.
```sql
shutdown immediate;
```
- Start Standby Instance mount stage.
```sql
CONNECT / AS SYSDBA
STARTUP NOMOUNT PFILE='/path/to/initSTANDBY.ora';
```

- **Running RMAN For Duplicate DataFile**
    - Login Into RMAN
    ```bash
    rman TARGET sys/password@NT19C2_PRIMARY AUXILIARY sys/password@NT19C2_STANDBY
    ```

    - Running this RMAN Duplicate Command
    ```bash
    DUPLICATE TARGET DATABASE
    FOR STANDBY
    FROM ACTIVE DATABASE
    DORECOVER
    SPFILE
      SET DB_UNIQUE_NAME='nt19c2_std'
      SET DB_FILE_NAME_CONVERT='+DATA/NT19C2/','+DATA/NT19C2_STD/' -- Add this line.
    ;
    ```
    This is example if `RMAN DUPLICATE` Success
    ```
    starting media recovery
    archived log for thread 1 with sequence 23 is already on disk as file +FRA/NT19C2_STD/ARCHIVELOG/2025_09_04/thread_1_seq_23.261.1210947183
    archived log for thread 1 with sequence 24 is already on disk as file +FRA/NT19C2_STD/ARCHIVELOG/2025_09_04/thread_1_seq_24.262.1210947185
    archived log file name=+FRA/NT19C2_STD/ARCHIVELOG/2025_09_04/thread_1_seq_23.261.1210947183 thread=1 sequence=23
    archived log file name=+FRA/NT19C2_STD/ARCHIVELOG/2025_09_04/thread_1_seq_24.262.1210947185 thread=1 sequence=24
    media recovery complete, elapsed time: 00:00:00

    Finished recover at 04-SEP-2025 14:13:12
    contents of Memory Script:
    {
       delete clone force archivelog all;
    }

    executing Memory Script


    released channel: ORA_DISK_1
    released channel: ORA_AUX_DISK_1
    allocated channel: ORA_DISK_1
    channel ORA_DISK_1: SID=40 device type=DISK
    deleted archived log
    archived log file name=+FRA/NT19C2_STD/ARCHIVELOG/2025_09_04/thread_1_seq_23.261.1210947183 RECID=1 STAMP=1210947183
    deleted archived log
    archived log file name=+FRA/NT19C2_STD/ARCHIVELOG/2025_09_04/thread_1_seq_24.262.1210947185 RECID=2 STAMP=1210947185
    Deleted 2 objects

    Finished Duplicate Db at 04-SEP-2025 14:13:19
    ```

    - If the `RMAN DUPLICATE` is success wecan start syncronize 
    ```sql
    ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;
    ```

    - Verified The Synchonrize From Primary Instances
    ```sql
    -- Execute From PRIMARY
    SELECT ARCHIVED_THREAD#, ARCHIVED_SEQ#, APPLIED_THREAD#, APPLIED_SEQ# 
    FROM V$ARCHIVE_DEST_STATUS 
    WHERE DEST_ID=2; -- DEST_ID 2 adalah tujuan standby Anda
    ```
    Focus on column `ARCHIVED` and `APPLIED` sequence will be same or have small gap.

## Enable Data Guard Broker 
Data Guard Broker (DGMGRL) is tools recommended from oracle for manage dataguard.

- Enable Broker between Primary & Standby Instance
```bash
su - oracle
```
```sql
ALTER SYSTEM SET DG_BROKER_START=TRUE;
```

- Create Configuration Data 
```bash
DGMGRL> CREATE CONFIGURATION 'DG_NT19C2_CONFIG' AS
> PRIMARY DATABASE IS 'nt19c2_pri'
> CONNECT IDENTIFIER IS NT19C2_PRIMARY;
```

- Add Standby Database
```bash
DGMGRL> ADD DATABASE 'nt19c2_std' AS
> CONNECT IDENTIFIER IS NT19C2_STANDBY
> MAINTAINED AS PHYSICAL;
```

- Enable Configuration
```bash
DGMGRL> ENABLE CONFIGURATION;
```

- Verified Configuration
```bash
DGMGRL> SHOW CONFIGURATION;
```


## Error Section 
### Error during `RMAN DUPLICATE` cause on standby instance doesn't have folder `NT19C2` on ASM. Cause during installation Standby Instance I put explicit the db param on dbca silent command
```
ORA-17502: ksfdcre:4 Failed to create file +DATA/NT19C2/PARAMETERFILE/spfile_nt19c2.ora
ORA-15173: entry 'NT19C2' does not exist in directory '/'
```
- Solution
Create directory `NT19C2` on ASM Disk Group Standb Instances.


### From dgmgrl | Warning: ORA-16809: multiple warnings detected for the member on standby instances
- Cause 
`ORA-16789: standby redo logs configured incorrectly`:  This one is core error message,The broker show to us the primary database can't find the standby redo log in standby instances. 
`ORA-16809: multiple warnings detected`: this recap error message on standby instance cause have more problem, but the core is about SRL.

- Solution
Create Standby Redo Log (RSL), between primary and standby instances.
  - Check Current Redo Log
  ```sql
  SELECT group#, bytes/1024/1024 as MB, members FROM v$log;
  ```
  By default the result will be show 3 group ORL each size is must be 200MB

  - Stop The Recovery mode on standby instance
  ```sql
  ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
  ```
  - Add Standby Redo Log In Standby Instance
  ```sql
  ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 
  GROUP 4 ('+FRA') SIZE 200M,
  GROUP 5 ('+FRA') SIZE 200M,
  GROUP 6 ('+FRA') SIZE 200M,
  GROUP 7 ('+FRA') SIZE 200M;
  ```

  - Add Standby Redo Log In Primary Instances
  ```sql
  ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 
  GROUP 4 ('+FRA') SIZE 200M,
  GROUP 5 ('+FRA') SIZE 200M,
  GROUP 6 ('+FRA') SIZE 200M,
  GROUP 7 ('+FRA') SIZE 200M;
  ```

  - Start The recovery mode on standby instance
  ```sql
  ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;
  ```
  
  - Check the status from dgmgrl
  ```bash
  show configuration;
  # Expected Results
      DGMGRL> show configuration;
    Configuration - DG_NT19C2_CONFIG
      Protection Mode: MaxPerformance
      Members:
      nt19c2_pri - Primary database
        nt19c2_std - Physical standby database 
    Fast-Start Failover:  Disabled
    Configuration Status:
    SUCCESS   (status updated 17 seconds ago)

    DGMGRL> 
  ```
  