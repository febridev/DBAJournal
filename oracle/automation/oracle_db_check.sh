#!/bin/bash

# ==============================================================================
# Script Name : oracle_db_check.sh
# Description : Oracle Database 19c Automated Health Check Script (PDB Supported)
# ==============================================================================

# 1. Environment Variable Check
if [ -z "$ORACLE_SID" ]; then
    echo "❌ Error: ORACLE_SID is not set. Please ensure the Oracle environment is loaded."
    exit 1
fi

# 2. Handle PDB Argument
# If an argument is provided, use it as PDB_NAME. Otherwise, default to CDB$ROOT.
PDB_NAME=${1:-CDB\$ROOT}

# 3. Setup Report File and PFILE Name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
# Clean up PDB_NAME for the filename (removes special characters like $)
SAFE_PDB_NAME=$(echo "$PDB_NAME" | tr -cd '[:alnum:]_') 
REPORT_FILE="/tmp/oracle_health_check_${ORACLE_SID}_${SAFE_PDB_NAME}_${TIMESTAMP}.log"
PFILE_PATH="/tmp/init_${ORACLE_SID}_${TIMESTAMP}.ora"

echo "Starting database check for SID: $ORACLE_SID"
echo "Target Container/PDB : $PDB_NAME"
echo "The report will be saved to: $REPORT_FILE"

# 4. Execute SQL*Plus
sqlplus -s / as sysdba <<EOF > "$REPORT_FILE"
-- Formatting for a cleaner log file output
SET LINESIZE 250
SET PAGESIZE 1000
SET FEEDBACK OFF
SET HEADING ON
SET TRIMSPOOL ON

-- Switch to the target PDB (or stay in CDB$ROOT)
PROMPT ========================================================================
PROMPT SETTING SESSION TO CONTAINER: $PDB_NAME
PROMPT ========================================================================
ALTER SESSION SET CONTAINER = $PDB_NAME;

--------------------------------------------------------------------------------
PROMPT
PROMPT ========================================================================
PROMPT 1. NON-DEFAULT ORACLE SCHEMAS (ORACLE_MAINTAINED = 'N') IN $PDB_NAME
PROMPT ========================================================================
COL username FORMAT A30
COL account_status FORMAT A20
COL created FORMAT A20

SELECT username, account_status, TO_CHAR(created, 'DD-MON-YYYY') as created
FROM dba_users 
WHERE oracle_maintained = 'N'
ORDER BY username;

--------------------------------------------------------------------------------
PROMPT 
PROMPT ========================================================================
PROMPT 2. GRANTS (SYS PRIVS & ROLES) ON NON-DEFAULT SCHEMAS IN $PDB_NAME
PROMPT ========================================================================
COL grantee FORMAT A30
COL privilege_or_role FORMAT A40
COL type FORMAT A15

SELECT grantee, privilege AS privilege_or_role, 'SYS_PRIV' AS type 
FROM dba_sys_privs 
WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
UNION ALL
SELECT grantee, granted_role AS privilege_or_role, 'ROLE' AS type 
FROM dba_role_privs 
WHERE grantee IN (SELECT username FROM dba_users WHERE oracle_maintained = 'N')
ORDER BY grantee, type, privilege_or_role;

--------------------------------------------------------------------------------
PROMPT
PROMPT ========================================================================
PROMPT 3. TOTAL INVALID OBJECTS GROUPED BY SCHEMA IN $PDB_NAME
PROMPT ========================================================================
COL owner FORMAT A30 HEADING 'SCHEMA OWNER'
COL total_invalid FORMAT 999,999 HEADING 'TOTAL INVALID OBJECTS'

SELECT owner, COUNT(*) AS total_invalid 
FROM dba_objects 
WHERE status = 'INVALID' 
GROUP BY owner
ORDER BY owner;

--------------------------------------------------------------------------------
PROMPT
PROMPT ========================================================================
PROMPT 4. NON-DEFAULT PARAMETERS (ISDEFAULT = 'FALSE')
PROMPT ========================================================================
COL name FORMAT A45
COL value FORMAT A80

SELECT name, value 
FROM v\$parameter 
WHERE isdefault = 'FALSE' 
ORDER BY name;

--------------------------------------------------------------------------------
PROMPT
PROMPT ========================================================================
PROMPT 5. PFILE CREATION IN /TMP (EXECUTED IN CDB ROOT)
PROMPT ========================================================================
-- Switch back to Root to ensure PFILE creation is handled at the instance level
ALTER SESSION SET CONTAINER = CDB\$ROOT;
CREATE PFILE='$PFILE_PATH' FROM SPFILE;
PROMPT PFILE successfully created at: $PFILE_PATH
PROMPT ========================================================================

EXIT;
EOF

# 5. Finish
echo "✅ Database check completed for $PDB_NAME!"
echo "📄 Please review the report file: $REPORT_FILE"
e
