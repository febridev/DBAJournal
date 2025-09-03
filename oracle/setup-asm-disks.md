# Setup ASM Disks
## Partition 
- check disk 
```bash
lsbk
```
- Create Partition On Disk 
```bash
/usr/lib/udev/scsi_id -g -u -d /dev/sdb1
# or
udevadm info --query=property --name=/dev/sdb
```

## Add Disks from sqlplus
- Check Candidate
```bash
asmcmd lsdsk --candidate
```

```sql
SET LINESIZE 200
COL NAME FORMAT A20

SELECT
    NAME,
    STATE,
    TYPE AS REDUNDANCY,
    TOTAL_MB,
    FREE_MB,
    USABLE_FILE_MB
FROM
    V$ASM_DISKGROUP;
```

- Add disks Group
```sql
CREATE DISKGROUP DATA EXTERNAL REDUNDANCY
DISK '/dev/oracleasm/asm-data0'
ATTRIBUTE
  'compatible.asm' = '19.0.0.0',
  'compatible.rdbms' = '19.0.0.0';

CREATE DISKGROUP FRA EXTERNAL REDUNDANCY
DISK '/dev/oracleasm/asm-fra0'
ATTRIBUTE
  'compatible.asm' = '19.0.0.0',
  'compatible.rdbms' = '19.0.0.0';
```

## Install DB Software Only Silent
```bash
export CV_ASSUME_DISTID=OEL8
./runInstaller -applyRU /u01/patches/dbpatch/36582781/ -silent -responseFile ~/db.rsp -ignorePrereq -waitForCompletion
```

## Create Database dbca silent
```bash
dbca -silent -createDatabase -responseFile /path/to/your/dbca_response_file.rsp
```


## Error 
- [DBT-05802] Creating password file on diskgroup (DATA) would fail since it requires compatible.asm of version (12.1.0.0.0) or higher. Current compatible.asm version is '11.2.0.2.0'.
```bash
sqplus / as sysasm
```

```sql
-- CHeck Compatibility ASM
select group_number, name, compatibility, database_compatibility from v$asm_diskgroup;
```

```bash
# change compatibility asm
asmcmd setattr -G DATA compatible.asm 19.0.0.0.0
```