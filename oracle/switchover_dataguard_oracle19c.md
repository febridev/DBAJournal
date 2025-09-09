# Switchover Dataguard Oracle 19c With ASM and Grid
This guide will be help to switchover between primary and standby (physical standby) on oracle 19c with asm and dataguard 

## Check Status Replication
- Using Data Guard Broker (dgmgrl)
    - Login as oracle user 
    ```bash
    su - oracle
    ```
    - Open dgmgrl connect to primary or standby 
    ```bash
    dgmgrl sys/your_password@TNS_ALIAS_STANDBY_or_PRIMARY
    ```
    - Check Current Status From Configuration
    ```bash
    DGMGRL> show configuration
    # expected results
    # Configuration - my_dg_config
    # Protection Mode: MaxPerformance
    # Members:
    # t19c2_pri - Primary database
    #    nt19c2_std - Physical standby database

    # Fast-Start Failover: DISABLED

    # Configuration Status:
    # SUCCESS   <-- this one as key successfull
    ```
    - Check Status Detail On Database
    ```bash
    DGMGRL> SHOW DATABASE 'nt19c2_pri';
    DGMGRL> SHOW DATABASE 'nt19c2_std';
    # Expected Results
    # Database - nt19c2_std

    # Role:               PHYSICAL STANDBY
    # Intended State:     APPLY-ON
    # Transport Lag:      0 seconds (computed 1 second ago) <- this must be 0 seconds 
    # Apply Lag:          0 seconds (computed 1 second ago) <- this must be 0 seconds
    # Average Apply Rate: 958.00 KByte/s
    # Real Time Query:    OFF
    # Instance(s):
    #    nt19c2

    # Database Status:
    # SUCCESS
    ```
- Using SQL Command
    - Login as oracle user On Primary Instance
    ```bash
    su - oracle
    ```
    - Login To Database using sqlplus as sysdba
    ```bash
    sqlplus / as sysdba
    ```
    - Check Readines Switchover 
    ```sql
    -- Running On Primary Instance
    SELECT switchover_status FROM v$database;
    -- Expected Results
    /*
    TO STANDBY Or SESSIONS ACTIVE. 
    If Not Allowed any condition as blocker switchover
    */
    ```
    - Check Transport Lag From Primary Instance
    ```sql
    -- Running On Primary Instance
    SELECT name, value, unit FROM v$dataguard_stats WHERE name LIKE 'transport lag';
    -- Expected Results
    -- +00 00:00:00
    ```
    - Check GAP For Archive Log
    ```sql
    -- Runnin On Primary Instance
    SELECT thread#, low_sequence#, high_sequence# FROM v$archive_gap;
    -- expected results
    -- no rows selected
    ```
    - Login as oracle user on Standby Instance
    ```bash
    su - oracle
    ```
    - Login To Database using sqlplus as sysdba
    ```bash
    sqlplus / as sysdba
    ```
    - Check Readines Switchover 
    ```sql
    -- Running On Standby Instance
    SELECT switchover_status FROM v$database;
    -- Expected Results
    -- TO_PRIMARY or SESSION ACTIVE
    ```
    - Check Lag Apply Log
    ```sql
    -- Running On Standby
    SELECT name, value, unit FROM v$dataguard_stats WHERE name LIKE 'apply lag';
    -- Expected Results
    -- +00 00:00:00
    ```
    - Check Recovery Process
    ```sql
    -- Running ON Standby
    SELECT process, status, thread#, sequence# FROM v$managed_standby WHERE process = 'MRP0';
    -- Expected Results
    -- APPLYING_LOG
    -- If WAIT_FOR_LOG the instance is waiting new log from primary, but if not have lag is normal. but have a lag this is will be issue.
    ```
## Switchover
- Using Data Guard Broker (dgmgrl)
    - Login as oracle user (standby or primary)
    ```bash
    su - oracle
    ```
    - Login To dgmgrl
    ```bash
    dgmgrl / 
    # or
    dgmgrl sys/sysdba@TNS_ALIAS_STANDBY_or_PRIMARY
    ```
    - Execute Switchover 
    ```bash
    DGMGRL> SWITCHOVER TO 'your_standby_instance_db_unique_name';
    ```
    What are dataguard broker Do is :
    1. Check Latest Prepared.
    2. Stop Redo Log Transport to Standby Instance.
    3. Waiting Latest redo finish applied on standby instance.
    4. Change old-primary to physical standby.
    5. Change old-standby to new primary.
    6. Execute shutdown and restart on both instance (primary and standby).
    7. Re-Configuration Redo Transport from new primary to new standby instance.
    This process will be take more time. Please wait until `DGMGRL` show message `Switchover succeeded, new primary is "your_standby_instance"`.
    
    - Check Configuration After Switchover.
    ```bash
    DGMGRL> show configuration
    ```
