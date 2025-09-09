# How To Parameter Changes

## Backup Current Configuration (SPFILE)
```sql
CREATE PFILE FROM SPFILE;
```


## Example
```sql
ALTER SYSTEM SET processes = 2000 SCOPE=SPFILE;
```


## CHANGE db_unique_name
- Create PFILE FROM SPFILE
```sql
CREATE PFILE FROM SPFILE;
```

- Check PFILE on $ORACLE_HOME/dbs
```bash
ls -ltrh $ORACLE_HOME/dbs
```

- Edit PFILE add parameter db_unique_name
```bash
su - oracle
vi $ORACLE_HOME/dbs/initnt19c2.ora
# add line 
# *.db_unique_name='nt19c2_pri'
# save file
```

- Shutdown Instances and Up using pfile 
```bash
su - oracle 
sqlplus / as sysdba
```

```sql
SHUTDOWN IMMEDIATE;
-- wait until finish
STARTUP PFILE=/u01/19c/oracle_base/oracle/dbs/initnt19c2.ora;

-- CHECK PARAMETER db_unique_file
show parameter uniq
-- expected results 
NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
db_unique_name			     string	 nt19c2_pri

-- CREATE SPFILE FROM PFILE 
create spfile='+DATA/NT19C2/PARAMETERFILE/spfile_nt19c2.ora' from pfile;
```

- Shutdown Instances
```bash
su - oracle
sqlplus / as sysdba
```

```sql
SHUTDOWN IMMEDIATE;
```

- Up Database using SPFILE
```bash
su - oracle
sqlplus / as sysdba
```

```sql
STARTUP
-- Check the parameter spfile make sure running from spfile 
show parameter spfile;
-- expected results
NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
spfile				     string	 /u01/19c/oracle_base/oracle/db
						 _home/dbs/spfilent19c2.ora
```
IF spfile is empty is mean the instances running from pfile

## If spfile is empty 