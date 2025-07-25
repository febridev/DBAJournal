# Installation Run Book
## Step-by-Step Guide to Install PostgreSQL 13 on Ubuntu 24 LTS
## Follow these commands in your VM's terminal.

## Step 1: Update Your System's Package List
It's always a good idea to start by updating your package lists to ensure you have the latest information on available packages.

```bash
sudo apt update
sudo apt upgrade -y
```

## Step 2: Configure Static IP Address (Optional but Recommended)
For a stable environment, especially for servers, setting a static IP address is crucial. Ubuntu 24 LTS uses Netplan for network configuration.

Identify your network interface name:
```bash
ip a
```
Look for your primary network interface (e.g., eth0, ens33, enp0s3).

Edit the Netplan configuration file:

Netplan configuration files are typically located in /etc/netplan/. You might find a file like 00-installer-config.yaml or similar.
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```
Modify the file to set a static IP. Replace your_interface_name, your_static_ip, your_gateway_ip, and your_dns_server_ip with your actual network details.

Important: Pay close attention to indentation! YAML uses spaces for indentation, and it's very strict. Use two spaces for each level of indentation.

```bash
network:
  version: 2
  renderer: networkd
  ethernets:
    your_interface_name: # e.g., ens33, eth0
      dhcp4: no
      addresses:
        - your_static_ip/24 # e.g., 192.168.1.100/24 (the /24 is for a standard Class C subnet mask)
      routes:
        - to: default
          via: your_gateway_ip # e.g., 192.168.1.1
      nameservers:
        addresses: [your_dns_server_ip, 8.8.8.8] # e.g., 192.168.1.1, 8.8.8.8 (Google DNS as a fallback)

Save and exit (Ctrl+X, Y, Enter).
```
Fix Permissions for Netplan Configuration File:

The warning "Permissions for /etc/netplan/00-installer-config.yaml are too open" means the file has permissions that are too broad. Only root should have write access, and others should not have any access.

sudo chmod 600 /etc/netplan/00-installer-config.yaml

This command sets the permissions to rw------- (read/write for owner, no permissions for group or others).

Apply the Netplan configuration:

sudo netplan apply

Verify the new IP address:

ip a

Your interface should now show the static IP you configured.

Step 3: Install Necessary Dependencies
You'll need curl to download the GPG key and gnupg2 to manage it.

sudo apt install curl gnupg2 -y

Step 4: Import the PostgreSQL GPG Key
This key is used to verify the authenticity of the PostgreSQL packages you'll download from their official repository.

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

Step 5: Add the PostgreSQL APT Repository
Now, add the official PostgreSQL repository to your system's apt sources. We specify noble for Ubuntu 24.04 LTS (Noble Numbat).

echo "deb http://apt.postgresql.org/pub/repos/apt noble-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql.list

Step 6: Update Package Lists Again
After adding the new repository, you need to update your package lists so apt knows about the new packages available from the PostgreSQL repository.

sudo apt update

Step 7: Install PostgreSQL 13
Now you can install PostgreSQL 13 and the postgresql-contrib-13 package, which provides additional utilities.

sudo apt install postgresql-13 postgresql-contrib-13 -y

Step 8: Verify the Installation
Check if the PostgreSQL service is running and verify the installed version.

Check service status:

sudo systemctl status postgresql

You should see output indicating active (exited) or active (running). If it's not active, you can start it with sudo systemctl start postgresql.

Check PostgreSQL version:

psql --version

You should see psql (PostgreSQL) 13.x.x (where x.x is the specific patch version).

Step 9: Disable Firewall (UFW) (Optional)
While not recommended for production environments without proper rules, you can disable the Uncomplicated Firewall (UFW) if you need to ensure no port blocking.

Check UFW status:

sudo ufw status

Disable UFW:

sudo ufw disable

You will be prompted to confirm. Type y and press Enter.

Step 10: Basic Configuration (Optional but Recommended)
By default, PostgreSQL creates a user called postgres with the ident authentication method, meaning it can only be accessed by the postgres system user.

Switch to the postgres user:

sudo -i -u postgres

Access the PostgreSQL prompt:

psql

You are now in the PostgreSQL command-line interface.

Set a password for the postgres database user:

ALTER USER postgres WITH PASSWORD 'your_strong_password';

Replace 'your_strong_password' with a strong password you'll remember.

Exit the PostgreSQL prompt:

\q

Exit the postgres system user:

exit

You are now back to your regular user.

Step 11: Configure Client Authentication (Optional)
If you want to connect to PostgreSQL from other users or remote machines, you'll need to edit the pg_hba.conf file.

sudo nano /etc/postgresql/13/main/pg_hba.conf

Find the line that looks like this:

# "local" is for Unix domain socket connections only
local   all             all                                     peer

Change peer to md5 for local connections if you want to use password authentication:

# "local" is for Unix domain socket connections only
local   all             all                                     md5

If you need to allow connections from other machines, add a line like this (be cautious with 0.0.0.0/0 in production):

# IPv4 local connections:
host    all             all             0.0.0.0/0               md5

Save and exit (Ctrl+X, Y, Enter).

Restart PostgreSQL service to apply changes:

sudo 

## Configuration by Default
### Configuration file
```bash
/etc/postgresql/13/main
```

### Datafile
```bash
/var/lib/postgresql/13/main
```