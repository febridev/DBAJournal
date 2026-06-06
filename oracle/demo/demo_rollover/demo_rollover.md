# Demo Standby Instance Disconnect From Primary

## Make STANDBY disconnect from PRIMARY
- Stop standby instances receive from primary
```sql
/*
Execute On Standby Instances
*/
-- Jika menggunakan SQLPlus
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;

-- Jika menggunakan DGMGRL (sesuai PDF langkah 1 )
EDIT DATABASE 'nama_standby_db' SET STATE='APPLY-OFF';
```

- Add gap data with create some object into primary database 
```sql
/*
Execute On Primary Database
*/

-- Buat table dummy
CREATE TABLE simulation_gap (id number, data char(200));

-- Insert data yang banyak untuk memicu redo generation
BEGIN
  FOR i IN 1..100000 LOOP
    INSERT INTO simulation_gap VALUES (i, 'Simulasi Gap Data 1 Tahun');
    COMMIT;
  END LOOP;
END;
/
```
- Disconnect Bridge between PRIMARY and STANDBY
```sql
/* 
Execute on PRIMARY
*/

-- Lakukan log switch berulang kali (misal 5-10 kali)
ALTER SYSTEM SWITCH LOGFILE;
-- Tunggu beberapa detik, ulangi lagi
ALTER SYSTEM SWITCH LOGFILE;
-- Lakukan checkpoint
ALTER SYSTEM CHECKPOINT;
```

- Drop Archive Log
```sql
/* 
Execute On PRIMARY
*/

rman target /
RMAN> DELETE ARCHIVELOG ALL;
-- Jawab YES saat diminta konfirmasi.
```

- Verify Standby Is DISCONNECT
```sql
/*
Execute On STANDBY
*/
-- Di Standby
SELECT * FROM V$ARCHIVE_GAP;
-- Anda akan melihat gap.
```

## Fix Standby With ROLLOVER
