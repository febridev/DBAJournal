#!/bin/bash

# ==============================================================================
# Script Name   : verify_grid_asm.sh
# Description   : Automated verification script for Oracle Grid Infrastructure 
#                 and ASM installation.
# Parameters    : <HOSTNAME_1> <HOSTNAME_2> <INSTALL_TYPE (rac|standalone)>
# ==============================================================================

# Define variables
LOG_DIR="/tmp"
LOG_FILE="${LOG_DIR}/grid_verify_$(date +%Y%m%d_%H%M%S).log"

# Function to write logs
log_msg() {
    local MSG_TYPE=$1
    local MSG_TEXT=$2
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${TIMESTAMP}] [${MSG_TYPE}] : ${MSG_TEXT}" | tee -a "${LOG_FILE}"
}

# Check if required number of parameters are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <HOSTNAME_1> <HOSTNAME_2> <INSTALL_TYPE (rac|standalone)>"
    echo "Example: $0 node1.localdomain node2.localdomain rac"
    exit 1
fi

NODE1=$1
NODE2=$2
INSTALL_TYPE=$(echo "$3" | tr '[:upper:]' '[:lower:]')

log_msg "INFO" "Starting Grid Infrastructure and ASM Verification..."
log_msg "INFO" "Node 1: ${NODE1}"
log_msg "INFO" "Node 2: ${NODE2}"
log_msg "INFO" "Installation Type: ${INSTALL_TYPE}"
log_msg "INFO" "Log file is located at: ${LOG_FILE}"

# Verify if ORACLE_HOME is set
if [ -z "${ORACLE_HOME}" ]; then
    log_msg "ERROR" "ORACLE_HOME environment variable is not set. Please source your grid environment profile."
    exit 1
fi
log_msg "INFO" "ORACLE_HOME is set to: ${ORACLE_HOME}"

# Initialize error counter
ERROR_COUNT=0

# Function to check Grid/Clusterware status
check_crs_status() {
    log_msg "INFO" "--- Checking Clusterware / HAS Status ---"
    
    if [ "${INSTALL_TYPE}" == "rac" ]; then
        log_msg "INFO" "Checking Oracle Clusterware status for RAC..."
        ${ORACLE_HOME}/bin/crsctl check cluster -all | tee -a "${LOG_FILE}"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then ((ERROR_COUNT++)); fi
        
        # Check remote node connectivity via SSH (Requires Passwordless SSH)
        log_msg "INFO" "Checking SSH connectivity to Node 2 (${NODE2})..."
        ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${NODE2}" "echo 'SSH to ${NODE2} is successful'" | tee -a "${LOG_FILE}"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            log_msg "WARNING" "Passwordless SSH to ${NODE2} might not be configured or node is unreachable."
            ((ERROR_COUNT++))
        fi

    elif [ "${INSTALL_TYPE}" == "standalone" ]; then
        log_msg "INFO" "Checking Oracle High Availability Services (HAS) status for Standalone..."
        ${ORACLE_HOME}/bin/crsctl check has | tee -a "${LOG_FILE}"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then ((ERROR_COUNT++)); fi
    else
        log_msg "ERROR" "Unknown installation type: ${INSTALL_TYPE}. Allowed values are 'rac' or 'standalone'."
        exit 1
    fi
    
    # Show resource status
    log_msg "INFO" "Listing all resource status..."
    ${ORACLE_HOME}/bin/crsctl status resource -t | tee -a "${LOG_FILE}"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then ((ERROR_COUNT++)); fi
}

# Function to check ASM status and Disk Groups
check_asm_status() {
    log_msg "INFO" "--- Checking ASM Instance and Disk Groups ---"
    
    # Check ASM via srvctl
    if [ "${INSTALL_TYPE}" == "rac" ]; then
        log_msg "INFO" "Checking ASM status across cluster..."
        ${ORACLE_HOME}/bin/srvctl status asm | tee -a "${LOG_FILE}"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then ((ERROR_COUNT++)); fi
    else
        log_msg "INFO" "Checking local ASM status..."
        ${ORACLE_HOME}/bin/srvctl status asm | tee -a "${LOG_FILE}"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then ((ERROR_COUNT++)); fi
    fi

    # Check Disk Groups via asmcmd
    log_msg "INFO" "Checking ASM Disk Groups state and usage..."
    ${ORACLE_HOME}/bin/asmcmd lsdg | tee -a "${LOG_FILE}"
    if [ ${PIPESTATUS[0]} -ne 0 ]; then ((ERROR_COUNT++)); fi
}

# Function to check oracle binary permissions
check_oracle_binary() {
    log_msg "INFO" "--- Checking Oracle Binary Permissions ---"
    
    local ORACLE_BIN="${ORACLE_HOME}/bin/oracle"
    
    if [ ! -f "${ORACLE_BIN}" ]; then
        log_msg "ERROR" "Oracle binary not found at ${ORACLE_BIN}."
        ((ERROR_COUNT++))
        return
    fi

    log_msg "INFO" "Listing oracle binary details:"
    ls -lah "${ORACLE_BIN}" | tee -a "${LOG_FILE}"

    # Get octal permissions using stat
    local BIN_PERM=$(stat -c "%a" "${ORACLE_BIN}")

    # Expected permission is 6751 (-rwsr-s--x)
    if [ "${BIN_PERM}" == "6751" ]; then
        log_msg "INFO" "Oracle binary permissions are correct (${BIN_PERM} / -rwsr-s--x)."
    else
        log_msg "WARNING" "Oracle binary permissions are INCORRECT. Expected: 6751, Found: ${BIN_PERM}"
        log_msg "WARNING" "Incorrect permissions can cause instances failing to connect to ASM. Please fix it using 'sethasmut' or chmod."
        ((ERROR_COUNT++))
    fi
}

# Execute checks
check_crs_status
echo "" | tee -a "${LOG_FILE}"
check_asm_status
echo "" | tee -a "${LOG_FILE}"
check_oracle_binary

echo "" | tee -a "${LOG_FILE}"
log_msg "INFO" "--- VERIFICATION SUMMARY ---"

if [ ${ERROR_COUNT} -eq 0 ]; then
    log_msg "SUCCESS" "The Grid Infrastructure (${INSTALL_TYPE^^}) and ASM configuration appears to be CORRECT and HEALTHY."
else
    log_msg "FAILED" "Issues were detected. Found ${ERROR_COUNT} error(s) during verification. The configuration is NOT FULLY HEALTHY."
    log_msg "FAILED" "Please review the detailed logs above to identify the root cause."
fi

log_msg "INFO" "Grid Infrastructure and ASM Verification completed."
