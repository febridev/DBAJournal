# DBAJournal 📚

A comprehensive collection of Database Administrator (DBA) notes, runbooks, configuration guides, and automation scripts. This repository serves as a knowledge base for managing multiple database technologies and the underlying Linux infrastructure.

## 📁 Repository Structure

The journal is organized by technology and operational area:

### 🐧 [Linux Administration](./linux)
General OS-level notes and guides focusing on:
- **Storage Management**: LVM partition creation and management.
- **Networking**: Domain configuration and network command references.
- **Infrastructure**: DNS server setup and demonstrations.

### 🐬 [MySQL](./mysql)
Guides and scripts for MySQL management on Ubuntu, including:
- **Maintenance**: Pre-patching check scripts.
- **Replication**: Detailed guides on InnoDB and Logical replication.
- **Routing**: MySQL Router installation and configuration.

### 🔴 [Oracle Database](./oracle)
Extensive resources for Oracle 19c and beyond:
- **Installation**: Step-by-step guides for Oracle Database, PDBs, and Grid Infrastructure.
- **High Availability**: RAC installation and DataGuard setup/switchover.
- **Maintenance**: Patching guides, parameter changes, and log analysis.
- **Automation**: 
  - [Oracle Restart Ansible IaC](./oracle/ansible/oracle_restart): A modular Ansible project for automated 19c Standalone installation with ASM.
- **Utilities**: Shell scripts for pre-installation, Grid verification, and RAC information gathering.

### 🐘 [PostgreSQL](./postgresql)
Guides for PostgreSQL administration on Ubuntu:
- **Deployment**: Installation runbooks.
- **Availability**: Streaming replication and log-based shipping standby setup.
- **Failover**: Guides on implementing and managing failover.
- **Reference**: Parameter reference guides.

### 🛠️ [Samples](./sample)
A collection of reference files and output snippets:
- Sample configuration files (hosts, named.conf.local).
- Command output examples (cluster status, listener status).
- Sample response files for silent installations.

## 🚀 How to Use This Journal

1. **Browse by Topic**: Navigate to the directory corresponding to the technology you are working with.
2. **Runbooks**: Look for `.md` files for step-by-step guides.
3. **Scripts**: Bash scripts (`.sh`) are provided for common repetitive tasks. Always review the script content and test in a development environment before running in production.
4. **Ansible Automation**: For the Oracle Restart automation, refer to the specific `README.md` within the `oracle/ansible/oracle_restart/` directory for a detailed quick-start guide.

## 🛠️ Technology Stack

- **OS**: Oracle Linux, RHEL, Ubuntu
- **DBs**: Oracle 19c, MySQL, PostgreSQL
- **Automation**: Ansible, Bash
- **Documentation**: Markdown

---
*Internal DBA Knowledge Base*
