oracle.install.responseFileVersion=/oracle/install/rspfmt_crsinstall_response_schema_v19.0.0

#-------------------------------------------------------------------------------
# SECTION A - BASIC
#-------------------------------------------------------------------------------
INVENTORY_LOCATION=/u01/19c/oraInventory
oracle.install.option=HA_CONFIG
ORACLE_BASE=/u01/19c/grid_base

#-------------------------------------------------------------------------------
# SECTION B - GROUPS
#-------------------------------------------------------------------------------
oracle.install.asm.OSDBA=asmdba
oracle.install.asm.OSOPER=asmoper
oracle.install.asm.OSASM=asmadmin

#-------------------------------------------------------------------------------
# SECTION G - ASM
#-------------------------------------------------------------------------------
oracle.install.asm.SYSASMPassword=PasswordKuatAnda123!
oracle.install.asm.diskGroup.name=DATA
oracle.install.asm.diskGroup.redundancy=EXTERNAL
oracle.install.asm.diskGroup.AUSize=4
oracle.install.asm.diskGroup.FailureGroups=
oracle.install.asm.diskGroup.disksWithFailureGroupNames=
oracle.install.asm.diskGroup.disks=/dev/oracleasm/asm-data01
oracle.install.asm.diskGroup.quorumFailureGroupNames=
oracle.install.asm.diskGroup.diskDiscoveryString=/dev/oracleasm/*
oracle.install.asm.monitorPassword=PasswordKuatAnda123!
oracle.install.asm.configureAFD=false

#-------------------------------------------------------------------------------
# ROOT SCRIPT AUTOMATION (Opsional tapi Direkomendasikan untuk Fully Silent)
#-------------------------------------------------------------------------------
oracle.install.crs.rootconfig.executeRootScript=true
oracle.install.crs.rootconfig.configMethod=ROOT
