# How To Parameter Changes

## Backup Current Configuration (SPFILE)
```sql
CREATE PFILE FROM SPFILE;
```


## Example
```sql
ALTER SYSTEM SET processes = 2000 SCOPE=SPFILE;
```
