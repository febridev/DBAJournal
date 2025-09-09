# Setup param `db_unique_name` On Oracle 19C with grid infra and asm 

- **Check Current Value param** `db_unique_name`
```bash
su - oracle
sqlplus / as sysdba
```

```sql
sql> SHOW PARAMETER db_unique_name;
```

The param `db_unique_name` must be different between primary and standby instances for dataguard to work.

- **Show Parameter SPFILE**

```bash
su - oracle
sqlplus / as sysdba
```

```sql
sql> SHOW PARAMETER spfile; 
```

Copy the path and spfile name
If using asm disk group will be like this 


If using file system will be like this


- **Create PFILE from SPFILE**

```bash
su - oracle
sqlplus / as sysdba
```

```sql
CREATE PFILE FROM SPFILE;
```

The default path will be `$ORACLE_HOME/dbs` with filename `init<yoursid>.ora`

- **Shutdown The Instances**
```bash
su - oracle
sqlplus / as sysdba
```

```sql
SHUTDOWN IMMEDIATE;
```

- **Edit PFILE and add parameter** `db_unique_name`
```bash
su - oracle
cd $ORACLE_HOME/dbs
```

For example in my case the PFILE is `initnt19c2.ora`
```bash
vi initnt19c2.ora
```

Add this text on last line
```txt
...
*.db_unique_name='nt19c2_pri'

:wq
```

in this case I will put `nt19c2_pri` meaning that is as primary intsances. Save the file

- **Startup The Instances using PFILE**
```bash
su - oracle 
sqlplus / as sysdba
```

```sql
sql > STARTUP PFILE=/u01/19c/oracle_base/oracle/dbs/initnt19c2.ora
```

- **Check Parameter** `db_unique_name` **after startup using PFILE**

```sql
sql> SHOW PARAMETER db_unique_name;
```

If the value is correct or align with pfile already changes, for example in this case must be `nt19c2_pri`

- **Create SPFILE from PFILE**

```sql
CREATE SPFILE='' FROM PFILE;
```

- **Shutdown Instance**
```sql
SHUTDOWN IMMEDIATE;
```

<p> Before we startup again the instances, rename the pfile for make sure oracle doesn't use the pfile.
For example the pfile is `init19c2.ora` rename to `init19c2.ora.bkp`
</p>

- **Rename the pfile before startup**
```bash
su - oracle 
cd $ORACLE_HOME/dbs

mv initxxxx.ora initxxxx.ora.bkp
```

- **Startup Instance**
```sql
STARTUP;
```

- **Check Current Instance running under spfile / pfile**
```sql
show parameter pfile;
```
If the results have a file for example `+DATA/xxxx/xxx.ora`. That's mean the instances is running using spfile.

- **Check the parameter** `db_unique_name`
```sql
show parameter uniq;
```

Make sure the value is same with our expectation.


