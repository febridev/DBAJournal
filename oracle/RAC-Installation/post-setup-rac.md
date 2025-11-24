# Add Instances as Services
```bash
su - oracle
srvctl add service -d <DB_NAME> -s <SERVICES_NAME> -r <NODE1>,<NODE2> -P BASIC
# Example
# srvctl add service -d DEMORH01 -s DEMORH01_SERVICE -r DEMORH011,DEMORH012 -P BASIC
```