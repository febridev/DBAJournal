# Phase 3 Install Oracle Software
## Prepare installation files
- Extract installation files from oracle user 
```bash
su - oracle
cd /tmp
unzip LINUX.X64_193000_db_home.zip -d $ORACLE_HOME
```

- Extract OPatch Files
```bash
su - oracle
cd $ORACLE_HOME
mv OPatch OPatch_bak
cd /tmp
unzip p6880880_190000_Linux-x86-64.zip -d $ORACLE_HOME
```

- Extract Latest Patch Files
```bash
su - oracle
cd /tmp/oracle-patch
unzip p39062931_190000_Linux-x86-64.zip
```

## Setup Response Files
```bash
su - oracle
cat << EOF > /tmp/db_install.txt
####################################################################
## Oracle Database 19c Software Only Response File
## Architecture: Standalone / Oracle Restart (Grid ASM)
####################################################################

# Version schema definition
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0

# Installation Option
oracle.install.option=INSTALL_DB_SWONLY

# System Groups & Base Paths
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=/u01/app/oraInventory
ORACLE_BASE=/u01/19c/oracle_base

# Edition
oracle.install.db.InstallEdition=EE

# Privileged Operating System Groups
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSDGDBA_GROUP=dgdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=racdba

# Root Script Execution (Manual execution via root user)
oracle.install.db.rootconfig.executeRootScript=true
oracle.install.db.rootconfig.configMethod=SUDO
oracle.install.db.rootconfig.sudoPath=/usr/bin/sudo
oracle.install.db.rootconfig.sudoUserName=oracle

# Cluster Nodes (Wajib kosong untuk Standalone / Oracle Restart)
oracle.install.db.CLUSTER_NODES=
EOF
```

## Run Installation
```bash
su - oracle
cd $ORACLE_HOME
export CV_ASSUME_DISTID=OEL8
./runInstaller -silent -applyRU /tmp/oracle-patch/39062931 -responseFile /tmp/db_install.rsp -ignorePrereq -waitforcompletion
```
