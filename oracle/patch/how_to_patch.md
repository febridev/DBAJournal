# Step By Step Oracle Database Patch.

This document will be cover for Linux OS

## Phase 1: Preparation & Downloads

1. Before touching the database, get your files ready and secure your environment.

2. Download the latest OPatch: Always use the newest OPatch utility for the latest RUs. Go to My Oracle Support (MOS) and download Patch 6880880 for your OS/architecture.

3. Download the 19.30 RU: Download the 19.30 Release Update patch from MOS.

4. Take a Backup: Perform a full RMAN backup (or at least a guaranteed restore point) before starting.

5. Stage the files: Upload both zip files to your database server (e.g., into /u01/stage).

## Phase 2: Phase 2: Update the OPatch Utility

You must update OPatch in your $ORACLE_HOME before applying the new RU.

```bash
# Log in as the oracle OS user
export ORACLE_HOME=/your/oracle/home/path
cd $ORACLE_HOME

# Rename the existing OPatch directory (as a backup)
mv OPatch OPatch_backup_19_25

# Unzip the new OPatch utility into the Oracle Home
unzip /u01/stage/p6880880_190000_Linux-x86-64.zip -d $ORACLE_HOME

# Verify the version (It should be 12.2.0.1.40 or higher)
$ORACLE_HOME/OPatch/opatch version

```

## Phase 3: Pre-Patch Checks

Ensure the patch won't conflict with anything currently installed and that your system has enough space.

```bash
# Unzip the 19.30 patch to your stage directory
cd /u01/stage
unzip p<19_30_PATCH_NUMBER>_190000_Linux-x86-64.zip
cd <19_30_PATCH_DIR>

# Run the conflict check
$ORACLE_HOME/OPatch/opatch prereq CheckConflictAgainstOHWithDetail -ph ./

# Check system space
$ORACLE_HOME/OPatch/opatch prereq CheckSystemSpace -ph ./
```

If both checks return "Prereq '...' passed", you are clear to proceed.

## Phase 4: Apply the Software Patch

This updates the Oracle binaries. The database and listener must be down.

**1. Stop the Listener and Database:**

```bash
export ORACLE_SID=yourdb
lsnrctl stop

sqlplus / as sysdba
SQL> SHUTDOWN IMMEDIATE;
SQL> EXIT;
```

**2. Apply the Patch:**

```bash
cd /u01/stage/<19_30_PATCH_DIR>
$ORACLE_HOME/OPatch/opatch apply
```

Answer y when prompted to proceed, and y when asked if the system is ready for patching.

## Phase 5: Post-Patch Database Steps (Datapatch)

Now that the binaries are updated, you need to apply the SQL changes to the database dictionary.

**1. Start the Database and Listener:**

```bash
lsnrctl start

sqlplus / as sysdba
SQL> STARTUP;
SQL> EXIT;

```

**2. Run Datapatch:**
This utility applies the internal SQL scripts required for 19.30.

```bash
cd $ORACLE_HOME/OPatch
./datapatch -verbose
```

**3. Recompile Invalid Objects:**
Datapatch often invalidates some objects. Recompile them using the standard Oracle script:

```bash
cd $ORACLE_HOME/rdbms/admin
sqlplus / as sysdba
SQL> @utlrp.sql
```

## Phase 6: Verification

**1. Check Binaries**

```bash
$ORACLE_HOME/OPatch/opatch lsinventory
```

(Look for the 19.30 Release Update in the installed patches list).

**2. Check the database dictionary:**

```sql
sqlplus / as sysdba
SQL> SELECT patch_id, version, status, action, description
     FROM dba_registry_sqlpatch;
```

(You should see a row for the 19.30 patch with a status of 'SUCCESS').

# Rollback When Error Happen

## Error At Phase 4:

This phase updates the physical software binaries on the OS. If it fails, your database software is in an inconsistent state, but your actual database data (datafiles) is untouched.

**1. Check the Log File Immediately: OPatch will usually output the exact path to the log file when it fails.**

- Location: $ORACLE_HOME/cfgtoollogs/opatch/

- Search the log for ERROR or FAILED.

**2. Common Culprit - Active Processes: The #1 reason opatch apply fails is that a background process is still holding onto an Oracle binary.**

- Ensure the listener and database are completely down.

- Check for zombie processes holding the binaries: /sbin/fuser -c $ORACLE_HOME/bin/oracle

- Kill any rogue processes tied to the Oracle software.

**4. How to Recover:**

- If you fixed the issue (e.g., killed a process): You can usually just re-run $ORACLE_HOME/OPatch/opatch apply and it will attempt to resume or prompt you to continue.

- If the patch is corrupted or stuck: You can roll it back using $ORACLE_HOME/OPatch/opatch rollback -id <19_30_PATCH_NUMBER>.

- The Nuclear Option: If the Oracle Home is completely broken and OPatch won't respond, this is why you take a backup of the $ORACLE_HOME or rely on your OS-level backups before patching.

## Error At Phase 5:

This phase runs SQL scripts against your database dictionary. If it fails, your binaries are fine, but your database dictionary is not fully updated.

**1. Check the Log File: Datapatch generates very detailed HTML and text logs.**

- Location: $ORACLE_HOME/cfgtoollogs/sqlpatch/

- Open the log for the specific patch run and look for ORA- errors.

**2. Common Culprit - Space or State Issues:**

- Tablespace Full: The SYSAUX or SYSTEM tablespace might have run out of space while applying the patch.

- Database State: The database might not be fully open (e.g., it was started in RESTRICT mode, or if you are using Multitenant, a Pluggable Database might be closed).

**3. How to Recover:**

- Datapatch is Idempotent (Resumable): This is the best part about datapatch. It tracks everything it does in the dba_registry_sqlpatch view.

- If it fails, you fix the underlying issue (e.g., add a datafile to SYSAUX, or open the PDB).

- Then, simply run ./datapatch -verbose again. It will look at what failed, skip what already succeeded, and pick up right where it left off.

A quick tip: Always keep your My Oracle Support (MOS) credentials handy during a patching window.
If you hit an obscure ORA- error in the logs, searching that specific error code plus "19c RU datapatch" on MOS usually yields a quick workaround document.
