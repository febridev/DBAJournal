#!/usr/bin/env bash
#
# ==============================================================================
# Script Name   : mysql_pre_patch_check.sh
# Description   : Pre-upgrade & health check script for MySQL 8.4.x patch release
#                 Accepts credentials directly via CLI parameters.
# Reference     : https://dev.mysql.com/doc/refman/8.4/en/upgrading.html
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# DEFAULT PARAMETER VALUES
# ------------------------------------------------------------------------------
MYSQL_USER="root"
MYSQL_PASS="Febr11yant!"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
CUSTOM_CONFIG_FILE=""

MIN_FREE_DISK_GB=10
MAX_TRX_TIME_SEC=60

ERRORS=0
WARNINGS=0

# ------------------------------------------------------------------------------
# COLOR DEFINITIONS
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# HELPER & USAGE FUNCTIONS
# ------------------------------------------------------------------------------
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -u USER       MySQL username (Default: root)"
    echo "  -p PASS       MySQL password"
    echo "  -h HOST       MySQL host (Default: localhost)"
    echo "  -P PORT       MySQL port (Default: 3306)"
    echo "  -f FILE       Path to custom .my.cnf file (Overrides -u, -p, -h, -P)"
    echo "  --help        Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -u admin -p 'MySecretPass' -h 127.0.0.1 -P 3306"
    exit 1
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++)) || true
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((ERRORS++)) || true
}

# ------------------------------------------------------------------------------
# PARSE COMMAND-LINE ARGUMENTS
# ------------------------------------------------------------------------------
while getopts "u:p:h:P:f:-:" opt; do
    case "$opt" in
        u) MYSQL_USER="$OPTARG" ;;
        p) MYSQL_PASS="$OPTARG" ;;
        h) MYSQL_HOST="$OPTARG" ;;
        P) MYSQL_PORT="$OPTARG" ;;
        f) CUSTOM_CONFIG_FILE="$OPTARG" ;;
        -)
            case "${OPTARG}" in
                help) usage ;;
                *) echo "Unknown option --${OPTARG}"; usage ;;
            esac ;;
        *) usage ;;
    esac
done

# ------------------------------------------------------------------------------
# CREDENTIAL & TEMP CONFIG PREPARATION
# ------------------------------------------------------------------------------
if [ -n "$CUSTOM_CONFIG_FILE" ]; then
    if [ ! -f "$CUSTOM_CONFIG_FILE" ]; then
        echo -e "${RED}[ERROR] Specified config file '$CUSTOM_CONFIG_FILE' does not exist.${NC}"
        exit 1
    fi
    DEFAULTS_FILE="$CUSTOM_CONFIG_FILE"
else
    # Create a secure temporary configuration file
    TMP_CONFIG=$(mktemp /tmp/mysql_check_XXXXXX.cnf)
    chmod 600 "$TMP_CONFIG"

    # Ensure cleanup on script exit
    trap 'rm -f "$TMP_CONFIG"' EXIT

    # Write credentials into temporary config file
    cat <<EOF > "$TMP_CONFIG"
[client]
user=${MYSQL_USER}
password=${MYSQL_PASS}
host=${MYSQL_HOST}
port=${MYSQL_PORT}
EOF

    DEFAULTS_FILE="$TMP_CONFIG"
fi

run_mysql_query() {
    local query="$1"
    mysql --defaults-file="$DEFAULTS_FILE" -B -N -e "$query" 2>/dev/null
}

# ------------------------------------------------------------------------------
# PRE-CHECK EXECUTION
# ------------------------------------------------------------------------------
echo "======================================================================"
echo "         MySQL 8.4 Patch Release Pre-Upgrade Health Check             "
echo "======================================================================"
echo "Execution Time : $(date)"
echo "Target Host    : ${MYSQL_HOST}:${MYSQL_PORT}"
echo "Target User    : ${MYSQL_USER}"
echo "======================================================================"
echo ""

# 1. Check MySQL Connectivity
log_info "1. Checking MySQL server connectivity..."
if ! mysqladmin --defaults-file="$DEFAULTS_FILE" ping --silent; then
    log_fail "Cannot connect to MySQL server. Check credentials, host, and port."
    exit 1
else
    log_pass "Successfully connected to MySQL server."
fi

# 2. Check Current MySQL Version
log_info "2. Validating MySQL Version..."
CURRENT_VERSION=$(run_mysql_query "SELECT VERSION();")
echo "   Detected Version: $CURRENT_VERSION"

if [[ "$CURRENT_VERSION" =~ ^8\.4\. ]]; then
    log_pass "MySQL version belongs to 8.4 LTS release series."
else
    log_warn "Current version ($CURRENT_VERSION) is not in 8.4 series. Major upgrade rules may apply!"
fi

# 3. Check Free Disk Space on Data Directory
log_info "3. Checking Free Disk Space on Data Directory..."
DATADIR=$(run_mysql_query "SELECT @@datadir;")
echo "   Data Directory: $DATADIR"

if [ -d "$DATADIR" ]; then
    AVAILABLE_KB=$(df -P "$DATADIR" | tail -1 | awk '{print $4}')
    AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))
    echo "   Available Space: ${AVAILABLE_GB} GB"

    if [ "$AVAILABLE_GB" -lt "$MIN_FREE_DISK_GB" ]; then
        log_warn "Free disk space (${AVAILABLE_GB} GB) is below recommended threshold (${MIN_FREE_DISK_GB} GB)."
    else
        log_pass "Sufficient disk space available."
    fi
else
    log_fail "Data directory '$DATADIR' does not exist or is not accessible locally."
fi

# 4. Check Long-Running / Uncommitted Transactions
log_info "4. Checking for Long-Running Transactions (> ${MAX_TRX_TIME_SEC}s)..."
LONG_TRX_COUNT=$(run_mysql_query "
    SELECT COUNT(*) 
    FROM information_schema.innodb_trx 
    WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > ${MAX_TRX_TIME_SEC};
")

if [ "$LONG_TRX_COUNT" -gt 0 ]; then
    log_warn "Found $LONG_TRX_COUNT long-running transaction(s). Consider terminating them before shutdown."
else
    log_pass "No long-running transactions found."
fi

# 5. Check InnoDB Dirty Pages Status
log_info "5. Checking InnoDB Dirty Pages..."
DIRTY_PAGES=$(run_mysql_query "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_pages_dirty';" | awk '{print $2}')
TOTAL_PAGES=$(run_mysql_query "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_pages_total';" | awk '{print $2}')

if [ -n "$TOTAL_PAGES" ] && [ "$TOTAL_PAGES" -gt 0 ]; then
    DIRTY_PCT=$(( (DIRTY_PAGES * 100) / TOTAL_PAGES ))
    echo "   Dirty Pages Ratio: ${DIRTY_PCT}% ($DIRTY_PAGES / $TOTAL_PAGES)"
    
    if [ "$DIRTY_PCT" -gt 20 ]; then
        log_warn "High percentage of dirty pages (${DIRTY_PCT}%). Ensure clean shutdown."
    else
        log_pass "Dirty pages ratio is within safe limits."
    fi
fi

# 6. Check Fast Shutdown Parameter Setting
log_info "6. Checking innodb_fast_shutdown parameter..."
FAST_SHUTDOWN=$(run_mysql_query "SELECT @@innodb_fast_shutdown;")
echo "   Current innodb_fast_shutdown setting: $FAST_SHUTDOWN"

if [ "$FAST_SHUTDOWN" -eq 2 ]; then
    log_warn "innodb_fast_shutdown is set to 2 (CRASH SHUTDOWN mode). Change it to 0 or 1 before patching!"
else
    log_pass "innodb_fast_shutdown setting is acceptable ($FAST_SHUTDOWN)."
fi

# 7. Check Replication Status (if configured as Replica)
log_info "7. Checking MySQL Replica Status..."
IS_REPLICA=$(run_mysql_query "SHOW REPLICA STATUS\G" || true)

if [ -n "$IS_REPLICA" ]; then
    IO_RUNNING=$(echo "$IS_REPLICA" | grep -i "Replica_IO_Running:" | awk '{print $2}')
    SQL_RUNNING=$(echo "$IS_REPLICA" | grep -i "Replica_SQL_Running:" | awk '{print $2}')
    BEHIND=$(echo "$IS_REPLICA" | grep -i "Seconds_Behind_Master:" | awk '{print $2}')

    echo "   Replica IO Running  : $IO_RUNNING"
    echo "   Replica SQL Running : $SQL_RUNNING"
    echo "   Seconds Behind Source: $BEHIND"

    if [ "$IO_RUNNING" == "Yes" ] && [ "$SQL_RUNNING" == "Yes" ]; then
        if [ "$BEHIND" != "NULL" ] && [ "$BEHIND" -gt 0 ]; then
            log_warn "Replication lag detected ($BEHIND seconds). Wait for sync before patching."
        else
            log_pass "Replication threads are running normally with no lag."
        fi
    else
        log_warn "One or more replication threads are not running."
    fi
else
    log_info "Server is not configured as a Replica (or SHOW REPLICA STATUS is empty)."
fi

# 8. Run mysqlcheck Upgrade Compatibility Verification
log_info "8. Running mysqlcheck upgrade verification (this may take a moment)..."
CHECK_OUTPUT=$(mysqlcheck --defaults-file="$DEFAULTS_FILE" --all-databases --check-upgrade 2>&1 || true)

if echo "$CHECK_OUTPUT" | grep -iq "error"; then
    log_fail "Table/View upgrade check encountered errors!"
    echo "$CHECK_OUTPUT" | grep -i "error"
else
    log_pass "All tables and views passed upgrade check."
fi

# ------------------------------------------------------------------------------
# SUMMARY & CONCLUSION
# ------------------------------------------------------------------------------
echo ""
echo "======================================================================"
echo "                       PRE-CHECK SUMMARY                              "
echo "======================================================================"
echo -e "Total Errors   : ${RED}${ERRORS}${NC}"
echo -e "Total Warnings : ${YELLOW}${WARNINGS}${NC}"
echo "======================================================================"

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}STATUS: READY FOR PATCHING.${NC}"
    exit 0
else
    echo -e "${RED}STATUS: NOT READY. Please resolve the errors above before patching.${NC}"
    exit 1
fi
