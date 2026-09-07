srvctl add service -d orcl -s app_orcl_new_svc \
 -preferred orcl1,orcl2 \
 -policy AUTOMATIC \
 -failovertype SELECT \
 -failovermethod BASIC
