# MySQL InnoDB Replication Ver 8.4 Ubuntu
This is guide for setup innodb replication on mysql 8.4 using ubuntu 24 LTS 

## Prerequiset
- Make Sure All node connected 
- If not please add config on `/etc/hosts`
```txt
10.10.50.7 mydbsql1
10.10.50.9 mydbsql2
10.10.50.11 mydbsql3
```
- Test Ping Again

## Primary Node
- Adjust Configurtaion `/etc/mysql/my.cnf`
```txt
[mysqld]
# Basic Network Settings
port=3306
bind-address=0.0.0.0 # Atau IP VM Anda (misal: 192.168.1.101)
mysqlx-bind-address=0.0.0.0 # Diperlukan untuk X Protocol, yang digunakan AdminAPI

# General Replication Settings (Wajib untuk Group Replication)
log_bin=mysql-bin
binlog_format=ROW
server-id = 507
enforce_gtid_consistency=ON
gtid_mode=ON
log_slave_updates=ON
binlog_expire_logs_seconds = 86400 # 1 Hari
max_connections=1000

# InnoDB Settings (Sesuaikan dengan kebutuhan dan RAM VM Anda)
#innodb_buffer_pool_size=2G # Minimal 25% dari total RAM, sesuaikan
#innodb_log_file_size=256M
#innodb_flush_log_at_trx_commit=1

# JANGAN set parameter Group Replication seperti group_replication_group_name,
# group_replication_local_address, group_replication_group_seeds secara manual.
# Ini akan diatur oleh AdminAPI.
```
- Add / Grant user `repuser`
```sql
-- IF CREATE 
-- CREATE USER 'repuser'@'%' IDENTIFIED BY 'repuser';
GRANT BACKUP_ADMIN, GROUP_REPLICATION_ADMIN ON *.* TO 'repuser'@'%';
FLUSH PRIVILEGES;
```

## Second Node 
- Adjust Configurtaion `/etc/mysql/my.cnf`
```txt
[mysqld]
# Basic Network Settings
port=3306
bind-address=0.0.0.0 # Atau IP VM Anda (misal: 192.168.1.101)
mysqlx-bind-address=0.0.0.0 # Diperlukan untuk X Protocol, yang digunakan AdminAPI

# General Replication Settings (Wajib untuk Group Replication)
log_bin=mysql-bin
binlog_format=ROW
server-id = 509
enforce_gtid_consistency=ON
gtid_mode=ON
log_slave_updates=ON
binlog_expire_logs_seconds = 86400 # 1 Hari
max_connections=1000

# InnoDB Settings (Sesuaikan dengan kebutuhan dan RAM VM Anda)
#innodb_buffer_pool_size=2G # Minimal 25% dari total RAM, sesuaikan
#innodb_log_file_size=256M
#innodb_flush_log_at_trx_commit=1

# JANGAN set parameter Group Replication seperti group_replication_group_name,
# group_replication_local_address, group_replication_group_seeds secara manual.
# Ini akan diatur oleh AdminAPI.
```

- Add / Grant user `repuser`
```sql
-- IF CREATE 
-- CREATE USER 'repuser'@'%' IDENTIFIED BY 'repuser';
GRANT BACKUP_ADMIN, GROUP_REPLICATION_ADMIN ON *.* TO 'repuser'@'%';
FLUSH PRIVILEGES;
```

## Third Node
- Adjust Configurtaion `/etc/mysql/my.cnf`
```txt
[mysqld]
# Basic Network Settings
port=3306
bind-address=0.0.0.0 # Atau IP VM Anda (misal: 192.168.1.101)
mysqlx-bind-address=0.0.0.0 # Diperlukan untuk X Protocol, yang digunakan AdminAPI

# General Replication Settings (Wajib untuk Group Replication)
log_bin=mysql-bin
binlog_format=ROW
server-id = 511
enforce_gtid_consistency=ON
gtid_mode=ON
log_slave_updates=ON
binlog_expire_logs_seconds = 86400 # 1 Hari
max_connections=1000

# InnoDB Settings (Sesuaikan dengan kebutuhan dan RAM VM Anda)
#innodb_buffer_pool_size=2G # Minimal 25% dari total RAM, sesuaikan
#innodb_log_file_size=256M
#innodb_flush_log_at_trx_commit=1

# JANGAN set parameter Group Replication seperti group_replication_group_name,
# group_replication_local_address, group_replication_group_seeds secara manual.
# Ini akan diatur oleh AdminAPI.
```

- Add / Grant user `repuser`
```sql
-- IF CREATE 
-- CREATE USER 'repuser'@'%' IDENTIFIED BY 'repuser';
GRANT BACKUP_ADMIN, GROUP_REPLICATION_ADMIN ON *.* TO 'repuser'@'%';
FLUSH PRIVILEGES;
```

# Setup InnoDB Replication Using `mysqlsh`
## Primary Node
This primary node will be set as primary node have R/W access
```bash
mysqlsh --uri repuser@10.10.50.7:3306
\js
```
```js
var cluster = dba.createCluster('ldvcluster');
```