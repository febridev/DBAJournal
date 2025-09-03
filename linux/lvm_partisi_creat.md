# LINUX Partition Disk With LVM
## Requirement Binary / Package
- Debian/Ubuntu: `sudo apt-get install lvm2`
- CentOS/RHEL: `sudo yum install lvm2`

## Setup
- Create partition
```bash
sudo fdisk /dev/sdd 

# g new partition
# n create partition
# t change partition type
# L check list all partition type
# p print partition
# w write disk changes
```

- Initiate Physical Volume (PV)
```bash
sudo pvcreate /dev/sdd1

#verified
sudo pvs
```

- Create Volume Group 
```bash
sudo vgcreate vg-data /dev/sdd1

#verified
sudo vgs
```

- Create logical volume
```bash
sudo lvcreate -n lv-data -l 100%FREE vg-data
# -n lv-data give lv-data pada LV
# -l 100%FREE use entire free space on VG

#verified
sudo lvs
```

- Create filesystem
```bash
sudo mkfs.xfs /dev/vg-data/lv-data

# for RHEL 9 and Oracle Linux 9 is recommend using XFS
```

- Get UUID 
```bash
blkid /dev/vg-data/lv-data
```

- Mounting 
```bash
mkdir /u01
vi /etc/fstab
# echo 'UUID=<UUID_YANG_ANDA_SALIN>  /data  xfs  defaults  0  0'
```