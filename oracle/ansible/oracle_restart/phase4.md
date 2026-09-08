# Phase 4 - Create Database Instances (dbca)
## Prepare response files
```bash
su - oracle
cat << 'EOF' > /home/oracle/dbca.rsp
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v12.2.0
gdbName=dborcl
sid=dborcl
DB_UNIQUE_NAME=dborcl
asmSysPassword=Welcome123#
databaseConfigType=SI
templateName=/u01/19c/oracle_base/oracle/db_home/assistants/dbca/templates/General_Purpose.dbc
sysPassword=5tgb^YHN
systemPassword=5tgb^YHN 
serviceUserPassword=database
datafileJarLocation={ORACLE_HOME}/assistants/dbca/templates/
datafileDestination=+DATA/{DB_UNIQUE_NAME}/
recoveryAreaDestination=+FRA
storageType=ASM
diskGroupName=+DATA/{DB_UNIQUE_NAME}/
recoveryGroupName=+FRA
characterSet=AL32UTF8
nationalCharacterSet=AL16UTF16
registerWithDirService=false
skipListenerRegistration=true
databaseType=MULTIPURPOSE
EOF
```
## Run dbca silent mode 
```bash
su - oracle
dbca -silent -createDatabase -responseFile /home/oracle/dbca.rsp
```
