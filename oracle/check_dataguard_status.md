# Check Dataguard Status (Physical Standby) Oracle 19c With Grid ASM

## Via DGMGRL
```bash
dgmgrl 
DGMGRL > connect sys/<your_password>@<TNSALIAS>
show configuration
```

## Check From Database 
### Primary Intances
**1. Verified Database** 
```bash
su - oracle
sqlplus / as sysdba
```

```sql
set linesize 200
set pagesize 200
SELECT
name AS DB_NAME,
db_unique_name AS DB_UNIQUE_NAME,
database_role AS ROLE,
open_mode AS OPEN_MODE,
log_mode AS LOG_MODE,
protection_mode
FROM
v$database;
```

**2. Check Archive Log Send Standby**
```sql
-- Status Column must be 'VALID'. If 'ERROR' or 'DEFERRED' 
SELECT dest_id,status,destination,error
FROM
v$archive_dest_status
WHERE
destination LIKE '%<db_unique_name_standby>%';
```

**3. Check Log Sequence Latest To Send**
This command show `sequence#` is successfull send to standby.
This is good for compare `sequence#` between standby and primary.
```sql
SELECT
dest_id,
destination,
status,
archived_seq# AS LAST_SEQ_SENT
FROM
v$archive_dest
WHERE
target = 'STANDBY';
```

**4. Check Log Sequence On Primary Instance**
This command will be check latest log sequence still active or latest archive on primary

```sql
SELECT
thread#,
max(sequence#) AS LATEST_ARCHIVE_LOG
FROM
v$archived_log
GROUP BY
thread#
ORDER BY
thread#;
```

**5. (Optional) Check status from Grid Infra / Clusterware**
cause I using grid, using `srvctl` for checkup status resource database.

```bash
srvctl status database -d <db_unique_name_primary>
```

### Standby Instances

**1. Verified Database** 
Make sure standby database is `PHYSICAL STANDBY`
Column `OPEN_MODE` can value `MOUNTED` or `READ ONLY WITH APPLY` (if active data guard)

```sql
SELECT
name AS DB_NAME,
db_unique_name AS DB_UNIQUE_NAME,
database_role AS ROLE,
open_mode AS OPEN_MODE
FROM
v$database;
```

**2. Check Recovery Status (MRP - Managed Recovery Process)**
Check the status make sure the value `APPLYING_LOG` or `WAIT_FOR_LOG`
if the qery doesn't show anything, MRP doesn't work and standby instances doesn't sync
```sql
SELECT
process,
status,
thread#,
sequence#,
block#
FROM
v$managed_standby
WHERE
process LIKE 'MRP%';
```

**3. Check Log Last Sequence Received and Applied**
This command ideally must be `LAST_SEQ_RECEIVED` and `LAST_SEQ_APPLIED`  memiliki nilai yang sama atau sangat dekat.
```sql
SELECT
al.thread#,
max(al.sequence#) AS LAST_SEQ_RECEIVED,
max(lh.sequence#) AS LAST_SEQ_APPLIED
FROM
varchivedl,ogal,vlog_history lh
WHERE
al.thread# = lh.thread# AND al.first_time = lh.first_time
GROUP BY
al.thread#
ORDER BY
al.thread#;
```

**4. Check Archive Log Gap**
This query will be show expelicit if have gap (missing log) between primary and standby.
if the results is empty,it's mean no gap and that is a good sign.

```sql
SELECT * FROM v$archive_gap;
```

**5. Check Transport Lag and Apply Lag**
The easy way for see how long standby instance behind from primary instances.
`Transport Lag` : Lag send redo from primary instances
`Apply Lag` : lag applied redo on standby instances after received
The normal value is 0

```sql
SELECT
name,
value,
unit
FROM
v$dataguard_stats;
```

**6. Check Stat with Data Guard Broker (DGMGRL)**
Using `dgmgrl` is recommended.

- Connect as `sys` using OS authentication
```bash
dgmgrl sys/your_password@your_tns_alias as sysdba 

#or

dgmgrl /
```

- Show detail standby instances 
```bash
DGMGRL> show database <db_unique_name_standby>
```

- Valiedate Database
```bash
DGMGRL> validate database <db_unique_name_standby>
```

**7. (Optional) Check status from grid Infrastructure/ clusterware**
cause I using grid, using `srvctl` for checkup status resource database.

```bash
srvctl status database -d <db_unique_name_primary>
```

