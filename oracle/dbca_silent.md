# Create New Instance (dbca) With Silent 
- Preapare .rsp file 

```bash
vi /tmp/dbca.rsp
```
- Sample `.rsp` file oracle\sample\dbca.rsp

- Running dbca with silent 
```bash
dbca -silent -createDatabase -responseFile /path/to/your/dbca_response_file.rsp

# init param
dbca -silent -createDatabase \
  -responseFile dbca.rsp \
  -initParams db_unique_name=NT19C2_PRI

```


## Drop Database / Instance
```bash
dbca -silent -deleteDatabase \
     -sourceDB nt19c2 \
     -sysDBAUserName sys \
     -sysDBAPassword <your_sys_password>
```