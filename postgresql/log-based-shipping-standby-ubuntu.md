# Runbook Log Based Shipping Standby 
Ubuntu 24 LTS, Postgres 13

# Initiation Setup
## Prepare On Primary Node
- Generate SSH Key
Generate key between node primary and standby node
```bash
sudo -i -u postgres
ssh-keygen
```
Enter for using default value

- SSH Copy ID Between Primary and Standby node
```bash
sudo -i -u postgres
ssh-copy-id postgres@<yourip_or_yourservername>
```

- Edit Configuration File On Primary Node
```bash
sudo -i -u postgres
nano /etc/postgresql/13/main/postgresql.conf
```

- Edit On archive part
```txt
archive_mode = on
archive_command = 'rsync -a %p postgres@<standbyip>:/var/lib/postgresql/13/archive/%f'
archive_timeout = 60
```
Save file

## Setup On Standby Node
- Stop Postgres service
```bash
sudo su
systemctl stop postgresql
systemctl status postgresql
```

- Create directory `archive`
```bash
sudo -i -u postgres
mkdir /var/lib/postgresql/13/archive
```

- Delete all datafile on standby node
Because we want to clone all the datafile from Primary Node To Standby Node
```bash
sudo -i -u postgres
rm -rf /var/lib/postgresql/13/main/*
```

# Run Sync Datafile 
## Primary Node
- Start Postgresql Service
```bash
sudo su
systemctl start postgresql
systemctl status postgresql
```

- Start Backup Database
```bash
sudo -i -u postgres
psql
```

```sql
select pg_start_backup('dbrepl');
```

- Run Rsync Manually for Initation Datafile To Standby Node
```bash
rsync -avz /var/lib/postgresql/13/main/* postgres@<ipstandby>:/var/lib/postgresql/13/main/
```

- Check File Already sync On Standby Node
```bash
sudo -i -u postgres
ls /var/lib/postgresql/13/main/
```

- Stop Backup Database
```bash
sudo -i -u postgres
psql
```
```sql
select pg_stop_backup();
-- Expected Results
NOTICE:  all required WAL segments have been archived
 pg_stop_backup
----------------
 0/4000050
(1 row)

```

## Standby Node

- Check Archive Log On Standby Node
```bash
sudo -i -u postgres
ls /var/lib/postgresql/13/archive
```

- Change Configuration File 
Because All the data and configuration file is coming from `Primary` Node, And set parameter `Restore Command`
```bash
sudo -i -u postgres
vi /etc/postgresql/13/main/postgresql.conf
```
Comment this parameter
```txt
#archive_mode=on
#archive_command='rsync -a %p postgres@<yourip>:/var/lib/postgresql/13/archive/%f'
#archive_timeout=60

...
restore_command = 'cp /var/lib/postgresql/13/archive/%f %p
...
```
Save File

- Create Standby File ON Standby Node
```bash
sudo -i -u postgres
cd /var/lib/postgresql/13/main
touch standy.signal
```

- Start Postgres at Standby Node
```bash
sudo su
systemctl start postgresql
systemctl status postgresql
```
    - Check Log Pararel 
    ```bash
    sudo -i -u postgres
    cd /var/log/postgresql
    tail -100f postgresql-13-main.log
    ```

    - capture the message on log
    ```
    LOG:  database system is ready to accept read only connections
    ```

# Monitoring Sync 
## Primary Node
```bash
sudo -i -u postgres
psql
```
```sql
-- Untuk PostgreSQL 10 ke atas
SELECT pg_current_wal_lsn()
```

## Standby Node
```bash
sudo -i -u postgres
psql
```
```sql
-- Untuk PostgreSQL 10 ke atas
SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
-- Contoh di Standby (jika Anda ingin melihat gap dari sudut pandang standby)
-- Asumsikan Anda mendapatkan current_wal_lsn dari primary
SELECT pg_wal_lsn_diff('PRIMARY_CURRENT_LSN_DARI_PRIMARY', pg_last_wal_replay_lsn());
```

# Demo Failover
Common situation is the primary node is down and we need up the standby node immediately

## Standby Node
- Check The GAP For Evidence
```bash
sudo -i -u postgres
psql
```
```sql
-- Untuk PostgreSQL 10 ke atas
SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
```

If `pg_last_wal_receive_lsn()` is empty or null we have evidence standby node is same with primary node, but is opposite that's mean standby node have a gap with primary, please info to your stakeholder related RPO & RTO for risk the data loss.

- Promote standby node 
```bash
sudo -i -u postgres
pg_ctl promote -D /var/lib/postgresql/13/main
# Expected Results
# waiting for server to promote.... done
# server promoted

```

- Check `standby.signal` file
```bash
sudo -i -u postgres
ls /var/lib/postgresql/13/main
```


## Primary Node
If primary node can start again the data will be not sync with standby node, we need setup again the physical standby node.