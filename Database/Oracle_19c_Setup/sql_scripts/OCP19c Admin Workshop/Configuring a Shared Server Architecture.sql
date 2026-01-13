#$ . oraenv
#ORACLE_SID = [orclcdb] ? orclcdb
#$ sqlplus / as sysdba
#SQL> show parameter shared_server
#SQL> show parameter dispatchers
#SQL> alter system set shared_servers = 3;
#SQL> show parameter dispatchers
#SQL> ALTER SYSTEM SET dispatchers = "(PROTOCOL=TCP)";
#SQL> show parameter dispatchers

#Configuring Clients to Use a Shared Server
#$ . oraenv
#$ cd $ORACLE_HOME/network/admin
#$ cp tnsnames.ora tnsnames.ora.4-2
#$ sqlplus system@test_ss
#$ sqlplus / as sysdba
#SQL> select dispatcher, server, saddr, queue from v$circuit;

#configure a client to use Oracle Connection Manager, and enable session multiplexing
