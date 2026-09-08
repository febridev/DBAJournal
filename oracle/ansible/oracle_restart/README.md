# Oracle 19c Standalone Installation — Ansible IaC

Modular Ansible playbooks for automated Oracle 19c Standalone (Oracle Restart / SIHA) installation with ASM storage, including Grid Infrastructure, database environment, and full verification.

## What This Does

Installs Oracle 19c in three phases:

1. **Phase 1** — Prerequisites, users/groups, LVM storage, directory structure, environment profiles, and extraction of Grid Infrastructure binaries
2. **Phase 2** — ASM disk configuration, OPatch/RU patching, Grid Infrastructure silent install, root scripts, diskgroup creation, and verification
3. **Phase 3** — Database software install, OPatch upgrade, DB-RU + OJVM patching, silent `runInstaller`, root.sh, and verification

Result: A single-node Oracle 19c instance running under Oracle Restart with three ASM diskgroups (OCR, DATA, FRA) and a fully patched database home.

## Project Structure

```
oracle-ansible/
├── group_vars/
│   ├── all.yml              ← Shared variables (paths, passwords, disks, timeouts)
│   └── ora_nodes.yml        ← Node-specific overrides
├── inventory.ini            ← Target host definitions + SSH settings
├── playbooks/
│   ├── phase1.yml           ← Thin orchestrator for prerequisites
│   ├── phase2.yml           ← Thin orchestrator for Grid Infrastructure
│   └── phase3.yml           ← Thin orchestrator for Database Software Install
└── roles/
    ├── preinstall/tasks/main.yml             # Packages, SELinux, firewall
    ├── users-groups/tasks/main.yml           # ASM groups, oracle/grid users
    ├── storage-lvm/tasks/main.yml            # LVM layout → /u01
    ├── create-directories/tasks/main.yml     # Oracle/Grid directory hierarchy
    ├── oracle-environment/                   # Environment profile templates
    │   ├── tasks/main.yml
    │   ├── templates/grid_env.j2
    │   └── templates/db_env.j2
    ├── grid-software/tasks/main.yml          # Unzip Grid Infrastructure binaries
    ├── limits-udev/                          # Resource limits for grid user
    │   └── tasks/main.yml
    ├── asm-storage/                          # ASM wipes, udev rules by serial
    │   ├── tasks/main.yml
    │   └── templates/99-oracle-asm.rules.j2
    ├── grid-infrastructure/                  # OPatch, RU, gridSetup.sh, DGs
    │   ├── tasks/main.yml
    │   └── templates/gridsetup.rsp.j2
    ├── db-prereqs/tasks/main.yml             # Add OS groups to oracle user
    ├── db-software/tasks/main.yml            # Extract DB binaries, upgrade OPatch, stage patches
    ├── db-response/                          # Generate db_install.rsp from Jinja2 template
    │   ├── tasks/main.yml
    │   └── templates/db_install.rsp.j2
    └── db-finalize/tasks/main.yml            # runInstaller, root.sh, OJVM patch, verify
```

**Key design principle:** All hardcoded values have been externalized into `group_vars/all.yml`. To deploy to a different environment, you only edit variable files — never touch role tasks or playbooks.

## Prerequisites

### Control node (your laptop/desktop)

- Ansible 2.9+ installed
- Python 3 with `pyyaml`
- SSH access to target hosts (key-based auth recommended)

### Target hosts

- Oracle Linux 8 / RHEL 8 (or compatible RHEL-family distribution)
- Python 3 installed (`/usr/bin/python3`)
- User with sudo privileges
- At least 3 additional block devices for ASM: `/dev/sdb`, `/dev/sdc`, `/dev/sdd`
- One additional block device for storage: `/dev/sde` (mounted as `/u01`)
- Internet access or local YUM repo for prerequisite packages
- Oracle 19c installation media uploaded to target hosts:

| File | Destination path |
|------|-----------------|
| `LINUX.X64_193000_grid_home.zip` | `/tmp/LINUX.X64_193000_grid_home.zip` |
| `LINUX.X64_193000_db_home.zip` | `/tmp/LINUX.X64_193000_db_home.zip` |
| `p6880880_190000_Linux-x86-64.zip` | `/tmp/p6880880_190000_Linux-x86-64.zip` |
| `p39467003_190000_Linux-x86-64.zip` | `/tmp/p39467003_190000_Linux-x86-64.zip` |
| `p39062931_190000_Linux-x86-64.zip` | `/tmp/p39062931_190000_Linux-x86-64.zip` |

## Quick Start

### 1. Configure your inventory

Edit `inventory.ini` to match your target hosts:

```ini
[ora_nodes]
oracle-server1 ansible_host=10.0.0.10
oracle-server2 ansible_host=10.0.0.11   # optional, for multi-node
```

Update connection settings in `[ora_nodes:vars]`:

```ini
ansible_user=myuser                     # SSH login user
ansible_become=yes                      # sudo support
ansible_become_method=sudo
ansible_python_interpreter=/usr/bin/python3
```

### 2. Customize variables (optional)

All defaults are defined in `group_vars/all.yml`. Common customizations:

```yaml
# Change the installation base path
ora_base: /u01

# Change the database SID
oracle_sid: mydb
oracle_unqname: "{{ oracle_sid }}"

# Change ASM disk devices
asm_disks:
  - { dev: sdb, role: ocr }
  - { dev: sdc, role: data }
  - { dev: sdd, role: fra }

# Change the storage device for /u01
lvm_disk: /dev/sde
lvm_vg_name: vg_u01
lvm_lv_name: lv_u01

# Change passwords
oracle_password: "Welcome123!"
grid_password: "Welcome123!"
asm_sys_password: "Welcome123#"
asm_monitor_password: "Asm#Monitor123"
```

To keep production secrets out of version control, create an encrypted vars file or override via `--extra-vars`:

```bash
# Override a single variable on the command line
ansible-playbook -i inventory.ini playbooks/phase1.yml \
  --extra-var "oracle_sid=prod19c"

# Use an extra-variables file (gitignored)
ansible-playbook -i inventory.ini playbooks/phase1.yml \
  --extra-vars "@vaulted_vars.yml"
```

### 3. Run Phase 1

This prepares the host: installs packages, configures users, sets up LVM storage, creates directories, deploys environment profiles, and extracts Grid binaries.

```bash
ansible-playbook -i inventory.ini playbooks/phase1.yml
```

Expected time: 5–15 minutes depending on package download size.

### 4. Verify Phase 1 completion

```bash
# Check that the binary was extracted
ssh myuser@oracle-server1 "ls -la /u01/19c/grid_home/gridSetup.sh"

# Check LVM mount
ssh myuser@oracle-server1 "df -h /u01"
```

### 5. Run Phase 2

This performs the full Grid Infrastructure installation: ASM disk setup, patching, silent install via `gridSetup.sh`, root scripts, diskgroup creation, and verification.

```bash
ansible-playbook -i inventory.ini playbooks/phase2.yml
```

Expected time: 30–60+ minutes. The playbook uses asynchronous execution for long-running operations and includes retry logic for CRS readiness.

### 6. Verify Phase 2 completion

After Phase 2 completes, verify everything is healthy:

```bash
# Check CRS resources
ssh grid@oracle-server1 "/u01/19c/grid_home/bin/crsctl stat res -t"

# Check ASM diskgroups
ssh -t grid@oracle-server1 "source ~/.grid19c_env && asmcmd lsdg"

# Check OPatch patches
ssh -t grid@oracle-server1 "source ~/.grid19c_env && /u01/19c/grid_home/OPatch/opatch lspatches"
```

### 7. Run Phase 3

This installs the Oracle Database software into DB_HOME, applies RU + OJVM patches, runs `root.sh`, and verifies the installation:

```bash
ansible-playbook -i inventory.ini playbooks/phase3.yml
```

Expected time: 45–90+ minutes. Includes async waits for `runInstaller` (~90 min), root.sh (~15 min), and OJVM patch apply (~30 min).

### 8. Verify Phase 3 completion

```bash
# Check OPatch level on DB home (should show DB RU + OJVM RU IDs)
ssh oracle@oracle-server1 "source ~/.db19c_env && $ORACLE_HOME/OPatch/opatch lspatches"

# Check sqlplus version
ssh oracle@oracle-server1 "source ~/.db19c_env && echo exit | sqlplus -S /nolog | head -2"

# Check central inventory registration
grep -q '/u01/19c/oracle_base/oracle/db_home' /u01/app/oraInventory/ContentsXML/inventory.xml && echo "DB_HOME registered" || echo "NOT registered"
```

## Troubleshooting

### gridSetup.sh fails or hangs

Phase 2 output shows the last 15 lines automatically. For more detail:

```bash
ssh myuser@oracle-server1 "tail -100 /u01/19c/grid_home/cfgtoollogs/gridSetupActions*.log"
```

### CRS doesn't come up after root.sh

The playbook waits up to 20 minutes (80 retries × 15 seconds) for OHASD to start. If it times out:

```bash
ssh grid@oracle-server1 "cat /u01/19c/grid_home/crs/install/last_root_output.log"
```

Check the system log for kernel-level issues.

### UDEV rules not creating symlinks

Verify SCSI serial numbers match:

```bash
ssh myuser@oracle-server1 "udevadm info --query=property --name=/dev/sdb | grep ID_SCSI_SERIAL"
ssh myuser@oracle-server1 "cat /etc/udev/rules.d/99-oracle-asm.rules"
```

Reload manually if needed:

```bash
ssh myuser@oracle-server1 "sudo udevadm control --reload-rules && sudo udevadm trigger"
```

### Idempotency

All three playbooks are idempotent. Re-running skips completed steps:
- Package installation checks current state
- User/group creation skips existing accounts
- LVM setup skips mounted filesystems
- `gridSetup.sh` checks for `/etc/oracle/olr.loc` marker
- `runInstaller` checks central inventory registration (`inventory.xml`)
- Root scripts (both GI and DB) check for `.done` markers
- Diskgroup creation skips already-created groups
- OPatch backup marker prevents duplicate upgrades
- RU patch check skips already-applied patches
- OJVM patch check skips already-applied OJVM RU

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Three-phase split | Phase 1 is fast; Phase 2 (GI) and Phase 3 (DB) each involve 30–90 min installs — separating them isolates failures and allows verification between stages |
| Async execution for long-running steps | `runInstaller`, `gridSetup.sh`, root scripts, and OJVM patches run 15–90 minutes; async prevents Ansible timeouts |
| Jinja2 templates for response files | Allows per-environment customization without changing role code (`gridsetup.rsp.j2`, `db_install.rsp.j2`) |
| UDEV rules by `ID_SCSI_SERIAL` | Reliable across VM migrations where `/dev/sdX` ordering changes |
| Role-based modular structure | Each role = one responsibility. Swap, reorder, or reuse roles freely |
| Separate vars for GI vs DB patches | `ru_patch_zip`/`ru_patch_id` for Phase 2, `db_ru_zip`/`db_ru_id`/`ojvm_ru_id` for Phase 3 — change independently |

## Customization Examples

### Change AU size for diskgroups

Edit `group_vars/all.yml`:

```yaml
asm_diskgroup_au_size: "1M"   # or "4M", "8M", "16M", "32M", "64M"
```

### Add another ASM disk

Add to `group_vars/ora_nodes.yml`:

```yaml
asm_disks:
  - { dev: sdb, role: ocr }
  - { dev: sdc, role: data }
  - { dev: sdd, role: fra }
  - { dev: sdf, role: backup }   # new disk
```

Then update the response file template `roles/grid-infrastructure/templates/gridsetup.rsp.j2` and the disk creation shell commands to include the new disk.

### Update RU / OJVM patch numbers

All patch variables live in `group_vars/all.yml`. To bump to a newer release:

```yaml
# Phase 2 — Grid Infrastructure RU
ru_patch_zip: /tmp/p<new_gi_ru_id>_190000_Linux-x86-64.zip
ru_patch_id: "<new_gi_ru_id>"

# Phase 3 — Database Software RU + OJVM
db_ru_zip: /tmp/p<new_db_ru_bundle_id>_190000_Linux-x86-64.zip
db_ru_id: "<new_db_ru_id>"
ojvm_ru_id: "<new_ojvm_ru_id>"
```

Run Phase 2 and/or Phase 3 again — each playbook checks for already-applied patches and skips them.

### Deploy to multiple nodes (RAC-like)

1. Add hosts to `[ora_nodes]` in `inventory.ini`
2. Set per-host variables using `host_vars/` directory (not yet implemented — add as needed)
3. Note: This playbook targets a single node (Oracle Restart). Multi-node RAC requires additional coordination not covered here

## Original Playbooks (Backups)

The original monolithic playbooks are preserved alongside the refactored versions:
- `phase1_playbook.yml` — original Phase 1 (single file, all-in-one)
- `phase2_playbook.yml` — original Phase 2 (single file, all-in-one)
- `phase3_playbook.yml` — original Phase 3 (single file, all-in-one)

These are kept for reference. The canonical versions are now under `playbooks/`.

## License

Internal use — Oracle Installation Automation.
