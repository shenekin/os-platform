#V9832064-01.zip . As the oracle OS user, unzip this file in place to create /stage/client 
#$ cd /stage/client
#$ pwd
#/stage/client
#$ ./runInstaller

#echo "client:/u01/app/oracle/product/client_1:N" >> /etc/oratab
#$ tail -6 /etc/oratab

#$ . oraenv
#ORACLE_SID = [orclcdb] ? client

#$ cd $ORACLE_HOME/network/admin
#$ cp samples/cman.ora cman.ora
#$ mkdir -p /u01/app/oracle/cman/log
#$ mkdir -p /u01/app/oracle/cman/trace
#$ cd $ORACLE_HOME/network/admin
#$ cp samples/cman.ora cman.ora

#Change from	Change to
#<fqnhost>	localhost
#<lsnport>	1522
#<logdir>	/u01/app/oracle/cman/log
#<trcdir>	/u01/app/oracle/cman/trace
#max_gateway_processes	8
#min_gateway_processes	3

$ vi cman.ora
$ cmctl
#CMCTL> admin cman_localhost

#$ . oraenv
#ORACLE_SID = [orclcdb] ? orclcdb
#$ cd $ORACLE_HOME/network/admin
#SQL> alter system set remote_listener=LISTENER_CMAN;
#SQL> alter system register;


#Configuring the Oracle Database Server for Session Multiplexing
#$ . oraenv
#ORACLE_SID = [client] ? orclcdb
#$ sqlplus / as sysdba
#SQL> alter system set 
#SQL> column "OS USER" format A8 SQL> column username format a10
#SQL> column MACHINE format A8
#SQL> column PROGRAM format A30
SQL> SELECT SERVER, SUBSTR(USERNAME,1,15) "USERNAME", SUBSTR(OSUSER,1,8) "OS USER", SUBSTR(MACHINE,1,7)
"MACHINE",
SUBSTR(PROGRAM,1,35) "PROGRAM" FROM V$SESSION
WHERE TYPE='USER';

#$ . oraenv
#ORACLE_SID = [orclcdb] ? client
$ sqlplus system/password@C_ORCLCDB
SQL> SELECT SERVER, SUBSTR(USERNAME,1,15) "USERNAME",
SUBSTR(OSUSER,1,8) "OS USER", SUBSTR(MACHINE,1,7) "MACHINE",
SUBSTR(PROGRAM,1,35) "PROGRAM" FROM V$SESSION
WHERE TYPE='USER';

$ . oraenv
ORACLE_SID = [orclcdb] ? client
$ sqlplus system/password@C_ORCLCDB

SQL> SELECT SERVER, SUBSTR(USERNAME,1,15) "USERNAME",
SUBSTR(OSUSER,1,8) "OS USER", SUBSTR(MACHINE,1,7) "MACHINE",
SUBSTR(PROGRAM,1,35) "PROGRAM" FROM V$SESSION
WHERE TYPE='USER';
#SQL> col "QUEUE" format a12
#SQL> select saddr, circuit, dispatcher, server,
SUBSTR(QUEUE,1,8) "QUEUE", waiter from v$circuit;
SQL> col "QUEUE" format a12
SQL> select saddr, circuit, dispatcher, server,
SUBSTR(QUEUE,1,8) "QUEUE", waiter from v$circuit;











