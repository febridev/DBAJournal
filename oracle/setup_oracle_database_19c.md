# Oracle Database 19c Oracle Linux 8 Runbook

This is guide or runbook for oracle database 19c setup on oracle linux with GCP environment. And in this demo using version 19c and oracle linux 8 with ASM and GRID Infrastructure For Standalone Restart.

## Disclaimer

- This is for demo or development purpose.
- If you apply on production you need changes more configuration like firewall etc.
- If any differential on GCP please adjusts for your self, or may be you can PR on this repository.
- I expected you are already familiar with GCP or other cloud environment.

## Preparation

- Create GCE Machine with oracle linux 8
  - Set Boot disk with Balanced Disk Type 30 - 50 GB.
  - CPU 2 Core and 8 GB Memory
  - Attach 3 Disk for ASMDISK (all disk enough using Balanced Disk)
    - 5 GB for OCR
    - 20 GB for DATA
    - 10 GB for FRA
- VPC Default (for demo or development purpose)
- Allow port on VPC default like 1521, 3389 AND 6000 for x11

## Installation

### Setup Repository or Pre-Installation

On this part you must be using `root` user

- Setup Repository

```bash
sudo yum update -y
sudo yum install -y oracle-database-preinstall-19c
sudo yum install -y xauth xdpyinfo xorg-x11-xauth dejavu-sans-fonts # for X Display
sudo yum install -y tigervnc-server tigervnc # Optional, For Remote
sudo yum install -y epel-release # Optional for get xrdp
sudo yum install -y xrdp # Instal XRDP
```

- Setup Firewall and SELINUX
  For development or demo purpose we can set the firewall disabled and `SELINUX=disable`

```bash
# set SELINUX disable
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
cat /etc/selinux/config

# set firewall disabled
systemctl stop firewalld
systemctl disable firewalld
```

- Changes The `X11` configuration on SSHD

```bash
vi /etc/ssh/sshd_config

# edit this line
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes

systemctl restart sshd
```

- Changes SSH can using password for others user like `grid or oracle`
  this is optional because if you can't new sshkey on gce for user `grid and oracle` you can't direct ssh using `grid or oracle` user.

```bash
vi /etc/ssh/sshd_config

# edit this line from No to Yes
PasswordAuthentication Yes

systemctl restart sshd
```

### Setup ORACLE ASM

In this part will be setup ASM using `UDEV` because oracleasm doesn't available again so oracle recommend using `UDEV`

- Check disk available (using root)

```bash
lsblk -f

NAME        FSTYPE LABEL UUID                                 MOUNTPOINT
sda
├─sda1      xfs    root  <UUID_OF_ROOT_PARTITION>             /
└─sda2      swap         <UUID_OF_SWAP_PARTITION>             [SWAP]
sdb                                                             <-- Your 20GB disk
sdc                                                             <-- Your 10GB disk
sdd                                                             <-- Your 20GB disk
```

- Check `oracle` user is available

```bash
id oracle
```

- Setup GROUP ASM USER on OS LINUX

```bash
# Create ASM groups
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
```

- Add `asmdba` as secondary group to oracle user:

```bash
# add asmdba group to oracle user
 usermod -a -G asmadmin,asmdba oracle
 id oracle
```

- Create Grid user:

```bash
# create grid user
 useradd -u 54331 -g oinstall -G dba,asmdba,asmadmin,asmoper,racdba grid
```

- Change the password for Oracle and Grid user:

```bash
# create grid oracle user passwords
 passwd oracle
 passwd grid
```

- Create the Directories for the Oracle Grid installation

```bash
mkdir -p /u01/19c/oracle_base
mkdir -p /u01/19c/oracle_base/oracle/db_home
chown -R oracle:oinstall /u01
```

- Create the Directories for the Oracle Database installation

```bash
mkdir -p /u01/19c/grid_base
mkdir -p /u01/19c/grid_home
chown -R grid:oinstall /u01/19c/grid_base /u01/19c/grid_home
chmod -R 775 /u01
```

- Switch to the `grid` user and edit the Grid `.bash_profile`, before edit the file I will take backup for it first

```bash
su - grid
cd /home/grid
cp .bash_profile .bash_profile.bkp

```

- Copy and paste this to grid home directory

```bash
cat > /home/grid/.grid19c_env <<EOF
# User specific environment and startup programs
ORACLE_SID=+ASM; export ORACLE_SID
ORACLE_BASE=/u01/19c/grid_base; export ORACLE_BASE
ORACLE_HOME=/u01/19c/grid_home; export ORACLE_HOME
ORACLE_TERM=xterm; export ORACLE_TERM
JAVA_HOME=/usr/bin/java; export JAVA_HOME
TNS_ADMIN=\$ORACLE_HOME/network/admin; export TNS_ADMIN
PATH=.:\${JAVA_HOME}/bin:\${PATH}:\$HOME/bin:\$ORACLE_HOME/bin
PATH=\${PATH}:/usr/bin:/bin:/usr/local/bin
export PATH
umask 022
EOF
```

- Apply the profile for the current session and check the environment variables:

```bash
echo "source ~/.grid19c_env" >> ~/.bash_profile
source .bash_profile
env | grep -i "tns\|oracle"exit
```

- Switch to `oracle` user and backup the `.bash_profile` :

```bash
su - oracle
cp .bash_profile .bash_profile.bkp
```

- Create new bash profile file copy the below script to your terminal and press enter:
  Please replace `<your_sid>` with your prefer `SID`

```bash
cat > /home/oracle/.db19c_env <<EOF
# specific environment and startup programs
ORACLE_HOSTNAME=\$HOSTNAME; export ORACLE_HOSTNAME
ORACLE_SID=<your_sid>; export ORACLE_SID
ORACLE_UNQNAME=<your_sid>; export ORACLE_UNQNAME
ORACLE_BASE=/u01/19c/oracle_base; export ORACLE_BASE
ORACLE_HOME=\$ORACLE_BASE/oracle/db_home; export ORACLE_HOME
ORACLE_TERM=xterm; export ORACLE_TERM
JAVA_HOME=/usr/bin/java; export JAVA_HOME
TNS_ADMIN=\$ORACLE_HOME/network/admin; export TNS_ADMIN
PATH=.:\${JAVA_HOME}/bin:\${PATH}:\$HOME/bin:\$ORACLE_HOME/bin
PATH=\${PATH}:/usr/bin:/bin:/usr/local/bin
NLS_DATE_FORMAT="DD-MON-YYYY HH24:MI:SS"; export NLS_DATE_FORMAT
TNS_ADMIN=\$ORACLE_HOME/network/admin; export TNS_ADMIN
PATH=.:\${JAVA_HOME}/bin:\${PATH}:\$HOME/bin:\$ORACLE_HOME/bin
PATH=\${PATH}:/usr/bin:/bin:/usr/local/bin
TEMP=/tmp ;export TMP
TMPDIR=\$tmp ; export TMPDIR
export PATH
umask 022
EOF
```

- Apply the profile

```bash
echo "source ~/.db19c_env" >> ~/.bash_profile
source /home/oracle/.bash_profile
env | grep ORACLE
exit
```

- Check the NTP service

```bash
systemctl status chronyd
```

**Configure Disk The Oracle ASM**

- Zero Out Disk Headers (Crucial for ASM):
  - Ensure the disks don't have any existing file system or partition table headers that could confuse ASM.
  - Login as `root`
  ```bash
  dd if=/dev/zero of=/dev/sdb bs=1M count=100
  dd if=/dev/zero of=/dev/sdc bs=1M count=100
  ```
- Create udev Rules for ASM Disks (root):

```bash
vi /etc/udev/rules.d/99-oracle-asmdisks.rules

# ASM Disk for OCR
KERNEL=="sdb", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ACTION=="add|change", SYMLINK+="oracleasm/asm-data", OWNER="grid", GROUP="asmadmin", MODE="0660"

# ASM Disk for FRA (10GB)
KERNEL=="sdc", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ACTION=="add|change", SYMLINK+="oracleasm/asm-fra", OWNER="grid", GROUP="asmadmin", MODE="0660"

# ASM Disk for DATA (20GB)
KERNEL=="sdd", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ACTION=="add|change", SYMLINK+="oracleasm/asm-datadb", OWNER="grid", GROUP="asmadmin", MODE="0660"
```

- Reload `udevadm` control

```bash
# Reload the UDEV rules
udevadm control --reload-rules && udevadm trigger --action=add
```

- Check Results

```bash
ls -l /dev/oracleasm/

```

Expected Output

```bash
total 0
lrwxrwxrwx. 1 root root 9 Jun  x xx:xx asm-data -> ../../sdb
lrwxrwxrwx. 1 root root 9 Jun  x xx:xx asm-fra -> ../../sdc
lrwxrwxrwx. 1 root root 9 Jun  x xx:xx asm-fra -> ../../sdd
```

```bash
ls -l /dev/sdb
ls -l /dev/sdc
ls -l /dev/sdd
```

Expected Output

```bash
brw-rw----. 1 grid asmadmin 8, 16 Jun  x xx:xx /dev/sdb
brw-rw----. 1 grid asmadmin 8, 32 Jun  x xx:xx /dev/sdc
brw-rw----. 1 grid asmadmin 8, 32 Jun  x xx:xx /dev/sdd
```

### Install Oracle 19 Grid Infrastructure

- Login as `grid` user
- Upload or Download the grid installer
- Extract on `$ORACLE_HOME` which is at `/u01/19c/grid_home`
- If you working remotely set the display for remote connection x11 forwarding, and set alias oracle linux version to `OEL7.6`

```bash
export DISPLAY=10.10.20.1:0.0
xhost +
# to test the x11 forwarding run below command
xev
export CV_ASSUME_DISTID=OEL7.6
```

- Run installation setup using GUI

```bash
cd $ORACLE_HOME

./gridSetup.sh
```

- Follow instruction, video on below

[Oracle Grid 19c Installation](https://drive.google.com/file/d/1_ZWKvqazGJFSyu9HFCdma96XcboelOpx/view?usp=sharing)

- Check the grid services

```bash
# from Grid user
crsctl stat res -tsqlplus -s / as sysdba <<EOFselect instance_name from v\$instance;EOF
```

## Create Data & FRA Disks Group

- Login using `grid` user
- Follow instruction, video on below
  [Create Disks Group On ASMCA](https://drive.google.com/file/d/1-IsNhbJ97bzMyUuPGbFNNoOFQzsBsP-z/view?usp=sharing)

- check the cluster resource if the disk groups have the cluster services using below command:

```bash
crsctl stat res -t
# the restult should be
# ora.CRS.dg    ONLINE  ONLINE       oracle                   STABLE
# ora.DATA.dg   ONLINE  ONLINE       oracle                   STABLE
# ora.FRA.dg    ONLINE  ONLINE       oracle                   STABLE
```

### Installing Oracle DB 19c software Only
