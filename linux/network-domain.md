# 1. Daftarkan IP BIND DB

sudo nmcli connection modify enp0s3 ipv4.dns "10.10.20.45 10.10.20.46"

# 2. Set search domain

sudo nmcli connection modify enp0s3 ipv4.dns-search "localdomain.com"

# 3. Abaikan DNS paksaan dari DHCP Router (Kunci Utama)

sudo nmcli connection modify enp0s3 ipv4.ignore-auto-dns yes

# 4. Set fast failover (1 detik)

sudo nmcli connection modify enp0s3 ipv4.dns-options "timeout:1 attempts:2"

# 5. Terapkan

sudo nmcli connection up enp0s3

# Set Primary DNS = IP Diri Sendiri, Secondary DNS = IP Node DB 2

sudo nmcli connection modify enp0s3 ipv4.dns "10.10.20.45 10.10.20.46"
sudo nmcli connection modify enp0s3 ipv4.dns-search "localdomain.com"
sudo nmcli connection modify enp0s3 ipv4.ignore-auto-dns yes
sudo nmcli connection modify enp0s3 ipv4.dns-options "timeout:1 attempts:2"

# Apply

sudo nmcli connection down enp0s3
sudo nmcli connection up enp0s3
