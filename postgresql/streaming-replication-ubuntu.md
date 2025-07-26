# Streaming Replication Postgres-13 Ubuntu 24 LTS
This is runbook for setup streaming replication (by default is asynchronus) 

## Primary Node
- Edit postgresql.conf
```bash
sudo -i -u postgres
vi /etc/postgresql/13/main/postgresql.conf
```
- Enable this value
```txt
...
listen_address=*
wal_level = replica
hot_standby = on
...
```
- Save file

- Create User `repuser`
```bash
sudo -i -u postgres
psql
```
```sql
create repuser with replication encrypted password 'repuser';
```

- Edit `pg_hba.conf`
```bash
sudo -i -u postgres
vi /etc/postgresql/13/main/pg_hba.conf
```
```text
host    replication     repuser         10.10.50.0/24           md5
```

- Restart Postgresql services
```bash
sudo su
systemctl restart postgresql
systemctl status postgresql
```

## Standby Node
- Start Postgresql Services
```bash
sudo su
systemctl start postgresql
systemctl status postgresql
```

- Delete All Datafiles 
```bash
sudo -i -u postgres
rm -rf /var/lib/postgresql/13/main/*
```

- Run `pg_basebackup` to clone all datafiles from primary node to standby node 
For safeguard please check `pg_replication_slots` on primary node first, make sure new standby doesn't using same replication slotname

```bash
sudo -i -u postgres
pg_basebackup -h <ip_primary> -U <repuser> -p 5432 -D <path_datafile> -Fp -Xs -P -R -C -S <replication_slot_name>

: << 'END_COMMENT'
-h =host
-U = user
-p = Port
-D = data directory
-F = format (plain or tar)
-p = plain
-X  = wal method ( none || fetch || stream)
-s = stream
-P  = Progress
-R = write configuration for replication.
-C = Creation of replication slot named by the -S option
-S  = name of the replication slot.

END_COMMENT

#Expectation Results
#32334/32334 kB (100%), 1/1 tablespace
```

- Check Log `postgresql-13-main.log`
```bash
: <<'END_COMMENT'
2025-07-19 08:37:57.306 UTC [354701] LOG:  entering standby mode
2025-07-19 08:37:57.439 UTC [354701] LOG:  restored log file "000000010000000000000015" from archive
2025-07-19 08:37:57.510 UTC [354701] LOG:  redo starts at 0/15000028
2025-07-19 08:37:57.514 UTC [354701] LOG:  consistent recovery state reached at 0/15000100
2025-07-19 08:37:57.524 UTC [354700] LOG:  database system is ready to accept read only connections
2025-07-19 08:37:57.568 UTC [354701] LOG:  restored log file "000000010000000000000016" from archive
cp: cannot stat '/var/lib/postgresql/13/archive/000000010000000000000017': No such file or directory
2025-07-19 08:37:57.660 UTC [354719] LOG:  started streaming WAL from primary at 0/17000000 on timeline 1
END_COMMENT

```

### Monitoring 
- Check Replication Status
```sql
\x
select * from pg_stat_replication;
```


# Streaming Replication Postgres-13 Ubuntu 24 LTS (Synchronus)
## Primary Node
- login into database as `postgres`
```bash
sudo -i -u postgres
```
```sql
ALTER SYSTEM SET synchronous_standby_names TO '*';
```
- Restart Postgresql Service
```bash
systemctl restart postgresql
```

- Rollback to asynchronous
```sql
ALTER SYSTEM RESET ALL;
```

- Restart Postgresql Service
```bash
systemctl restart postgresql
```

## Standby Node


# Check `pg_replication_slots`
This is how to check which one pg_replication_slots
```bash
sudo -i -u postgres
```
```sql
select * from pg_replication_slots;
```
