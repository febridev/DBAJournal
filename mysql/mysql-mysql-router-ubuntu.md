# Setup MySQL-Router On Ubuntu 24 LTS
This is will guide setup mysql router as loadbalancer front of mysql innodb replication

## Download
- Download or get mysqlrouter package
```bash
sudo apt install mysql-router
# or
wget https://dev.mysql.com/get/Downloads/MySQL-Router/mysql-router_8.4.6-1ubuntu24.04_amd64.deb
dpkg -i mysql-router_8.4.6-1ubuntu24.04_amd64.deb
sudo apt --fix-broken install
```

## Config MySQL-Router
- Preapre the config file 
```bash
sudo mysqlrouter --bootstrap root@<IP_NODE1_CLUSTER>:3306 --user mysqlrouter
```
