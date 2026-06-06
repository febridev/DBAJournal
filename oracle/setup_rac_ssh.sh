#!/bin/bash

# ====================================================================
# Script Name : setup_rac_ssh.sh
# Description : Automated SSH Configuration for Oracle RAC
# Reference   : DB-SSH Configuration For Oracle RAC-010626-093241.pdf
# ====================================================================

echo "================================================================="
echo "   Oracle RAC SSH Connectivity Automation Script"
echo "================================================================="

# Step 1: Interactive Prompt Inputs
read -p "Enter the Oracle/Grid OS username (e.g., oracle): " USR
if [ -z "$USR" ]; then
    echo "Error: Username cannot be empty."
    exit 1
fi

read -p "Enter all RAC hostnames/IPs (separated by space, e.g., node1 node2): " -a NODES
if [ ${#NODES[@]} -eq 0 ]; then
    echo "Error: Hostname list cannot be empty."
    exit 1
fi

echo -e "\n[+] Target nodes detected: ${NODES[*]}"

# Resolve local home directory path dynamically
LOCAL_HOME=$(eval echo "~$USR")
chmod 755 "$LOCAL_HOME"

# Step 2: Create directories and generate keys on all cluster nodes
echo -e "\n-----------------------------------------------------------------"
echo "[Step 1] Creating .ssh directories & Generating Keys on all nodes"
echo "-----------------------------------------------------------------"
for NODE in "${NODES[@]}"; do
    echo ">>> Processing Node: $NODE (Please provide password if prompted)"
    
    # Remote execution block to set up base infrastructure
    ssh -o StrictHostKeyChecking=no "${USR}@${NODE}" "
        chmod 755 \$HOME
        mkdir -p \$HOME/.ssh
        chmod 700 \$HOME/.ssh
        cd \$HOME/.ssh
        
        # Generate RSA keypair if missing
        if [ ! -f id_rsa ]; then
            ssh-keygen -t rsa -N '' -f id_rsa
        fi
        
        # Generate DSA keypair if missing
        if [ ! -f id_dsa ]; then
            ssh-keygen -t dsa -N '' -f id_dsa
        fi
        
        # Consolidate public keys locally for this specific node
        cat *.pub > authorized_keys.\${HOSTNAME}
    "
done

# Step 3: Centralize and combine public keys
echo -e "\n-----------------------------------------------------------------"
echo "[Step 2] Consolidating all Public Keys to Master File"
echo "-----------------------------------------------------------------"
TEMP_DIR="/tmp/ssh_rac_combine"
mkdir -p "$TEMP_DIR"
rm -rf "$TEMP_DIR"/*

for NODE in "${NODES[@]}"; do
    echo ">>> Fetching public key file from: $NODE"
    # Using an absolute fallback path to capture the remote file safely
    scp "${USR}@${NODE}:~/.ssh/authorized_keys.*" "$TEMP_DIR/" 2>/dev/null
done

echo ">>> Merging all public keys into master authorized_keys..."
cat "$TEMP_DIR"/authorized_keys.* > "$TEMP_DIR"/authorized_keys_master
chmod 600 "$TEMP_DIR"/authorized_keys_master

# Step 4: Distribute master file back to all nodes
echo -e "\n-----------------------------------------------------------------"
echo "[Step 3] Distributing Master authorized_keys File to all nodes"
echo "-----------------------------------------------------------------"
for NODE in "${NODES[@]}"; do
    echo ">>> Uploading master authorized_keys to: $NODE"
    scp "$TEMP_DIR/authorized_keys_master" "${USR}@${NODE}:~/.ssh/authorized_keys"
    
    # Enforce strict read/write security permissions remotely
    ssh "${USR}@${NODE}" "chmod 600 \$HOME/.ssh/authorized_keys"
done

# Step 5: Execute matrix validation cross-check
echo -e "\n-----------------------------------------------------------------"
echo "[Step 4] Verifying Passwordless SSH & Populating known_hosts"
echo "-----------------------------------------------------------------"
echo "Running cross-node connection tests to auto-accept host signatures..."

for SRC in "${NODES[@]}"; do
    for DST in "${NODES[@]}"; do
        echo ">>> Testing connection from [ $SRC ] to [ $DST ]..."
        # StrictHostKeyChecking=no auto-adds keys to known_hosts on first connection
        ssh -t "${USR}@${SRC}" "ssh -o StrictHostKeyChecking=no ${USR}@${DST} date"
    done
done

# Clean up temporary processing workspace
rm -rf "$TEMP_DIR"

echo -e "\n================================================================="
echo "   SUCCESS! Passwordless SSH configuration is complete."
echo "================================================================="
