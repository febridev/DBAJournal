# Failover standby node as primary on streaming replicaton
## Primary standby
- In this case we can simulation the primary node is down.

```bash
sudo su
systemctl stop postgresql 
```
- After that we can set standby node as primary node 
```bash
sudo -i -u postgres
psql
```

```sql
select pg_promote