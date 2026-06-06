
#!/bin/bash
# =============================================================================
# Script  : rac_info_collector.sh
# Purpose : Collect Oracle RAC cluster information from existing server
#           Covers: OS level, Grid/ASM, Oracle DB, User Environment
# Author  : Generated for RAC Migration Preparation
# Usage   : Run as root, or grid/oracle user (root recommended for full data)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# GLOBAL VARIABLES
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_VERSION="1.0.0"
HOSTNAME=$(hostname -s)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_DIR="/tmp/rac_info_${HOSTNAME}_${TIMESTAMP}"
LOG_FILE="${LOG_DIR}/rac_collector_${HOSTNAME}.log"
SUMMARY_FILE="${LOG_DIR}/summary_${HOSTNAME}.txt"

# Detect users
GRID_USER="grid"
ORACLE_USER="oracle"
CURRENT_USER=$(whoami)

# Colors (for terminal output only)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

init_log() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    touch "${SUMMARY_FILE}"
}

log() {
    echo "$1" | tee -a "${LOG_FILE}"
}

log_only() {
    echo "$1" >> "${LOG_FILE}"
}

section() {
    local title="$1"
    local separator="$(printf '=%.0s' {1..70})"
    log ""
    log "${separator}"
    log ">>> ${title}"
    log "    Captured at: $(date '+%Y-%m-%d %H:%M:%S')"
    log "${separator}"
}

subsection() {
    local title="$1"
    local separator="$(printf -- '-%.0s' {1..60})"
    log ""
    log "${separator}"
    log "  -- ${title}"
    log "${separator}"
}

run_cmd() {
    # run_cmd <description> <command>
    local desc="$1"
    shift
    local cmd="$@"
    log ""
    log "  [CMD] ${desc}"
    log "  \$ ${cmd}"
    log "  Output:"
    eval "${cmd}" 2>&1 | while IFS= read -r line; do log "    ${line}"; done
    log ""
}

run_as_user() {
    # run_as_user <user> <description> <command>
    local user="$1"
    local desc="$2"
    shift 2
    local cmd="$@"

    if id "${user}" &>/dev/null; then
        log ""
        log "  [CMD as ${user}] ${desc}"
        log "  \$ su - ${user} -c \"${cmd}\""
        log "  Output:"
        su - "${user}" -c "${cmd}" 2>&1 | while IFS= read -r line; do log "    ${line}"; done
        log ""
    else
        log "  [SKIP] User '${user}' not found — skipping: ${desc}"
    fi
}

check_binary() {
    local bin="$1"
    if command -v "${bin}" &>/dev/null; then
        echo "$(command -v ${bin})"
    else
        echo "NOT_FOUND"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1: SCRIPT HEADER & ENVIRONMENT CHECK
# ─────────────────────────────────────────────────────────────────────────────

print_header() {
    echo -e "${CYAN}"
    echo "============================================================"
    echo "  Oracle RAC Information Collector v${SCRIPT_VERSION}"
    echo "  Host     : ${HOSTNAME}"
    echo "  Run By   : ${CURRENT_USER}"
    echo "  Start    : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Log Dir  : ${LOG_DIR}"
    echo "============================================================"
    echo -e "${NC}"

    log "============================================================"
    log "  Oracle RAC Information Collector v${SCRIPT_VERSION}"
    log "  Host     : ${HOSTNAME}"
    log "  Run By   : ${CURRENT_USER}"
    log "  Start    : $(date '+%Y-%m-%d %H:%M:%S')"
    log "  Log Dir  : ${LOG_DIR}"
    log "  Log File : ${LOG_FILE}"
    log "============================================================"

    if [ "${CURRENT_USER}" != "root" ]; then
        echo -e "${YELLOW}[WARN] Not running as root. Some sections may be incomplete.${NC}"
        log "[WARN] Not running as root. Some sections may be incomplete."
    else
        echo -e "${GREEN}[OK] Running as root — full data collection enabled.${NC}"
        log "[OK] Running as root — full data collection enabled."
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: OPERATING SYSTEM INFORMATION
# ─────────────────────────────────────────────────────────────────────────────

collect_os_info() {
    section "OS & HARDWARE INFORMATION"

    subsection "OS Release & Kernel"
    run_cmd "OS Release"          "cat /etc/os-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || cat /etc/oracle-release 2>/dev/null"
    run_cmd "Kernel Version"      "uname -r"
    run_cmd "Kernel Full Info"    "uname -a"
    run_cmd "OS Architecture"     "arch"
    run_cmd "System Info (hostnamectl)" "hostnamectl 2>/dev/null"

    subsection "CPU Information"
    run_cmd "CPU Summary"         "lscpu 2>/dev/null"
    run_cmd "CPU Count"           "nproc"
    run_cmd "CPU Details (/proc)" "grep -E '^(processor|model name|cpu MHz|cache size|siblings|cores)' /proc/cpuinfo | sort -u"

    subsection "Memory Information"
    run_cmd "Memory Summary"      "free -h"
    run_cmd "Memory Details"      "cat /proc/meminfo"
    run_cmd "HugePage Config"     "grep -i huge /proc/meminfo"
    run_cmd "HugePage sysctl"     "sysctl -a 2>/dev/null | grep -i huge"

    subsection "Disk & Storage"
    run_cmd "Block Devices"       "lsblk -o NAME,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINT,UUID 2>/dev/null"
    run_cmd "Disk Layout (fdisk)" "fdisk -l 2>/dev/null"
    run_cmd "Filesystem Mounts"   "df -hT"
    run_cmd "Mount Table"         "cat /proc/mounts"
    run_cmd "fstab"               "cat /etc/fstab"
    run_cmd "Multipath Devices"   "multipath -ll 2>/dev/null"
    run_cmd "DM Devices"          "dmsetup ls 2>/dev/null"
    run_cmd "SCSI Devices"        "lsscsi 2>/dev/null"
    run_cmd "Device Mapper"       "ls -la /dev/mapper/ 2>/dev/null"

    subsection "Network Configuration"
    run_cmd "IP Addresses"        "ip addr show"
    run_cmd "Routing Table"       "ip route show"
    run_cmd "Network Interfaces"  "ip link show"
    run_cmd "ifconfig (legacy)"   "ifconfig -a 2>/dev/null"
    run_cmd "/etc/hosts"          "cat /etc/hosts"
    run_cmd "DNS Config"          "cat /etc/resolv.conf"
    run_cmd "Hostname"            "hostname -f 2>/dev/null; hostname -s 2>/dev/null; hostname -i 2>/dev/null"
    run_cmd "bonding config"      "cat /proc/net/bonding/* 2>/dev/null"
    run_cmd "NIC details (ethtool)" "for nic in \$(ip -o link show | awk -F': ' '{print \$2}' | grep -v lo); do echo \"--- \$nic ---\"; ethtool \$nic 2>/dev/null; done"

    subsection "Time & NTP"
    run_cmd "System Date"         "date"
    run_cmd "Timezone"            "timedatectl 2>/dev/null || cat /etc/localtime 2>/dev/null"
    run_cmd "NTP Status (chrony)" "chronyc tracking 2>/dev/null"
    run_cmd "NTP Sources (chrony)" "chronyc sources 2>/dev/null"
    run_cmd "NTP (ntpq)"          "ntpq -pn 2>/dev/null"
    run_cmd "NTP Config"          "cat /etc/chrony.conf 2>/dev/null || cat /etc/ntp.conf 2>/dev/null"

    subsection "Kernel Parameters (sysctl)"
    run_cmd "All sysctl params"   "sysctl -a 2>/dev/null"
    run_cmd "Shared Memory"       "sysctl -a 2>/dev/null | grep -E 'shm|sem|shmmax|shmall|shmmni'"
    run_cmd "Network sysctl"      "sysctl -a 2>/dev/null | grep -E 'net\.(core|ipv4|ipv6)'"

    subsection "Limits & PAM"
    run_cmd "/etc/security/limits.conf" "cat /etc/security/limits.conf"
    run_cmd "limits.d directory"  "ls -la /etc/security/limits.d/ 2>/dev/null; cat /etc/security/limits.d/*.conf 2>/dev/null"
    run_cmd "PAM login config"    "cat /etc/pam.d/login 2>/dev/null"
    run_cmd "grid user limits"    "su - ${GRID_USER} -c 'ulimit -a' 2>/dev/null"
    run_cmd "oracle user limits"  "su - ${ORACLE_USER} -c 'ulimit -a' 2>/dev/null"

    subsection "Running Processes & Services"
    run_cmd "All Processes"       "ps -ef"
    run_cmd "Oracle/Grid Procs"   "ps -ef | grep -E '(oracle|grid|asm|crsd|ocssd|evmd|cssd|gpnpd|mdnsd|diskmon)' | grep -v grep"
    run_cmd "Systemd Services"    "systemctl list-units --type=service --state=running 2>/dev/null"
    run_cmd "Runlevel"            "runlevel 2>/dev/null || systemctl get-default 2>/dev/null"

    subsection "Package & Patch Info"
    run_cmd "Installed RPMs (Oracle/Grid related)" "rpm -qa 2>/dev/null | grep -iE 'oracle|grid|asm|cvuqdisk|oracleasm' | sort"
    run_cmd "Kernel RPMs"         "rpm -qa kernel* 2>/dev/null | sort"
    run_cmd "Installed RPMs (all)" "rpm -qa 2>/dev/null | sort"
    run_cmd "oracleasm module"    "lsmod | grep oracleasm 2>/dev/null"
    run_cmd "oracleasm config"    "oracleasm configure 2>/dev/null"
    run_cmd "oracleasm listdisks" "oracleasm listdisks 2>/dev/null"
    run_cmd "oracleasm scandisks" "oracleasm scandisks 2>/dev/null"

    subsection "Shared Memory Segments"
    run_cmd "ipcs (shared mem)"   "ipcs -m"
    run_cmd "ipcs (semaphores)"   "ipcs -s"
    run_cmd "ipcs (all)"          "ipcs -a"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: USERS & GROUPS
# ─────────────────────────────────────────────────────────────────────────────

collect_users_info() {
    section "USERS & GROUPS"

    subsection "OS Users"
    run_cmd "grid user detail"    "id ${GRID_USER} 2>/dev/null"
    run_cmd "oracle user detail"  "id ${ORACLE_USER} 2>/dev/null"
    run_cmd "/etc/passwd (oracle/grid)" "grep -E '(oracle|grid|oinstall|dba|oper|backupdba|asmdba|asmoper|asmadmin)' /etc/passwd"
    run_cmd "/etc/group (oracle/grid)"  "grep -E '(oracle|grid|oinstall|dba|oper|backupdba|asmdba|asmoper|asmadmin)' /etc/group"
    run_cmd "Full /etc/passwd"    "cat /etc/passwd"
    run_cmd "Full /etc/group"     "cat /etc/group"

    subsection "User UID/GID Summary"
    run_cmd "grid UID/GID"        "id ${GRID_USER} 2>/dev/null"
    run_cmd "oracle UID/GID"      "id ${ORACLE_USER} 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 4: GRID USER ENVIRONMENT
# ─────────────────────────────────────────────────────────────────────────────

collect_grid_env() {
    section "GRID USER ENVIRONMENT"

    if ! id "${GRID_USER}" &>/dev/null; then
        log "[SKIP] User '${GRID_USER}' does not exist on this system."
        return
    fi

    subsection "Grid User Shell Environment"
    run_as_user "${GRID_USER}" "Full Environment Variables" "env | sort"
    run_as_user "${GRID_USER}" "ORACLE_HOME" "echo ORACLE_HOME=\$ORACLE_HOME"
    run_as_user "${GRID_USER}" "ORACLE_BASE" "echo ORACLE_BASE=\$ORACLE_BASE"
    run_as_user "${GRID_USER}" "ORACLE_SID"  "echo ORACLE_SID=\$ORACLE_SID"
    run_as_user "${GRID_USER}" "GRID_HOME"   "echo GRID_HOME=\$ORACLE_HOME"
    run_as_user "${GRID_USER}" "PATH"        "echo PATH=\$PATH"
    run_as_user "${GRID_USER}" "CRS_HOME"    "echo CRS_HOME=\$CRS_HOME"

    subsection "Grid User Profile Files"
    run_cmd "grid .bash_profile"  "cat /home/${GRID_USER}/.bash_profile 2>/dev/null || cat /home/${GRID_USER}/.profile 2>/dev/null"
    run_cmd "grid .bashrc"        "cat /home/${GRID_USER}/.bashrc 2>/dev/null"
    run_cmd "grid .bash_history"  "cat /home/${GRID_USER}/.bash_history 2>/dev/null | tail -100"
    run_cmd "grid home dir"       "ls -la /home/${GRID_USER}/ 2>/dev/null"
    run_cmd "grid .ssh"           "ls -la /home/${GRID_USER}/.ssh/ 2>/dev/null"

    subsection "Grid Home Directory Structure"
    run_as_user "${GRID_USER}" "ORACLE_HOME content" "ls -la \$ORACLE_HOME 2>/dev/null"
    run_as_user "${GRID_USER}" "ORACLE_HOME/bin" "ls -la \$ORACLE_HOME/bin 2>/dev/null"
    run_as_user "${GRID_USER}" "Grid version (opatch)" "\$ORACLE_HOME/OPatch/opatch lsinventory 2>/dev/null"
    run_as_user "${GRID_USER}" "Grid version (crsctl)" "\$ORACLE_HOME/bin/crsctl query crs activeversion 2>/dev/null"
    run_as_user "${GRID_USER}" "Grid version (crsctl softwareversion)" "\$ORACLE_HOME/bin/crsctl query crs softwareversion 2>/dev/null"

    subsection "oraInst.loc & inventory"
    run_cmd "oraInst.loc"         "cat /etc/oraInst.loc 2>/dev/null"
    run_as_user "${GRID_USER}" "Inventory contents" "cat \$(cat /etc/oraInst.loc 2>/dev/null | grep inventory_loc | cut -d= -f2)/ContentsXML/inventory.xml 2>/dev/null"

    subsection "oratab"
    run_cmd "oratab"              "cat /etc/oratab 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 5: ORACLE USER ENVIRONMENT
# ─────────────────────────────────────────────────────────────────────────────

collect_oracle_env() {
    section "ORACLE USER ENVIRONMENT"

    if ! id "${ORACLE_USER}" &>/dev/null; then
        log "[SKIP] User '${ORACLE_USER}' does not exist on this system."
        return
    fi

    subsection "Oracle User Shell Environment"
    run_as_user "${ORACLE_USER}" "Full Environment Variables" "env | sort"
    run_as_user "${ORACLE_USER}" "ORACLE_HOME" "echo ORACLE_HOME=\$ORACLE_HOME"
    run_as_user "${ORACLE_USER}" "ORACLE_BASE" "echo ORACLE_BASE=\$ORACLE_BASE"
    run_as_user "${ORACLE_USER}" "ORACLE_SID"  "echo ORACLE_SID=\$ORACLE_SID"
    run_as_user "${ORACLE_USER}" "PATH"        "echo PATH=\$PATH"
    run_as_user "${ORACLE_USER}" "TNS_ADMIN"   "echo TNS_ADMIN=\$TNS_ADMIN"
    run_as_user "${ORACLE_USER}" "NLS_LANG"    "echo NLS_LANG=\$NLS_LANG"
    run_as_user "${ORACLE_USER}" "NLS_DATE_FORMAT" "echo NLS_DATE_FORMAT=\$NLS_DATE_FORMAT"

    subsection "Oracle User Profile Files"
    run_cmd "oracle .bash_profile" "cat /home/${ORACLE_USER}/.bash_profile 2>/dev/null || cat /home/${ORACLE_USER}/.profile 2>/dev/null"
    run_cmd "oracle .bashrc"       "cat /home/${ORACLE_USER}/.bashrc 2>/dev/null"
    run_cmd "oracle .bash_history" "cat /home/${ORACLE_USER}/.bash_history 2>/dev/null | tail -100"
    run_cmd "oracle home dir"      "ls -la /home/${ORACLE_USER}/ 2>/dev/null"
    run_cmd "oracle .ssh"          "ls -la /home/${ORACLE_USER}/.ssh/ 2>/dev/null"

    subsection "Oracle Home Version & Inventory"
    run_as_user "${ORACLE_USER}" "ORACLE_HOME content" "ls -la \$ORACLE_HOME 2>/dev/null"
    run_as_user "${ORACLE_USER}" "opatch lsinventory" "\$ORACLE_HOME/OPatch/opatch lsinventory 2>/dev/null"
    run_as_user "${ORACLE_USER}" "Oracle version (sqlplus)" "\$ORACLE_HOME/bin/sqlplus -v 2>/dev/null"

    subsection "TNS & Network Config"
    run_as_user "${ORACLE_USER}" "tnsnames.ora location" "find \$ORACLE_HOME /home/${ORACLE_USER} /etc -name tnsnames.ora 2>/dev/null"
    run_as_user "${ORACLE_USER}" "tnsnames.ora content" "cat \$ORACLE_HOME/network/admin/tnsnames.ora 2>/dev/null"
    run_as_user "${ORACLE_USER}" "listener.ora content" "cat \$ORACLE_HOME/network/admin/listener.ora 2>/dev/null"
    run_as_user "${ORACLE_USER}" "sqlnet.ora content"   "cat \$ORACLE_HOME/network/admin/sqlnet.ora 2>/dev/null"
    run_as_user "${GRID_USER}"   "Grid tnsnames.ora"    "cat \$ORACLE_HOME/network/admin/tnsnames.ora 2>/dev/null"
    run_as_user "${GRID_USER}"   "Grid listener.ora"    "cat \$ORACLE_HOME/network/admin/listener.ora 2>/dev/null"
    run_as_user "${GRID_USER}"   "Grid sqlnet.ora"      "cat \$ORACLE_HOME/network/admin/sqlnet.ora 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 6: ORACLE CLUSTERWARE (CRS/GI)
# ─────────────────────────────────────────────────────────────────────────────

collect_cluster_info() {
    section "ORACLE CLUSTERWARE (CRS / GRID INFRASTRUCTURE)"

    subsection "Cluster Status"
    run_as_user "${GRID_USER}" "CRS status (crsctl)"  "\$ORACLE_HOME/bin/crsctl stat res -t 2>/dev/null"
    run_as_user "${GRID_USER}" "CRS status (full)"    "\$ORACLE_HOME/bin/crsctl stat res -t -init 2>/dev/null"
    run_as_user "${GRID_USER}" "CRS check cluster"    "\$ORACLE_HOME/bin/crsctl check cluster -all 2>/dev/null"
    run_as_user "${GRID_USER}" "CRS check CRS"        "\$ORACLE_HOME/bin/crsctl check crs 2>/dev/null"
    run_as_user "${GRID_USER}" "CRS check has"        "\$ORACLE_HOME/bin/crsctl check has 2>/dev/null"

    subsection "Cluster Nodes"
    run_as_user "${GRID_USER}" "OLR config"           "olsnodes -n -i -s -t 2>/dev/null || \$ORACLE_HOME/bin/olsnodes -n -i -s -t 2>/dev/null"
    run_as_user "${GRID_USER}" "Cluster nodes"        "\$ORACLE_HOME/bin/olsnodes 2>/dev/null"
    run_as_user "${GRID_USER}" "Local node number"    "\$ORACLE_HOME/bin/olsnodes -l -n 2>/dev/null"
    run_as_user "${GRID_USER}" "cluvfy nodereach"     "\$ORACLE_HOME/bin/cluvfy comp nodereach -n all 2>/dev/null"

    subsection "Cluster Name & Config"
    run_as_user "${GRID_USER}" "Cluster name"         "\$ORACLE_HOME/bin/cemutlo -n 2>/dev/null"
    run_as_user "${GRID_USER}" "Cluster config (crsctl)" "\$ORACLE_HOME/bin/crsctl get css misscount 2>/dev/null; \$ORACLE_HOME/bin/crsctl get css disktimeout 2>/dev/null"
    run_as_user "${GRID_USER}" "GPNP profile"         "cat /u01/app/*/grid/gpnp/*/profiles/peer/profile.xml 2>/dev/null || find / -name 'profile.xml' -path '*/gpnp/*' 2>/dev/null | xargs cat"

    subsection "CRS Resources"
    run_as_user "${GRID_USER}" "All CRS resources"    "\$ORACLE_HOME/bin/crsctl stat res -p 2>/dev/null"
    run_as_user "${GRID_USER}" "DB resources"         "\$ORACLE_HOME/bin/srvctl config database 2>/dev/null"
    run_as_user "${GRID_USER}" "srvctl status db"     "\$ORACLE_HOME/bin/srvctl status database -d \$(srvctl config database 2>/dev/null | head -1) 2>/dev/null"

    subsection "VIP & SCAN Configuration"
    run_as_user "${GRID_USER}" "SCAN config"          "\$ORACLE_HOME/bin/srvctl config scan 2>/dev/null"
    run_as_user "${GRID_USER}" "SCAN listener"        "\$ORACLE_HOME/bin/srvctl config scan_listener 2>/dev/null"
    run_as_user "${GRID_USER}" "SCAN status"          "\$ORACLE_HOME/bin/srvctl status scan 2>/dev/null"
    run_as_user "${GRID_USER}" "SCAN listener status" "\$ORACLE_HOME/bin/srvctl status scan_listener 2>/dev/null"
    run_as_user "${GRID_USER}" "VIP config"           "\$ORACLE_HOME/bin/srvctl config vip -n \$(hostname -s) 2>/dev/null"
    run_as_user "${GRID_USER}" "VIP status"           "\$ORACLE_HOME/bin/srvctl status vip -n \$(hostname -s) 2>/dev/null"
    run_as_user "${GRID_USER}" "Nodeapps config"      "\$ORACLE_HOME/bin/srvctl config nodeapps 2>/dev/null"
    run_as_user "${GRID_USER}" "Nodeapps status"      "\$ORACLE_HOME/bin/srvctl status nodeapps 2>/dev/null"

    subsection "Listener Configuration"
    run_as_user "${GRID_USER}" "Grid listener status" "\$ORACLE_HOME/bin/lsnrctl status 2>/dev/null"
    run_as_user "${GRID_USER}" "Grid listener services" "\$ORACLE_HOME/bin/lsnrctl services 2>/dev/null"
    run_as_user "${ORACLE_USER}" "Oracle listener status" "\$ORACLE_HOME/bin/lsnrctl status 2>/dev/null"
    run_as_user "${ORACLE_USER}" "Oracle listener services" "\$ORACLE_HOME/bin/lsnrctl services 2>/dev/null"

    subsection "OLR (Oracle Local Registry)"
    run_as_user "${GRID_USER}" "OLR info"             "ocrcheck -local 2>/dev/null || \$ORACLE_HOME/bin/ocrcheck -local 2>/dev/null"
    run_cmd "OLR file location"   "cat /etc/oracle/olr.loc 2>/dev/null"

    subsection "OCR (Oracle Cluster Registry)"
    run_as_user "${GRID_USER}" "OCR check"            "\$ORACLE_HOME/bin/ocrcheck 2>/dev/null"
    run_as_user "${GRID_USER}" "OCR config"           "\$ORACLE_HOME/bin/ocrconfig -showbackup 2>/dev/null"
    run_as_user "${GRID_USER}" "OCR backup info"      "\$ORACLE_HOME/bin/ocrconfig -backuploc 2>/dev/null"

    subsection "Voting Disk"
    run_as_user "${GRID_USER}" "Voting disk list"     "\$ORACLE_HOME/bin/crsctl query css votedisk 2>/dev/null"

    subsection "Interconnect"
    run_as_user "${GRID_USER}" "Cluster interconnect" "\$ORACLE_HOME/bin/oifcfg getif 2>/dev/null"
    run_as_user "${GRID_USER}" "oifcfg iflist"        "\$ORACLE_HOME/bin/oifcfg iflist 2>/dev/null"
    run_as_user "${GRID_USER}" "Cluster interconnect IP" "\$ORACLE_HOME/bin/oifcfg getif -type cluster_interconnect 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 7: ASM INFORMATION
# ─────────────────────────────────────────────────────────────────────────────

collect_asm_info() {
    section "ASM (AUTOMATIC STORAGE MANAGEMENT)"

    subsection "ASM Instance Status"
    run_as_user "${GRID_USER}" "ASM processes"        "ps -ef | grep pmon | grep -i asm | grep -v grep"
    run_as_user "${GRID_USER}" "ASM SID"              "echo \$ORACLE_SID"

    # Detect ASM SID
    local ASM_SID
    ASM_SID=$(ps -ef 2>/dev/null | grep 'asm_pmon' | grep -v grep | awk -F'asm_pmon_' '{print $2}' | head -1)
    if [ -z "${ASM_SID}" ]; then
        ASM_SID="+ASM"
    fi
    log "  [INFO] Detected ASM SID: ${ASM_SID}"

    subsection "ASM Configuration (via sqlplus)"
    local ASM_QUERIES=(
        "set lines 200 pages 200;
         col name for a30;
         col path for a50;
         select instance_name, status, database_status from v\$instance;"

        "set lines 200 pages 200;
         col name for a30;
         select name, state, type, total_mb, free_mb,
                round((total_mb - free_mb)/total_mb*100,2) as used_pct
         from v\$asm_diskgroup order by name;"

        "set lines 200 pages 200;
         col path for a60;
         col name for a30;
         col failgroup for a20;
         select group_number, disk_number, name, path, failgroup,
                total_mb, free_mb, state, mode_status
         from v\$asm_disk order by group_number, disk_number;"

        "set lines 200 pages 200;
         col name for a60;
         col type for a15;
         select group_number, file_number, round(bytes/1024/1024,2) as MB,
                round(space/1024/1024,2) as SPACE_MB, type, incarnation
         from v\$asm_file order by group_number, file_number;"

        "set lines 200 pages 200;
         col compatibility for a20;
         col database_compatibility for a30;
         select name, compatibility, database_compatibility, voting_files
         from v\$asm_diskgroup;"

        "select * from v\$asm_attribute where group_number > 0 order by group_number, name;"

        "col redundancy for a15;
         select dg.name, cl.name as client_name, cl.db_name, cl.status
         from v\$asm_diskgroup dg, v\$asm_client cl
         where dg.group_number = cl.group_number;"

        "select operation, state, power, actual, sofar, est_work, est_rate, est_minutes
         from v\$asm_operation;"
    )

    for query in "${ASM_QUERIES[@]}"; do
        local first_line
        first_line=$(echo "${query}" | grep -v "^set\|^col\|^$" | head -1 | sed 's/;//')
        run_as_user "${GRID_USER}" "ASM Query: ${first_line:0:60}" \
            "echo \"${query}\" | \$ORACLE_HOME/bin/sqlplus -s / as sysasm"
    done

    subsection "ASM Alert Log"
    run_as_user "${GRID_USER}" "ASM alert log location" "find /u01 /u02 /opt/oracle -name 'alert_*.log' 2>/dev/null | grep -i asm | head -5"
    run_as_user "${GRID_USER}" "ASM alert log (last 200 lines)" \
        "find \$ORACLE_BASE/diag/asm -name 'alert*.log' 2>/dev/null | head -1 | xargs tail -200 2>/dev/null"

    subsection "ASM SPFILE & Parameters"
    run_as_user "${GRID_USER}" "ASM SPFILE location" \
        "echo \"show parameter spfile;\" | \$ORACLE_HOME/bin/sqlplus -s / as sysasm 2>/dev/null"
    run_as_user "${GRID_USER}" "ASM all parameters" \
        "echo \"col name for a40; col value for a60; select name,value,description from v\\\$asm_attribute;\" | \$ORACLE_HOME/bin/sqlplus -s / as sysasm 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 8: ORACLE DATABASE INSTANCES
# ─────────────────────────────────────────────────────────────────────────────

collect_db_info() {
    section "ORACLE DATABASE INSTANCES"

    subsection "Detect Running Instances"
    run_cmd "DB PMON processes" "ps -ef | grep pmon | grep -v asm | grep -v grep"

    # Detect all DB SIDs (non-ASM)
    local DB_SIDS
    DB_SIDS=$(ps -ef 2>/dev/null | grep 'ora_pmon' | grep -v grep | awk -F'ora_pmon_' '{print $2}')
    if [ -z "${DB_SIDS}" ]; then
        log "  [INFO] No Oracle DB instances detected via pmon. Trying oratab..."
        DB_SIDS=$(grep -v '^#\|^$' /etc/oratab 2>/dev/null | grep -v '\+ASM' | awk -F: '{print $1}')
    fi
    log "  [INFO] Detected DB SIDs: ${DB_SIDS}"

    for SID in ${DB_SIDS}; do
        section "DATABASE: ${SID}"

        # Get ORACLE_HOME from oratab
        local OH
        OH=$(grep "^${SID}:" /etc/oratab 2>/dev/null | awk -F: '{print $2}')
        log "  [INFO] ORACLE_HOME for ${SID}: ${OH}"

        subsection "${SID} — Instance & Database Info"

        local DB_QUERIES=(
            "set lines 200 pages 200;
             select instance_number, instance_name, host_name, version,
                    startup_time, status, database_status, instance_role
             from v\$instance;"

            "set lines 200 pages 200;
             select name, db_unique_name, dbid, log_mode, open_mode,
                    protection_mode, database_role, platform_name, created
             from v\$database;"

            "set lines 200 pages 200;
             col name for a30; col value for a80;
             select name, value from v\$parameter where value is not null order by name;"

            "set lines 200 pages 200;
             col name for a30; col value for a80;
             select name, value, isdefault, ismodified from v\$parameter2
             where isdefault='FALSE' order by name;"

            "set lines 200 pages 200;
             col tablespace_name for a30;
             col file_name for a80;
             select tablespace_name, file_name, bytes/1024/1024 as MB,
                    autoextensible, maxbytes/1024/1024 as MAX_MB
             from dba_data_files order by tablespace_name;"

            "set lines 200 pages 200;
             col tablespace_name for a30;
             select tablespace_name, sum(bytes)/1024/1024 as TOTAL_MB,
                    max_size/1024/1024 as MAX_MB, status
             from dba_tablespaces group by tablespace_name, status, max_size
             order by tablespace_name;"

            "set lines 200 pages 200;
             col member for a80;
             select l.group#, l.members, l.bytes/1024/1024 as MB,
                    l.status, l.archived, lm.member
             from v\$log l, v\$logfile lm
             where l.group# = lm.group# order by l.group#;"

            "set lines 200 pages 200;
             col name for a30; col value for a60;
             select name, value from v\$spparameter
             where isspecified = 'TRUE' order by name;"

            "set lines 200 pages 200;
             select inst_id, instance_number, instance_name, host_name,
                    status, database_status from gv\$instance;"

            "set lines 200 pages 200;
             select username, account_status, default_tablespace,
                    temporary_tablespace, profile, created
             from dba_users order by username;"

            "set lines 200 pages 200;
             col profile for a20; col resource_name for a30; col limit for a20;
             select profile, resource_name, limit from dba_profiles order by profile, resource_name;"

            "set lines 200 pages 200;
             select * from dba_scheduler_jobs where enabled = 'TRUE';"

            "set lines 200 pages 200;
             col name for a30; col value for a60;
             select name, value from nls_database_parameters order by name;"

            "set lines 200 pages 200;
             select banner from v\$version;"
        )

        for query in "${DB_QUERIES[@]}"; do
            local first_line
            first_line=$(echo "${query}" | grep -v "^set\|^col\|^$" | head -1 | sed 's/;//')
            run_as_user "${ORACLE_USER}" "DB[${SID}]: ${first_line:0:60}" \
                "export ORACLE_SID=${SID}; export ORACLE_HOME=${OH}; echo \"${query}\" | ${OH}/bin/sqlplus -s / as sysdba 2>/dev/null"
        done

        subsection "${SID} — SPFILE Location"
        run_as_user "${ORACLE_USER}" "SPFILE path" \
            "export ORACLE_SID=${SID}; export ORACLE_HOME=${OH}; echo \"show parameter spfile;\" | ${OH}/bin/sqlplus -s / as sysdba 2>/dev/null"

        subsection "${SID} — Control Files"
        run_as_user "${ORACLE_USER}" "Control files" \
            "export ORACLE_SID=${SID}; export ORACLE_HOME=${OH}; echo \"select name from v\\\$controlfile;\" | ${OH}/bin/sqlplus -s / as sysdba 2>/dev/null"

        subsection "${SID} — srvctl Config"
        run_as_user "${ORACLE_USER}" "srvctl config db" \
            "export ORACLE_HOME=${OH}; ${OH}/bin/srvctl config database -d ${SID} 2>/dev/null"
        run_as_user "${ORACLE_USER}" "srvctl config instance" \
            "export ORACLE_HOME=${OH}; ${OH}/bin/srvctl config instance -d ${SID} 2>/dev/null"
        run_as_user "${ORACLE_USER}" "srvctl status db" \
            "export ORACLE_HOME=${OH}; ${OH}/bin/srvctl status database -d ${SID} 2>/dev/null"
        run_as_user "${ORACLE_USER}" "srvctl config service" \
            "export ORACLE_HOME=${OH}; ${OH}/bin/srvctl config service -d ${SID} 2>/dev/null"
        run_as_user "${ORACLE_USER}" "srvctl status service" \
            "export ORACLE_HOME=${OH}; ${OH}/bin/srvctl status service -d ${SID} 2>/dev/null"

        subsection "${SID} — Alert Log"
        run_as_user "${ORACLE_USER}" "Alert log location" \
            "export ORACLE_SID=${SID}; export ORACLE_HOME=${OH}; echo \"select value from v\\\$diag_info where name='Diag Trace';\" | ${OH}/bin/sqlplus -s / as sysdba 2>/dev/null"
        run_as_user "${ORACLE_USER}" "Alert log (last 200 lines)" \
            "export ORACLE_SID=${SID}; find ${OH}/../../diag/rdbms -name 'alert_${SID}*.log' 2>/dev/null | head -1 | xargs tail -200 2>/dev/null"
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 9: FILE SYSTEM & ORACLE BASE STRUCTURE
# ─────────────────────────────────────────────────────────────────────────────

collect_filesystem_info() {
    section "ORACLE DIRECTORY STRUCTURE"

    subsection "Common Oracle Directories"
    local DIRS=("/u01" "/u02" "/u03" "/opt/oracle" "/oracle" "/app/oracle" "/home/grid" "/home/oracle")
    for d in "${DIRS[@]}"; do
        if [ -d "${d}" ]; then
            run_cmd "Directory: ${d}" "find ${d} -maxdepth 3 -type d 2>/dev/null | sort"
        fi
    done

    run_as_user "${GRID_USER}" "ORACLE_BASE dir" "ls -la \$ORACLE_BASE/ 2>/dev/null"
    run_as_user "${ORACLE_USER}" "ORACLE_BASE dir" "ls -la \$ORACLE_BASE/ 2>/dev/null"

    subsection "Oracle Admin Directory"
    run_as_user "${ORACLE_USER}" "admin dir structure" "find \$ORACLE_BASE/admin -maxdepth 4 2>/dev/null | sort"

    subsection "Oracle diag Directory"
    run_as_user "${ORACLE_USER}" "diag dir structure" "find \$ORACLE_BASE/diag -maxdepth 4 2>/dev/null | sort | head -100"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 10: SECURITY & SSH
# ─────────────────────────────────────────────────────────────────────────────

collect_security_info() {
    section "SECURITY & SSH CONFIGURATION"

    subsection "SSH Keys"
    run_cmd "grid known_hosts"    "cat /home/${GRID_USER}/.ssh/known_hosts 2>/dev/null"
    run_cmd "grid authorized_keys" "cat /home/${GRID_USER}/.ssh/authorized_keys 2>/dev/null"
    run_cmd "oracle known_hosts"  "cat /home/${ORACLE_USER}/.ssh/known_hosts 2>/dev/null"
    run_cmd "oracle authorized_keys" "cat /home/${ORACLE_USER}/.ssh/authorized_keys 2>/dev/null"
    run_cmd "SSH server config"   "cat /etc/ssh/sshd_config 2>/dev/null"

    subsection "Sudoers"
    run_cmd "/etc/sudoers"        "cat /etc/sudoers 2>/dev/null"
    run_cmd "sudoers.d/"          "ls -la /etc/sudoers.d/ 2>/dev/null; cat /etc/sudoers.d/* 2>/dev/null"

    subsection "SELinux / Firewall"
    run_cmd "SELinux status"      "getenforce 2>/dev/null; sestatus 2>/dev/null"
    run_cmd "Firewall status"     "firewall-cmd --state 2>/dev/null; iptables -L -n 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 11: CRON JOBS
# ─────────────────────────────────────────────────────────────────────────────

collect_cron_info() {
    section "CRON JOBS"

    run_cmd "root crontab"        "crontab -l -u root 2>/dev/null"
    run_cmd "grid crontab"        "crontab -l -u ${GRID_USER} 2>/dev/null"
    run_cmd "oracle crontab"      "crontab -l -u ${ORACLE_USER} 2>/dev/null"
    run_cmd "/etc/crontab"        "cat /etc/crontab 2>/dev/null"
    run_cmd "cron.d directory"    "ls -la /etc/cron.d/ 2>/dev/null; cat /etc/cron.d/* 2>/dev/null"
    run_cmd "cron.daily"          "ls -la /etc/cron.daily/ 2>/dev/null"
    run_cmd "cron.weekly"         "ls -la /etc/cron.weekly/ 2>/dev/null"
}

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 12: GENERATE SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

generate_summary() {
    section "GENERATING SUMMARY REPORT"

    {
        echo "========================================================"
        echo "  Oracle RAC Info Collector — SUMMARY"
        echo "  Host     : ${HOSTNAME}"
        echo "  Run By   : ${CURRENT_USER}"
        echo "  Date     : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================================"
        echo ""

        echo "--- OS ---"
        cat /etc/os-release 2>/dev/null | grep -E '^(NAME|VERSION)=' || cat /etc/redhat-release 2>/dev/null
        echo "Kernel: $(uname -r)"
        echo "Arch: $(arch)"
        echo ""

        echo "--- CPU & Memory ---"
        echo "CPUs: $(nproc)"
        echo "Memory:"
        free -h | grep Mem
        echo ""

        echo "--- Grid User ---"
        id ${GRID_USER} 2>/dev/null
        su - ${GRID_USER} -c "echo ORACLE_HOME=\$ORACLE_HOME; echo ORACLE_BASE=\$ORACLE_BASE; echo ORACLE_SID=\$ORACLE_SID" 2>/dev/null
        su - ${GRID_USER} -c "\$ORACLE_HOME/bin/crsctl query crs activeversion 2>/dev/null"
        echo ""

        echo "--- Oracle User ---"
        id ${ORACLE_USER} 2>/dev/null
        su - ${ORACLE_USER} -c "echo ORACLE_HOME=\$ORACLE_HOME; echo ORACLE_BASE=\$ORACLE_BASE; echo ORACLE_SID=\$ORACLE_SID" 2>/dev/null
        echo ""

        echo "--- Cluster Nodes ---"
        su - ${GRID_USER} -c "\$ORACLE_HOME/bin/olsnodes -n -i -s -t 2>/dev/null"
        echo ""

        echo "--- ASM Disk Groups ---"
        local ASM_SID
        ASM_SID=$(ps -ef 2>/dev/null | grep 'asm_pmon' | grep -v grep | awk -F'asm_pmon_' '{print $2}' | head -1)
        su - ${GRID_USER} -c "echo 'select name,state,type,total_mb,free_mb from v\$asm_diskgroup;' | \$ORACLE_HOME/bin/sqlplus -s / as sysasm 2>/dev/null"
        echo ""

        echo "--- Database Instances ---"
        ps -ef | grep ora_pmon | grep -v grep
        echo ""

        echo "--- Log File ---"
        echo "${LOG_FILE}"

    } | tee "${SUMMARY_FILE}"

    log ""
    log "Summary written to: ${SUMMARY_FILE}"
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

main() {
    init_log
    print_header

    echo -e "${BLUE}[1/10] Collecting OS & Hardware info...${NC}"
    collect_os_info

    echo -e "${BLUE}[2/10] Collecting Users & Groups...${NC}"
    collect_users_info

    echo -e "${BLUE}[3/10] Collecting Grid user environment...${NC}"
    collect_grid_env

    echo -e "${BLUE}[4/10] Collecting Oracle user environment...${NC}"
    collect_oracle_env

    echo -e "${BLUE}[5/10] Collecting Clusterware info...${NC}"
    collect_cluster_info

    echo -e "${BLUE}[6/10] Collecting ASM info...${NC}"
    collect_asm_info

    echo -e "${BLUE}[7/10] Collecting Database instances...${NC}"
    collect_db_info

    echo -e "${BLUE}[8/10] Collecting Filesystem structure...${NC}"
    collect_filesystem_info

    echo -e "${BLUE}[9/10] Collecting Security & Cron info...${NC}"
    collect_security_info
    collect_cron_info

    echo -e "${BLUE}[10/10] Generating Summary...${NC}"
    generate_summary

    # Final log entry
    section "COLLECTION COMPLETE"
    log "End time : $(date '+%Y-%m-%d %H:%M:%S')"
    log "Log file : ${LOG_FILE}"
    log "Summary  : ${SUMMARY_FILE}"
    log "Log Dir  : ${LOG_DIR}"

    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}  Collection COMPLETE!${NC}"
    echo -e "${GREEN}  Log Dir  : ${LOG_DIR}${NC}"
    echo -e "${GREEN}  Main Log : ${LOG_FILE}${NC}"
    echo -e "${GREEN}  Summary  : ${SUMMARY_FILE}${NC}"
    echo -e "${GREEN}============================================================${NC}"

    # Compress output
    echo -e "${YELLOW}Compressing output...${NC}"
    cd /tmp && tar -czf "rac_info_${HOSTNAME}_${TIMESTAMP}.tar.gz" "rac_info_${HOSTNAME}_${TIMESTAMP}/" 2>/dev/null
    echo -e "${GREEN}Archive : /tmp/rac_info_${HOSTNAME}_${TIMESTAMP}.tar.gz${NC}"
}

# Run
main "$@"
