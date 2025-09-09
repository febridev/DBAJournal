# Switch From Active To Passive DataGuard Oracle 19c with Grid Infra & ASM

- **Stop standby apply redo / archive log**
```bash
dgmgrl
connect sys/<password>@<tns_alias_standby>

EDIT DATABASE 'nama_db_unique_standby' SET STATE='APPLY-OFF';
```

- **Go To Standby Instance, and shutdown and startup mount**
```sql
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
```

- **Back to dgmgrl and set state apply on**
```bash
dgmgrl
connect sys/<password>@<tns_alias_standby>

EDIT DATABASE 'nama_db_unique_standby' SET STATE='APPLY-ON';

SHOW DATABASE 'nama_db_unique_standby';
```

- **Check status and role dan open mode on standby instances**
```sql
-- Di SQL*Plus
SELECT open_mode, database_role FROM v$database;
```