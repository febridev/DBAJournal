expdp \" <user>/<password>@//<hostname>:<port>/<pdb_service_name> \" \
      directory=<nama_objek_direktori> \
      dumpfile=<nama_file_dump>.dmp \
      logfile=<nama_file_log>.log \
      compression=ALL \
      full=Y



expdp userid=sys/database@nt19c2:1521/PNT19C2 \
      directory=PDB_BACKUP_DIR2 \
      dumpfile=FULL_PNT19C2_20250917.dmp \
      logfile=FULL_PNT19c2_20250917.log \
      compression=ALL \
      full=Y



expdp \"sys/database@nt19c2:1521/pnt19c2.localdomain as sysdba \" \
      directory=PDB_BACKUP_DIR2 \
      dumpfile=FULL_PNT19C2_20250917.dmp \
      logfile=FULL_PNT19c2_20250917.log \
      compression=ALL \
      full=Y



      
expdp \"sys/database@10.10.20.8:1521/pnt19c2.localdomain as sysdba \" \
      directory=PDB_BACKUP_DIR2 \
      dumpfile=FULL_IP_PNT19C2_20250917.dmp \
      logfile=FULL_IP_PNT19c2_20250917.log \
      compression=ALL \
      full=Y

expdp \"HR_APP/hrapp@10.10.20.8:1521/pnt19c2.localdomain \" \
      directory=PDB_BACKUP_DIR2 \
      dumpfile=FULL_schemas_PNT19C2_20250917.dmp \
      logfile=FULL_schemas_PNT19c2_20250917.log \
      schemas=HR_APP \
      content=ALL \
      compression=ALL