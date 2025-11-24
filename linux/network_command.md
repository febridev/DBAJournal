# Collect All Command regarding the network.
- Check Port Source
```bash
sudo netstat -tnlp | grep :22
```

# Setup Network 
- Check Device Status
```bash
nmcli device status
```

- Set ip on specific devices
```bash
nmcli connection add con-name <connection_name> ifname <enp0s8> type ethernet ipv4.method manual ipv4.addresses <10.10.0.50/24>
```

- Bring Up the connection
```bash
nmcli connection up <connection_name>
```

- Check IP Address
```bash
ip addr show <enp0s8>
```

- Change IP Address
```bash
nmcli con mod priv-conn ipv4.addresses 10.10.0.84/24
```