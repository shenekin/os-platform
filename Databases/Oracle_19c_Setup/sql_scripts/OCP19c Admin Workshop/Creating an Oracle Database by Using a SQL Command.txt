#Verify that CDBDEV is not already recorded in /etc/oratab
cat /etc/oratab
…
#
orclcdb:/u01/app/oracle/product/19.3.0/dbhome_1:N
rcatcdb:/u01/app/oracle/product/19.3.0/dbhome_1:N
CDBTEST:/u01/app/oracle/product/19.3.0/dbhome_1:N

vi CrCDBDEV.sql
…
CREATE DATABASE cdbdev
USER SYS IDENTIFIED BY password
USER SYSTEM IDENTIFIED BY password
EXTENT MANAGEMENT LOCAL
DEFAULT TEMPORARY TABLESPACE temp
DEFAULT TABLESPACE users
UNDO TABLESPACE undotbs1
ENABLE PLUGGABLE DATABASE;

#Set the oracle environment variables using the oraenv script.
$ . oraenv
ORACLE_SID = [CDBTEST] ? CDBDEV
ORACLE_HOME = [/home/oracle] ? /u01/app/oracle/product/19.3.0/dbhome_1
The Oracle base remains unchanged with value /u01/app/oracle

#Create an initialization parameter file named $ORACLE_HOME/dbs/initCDBDEV.ora
from the sample init.ora file.
$ cd $ORACLE_HOME/dbs
$ cp init.ora initCDBDEV.ora

#add the following initialization parameters to the end of the file
$ORACLE_HOME/dbs/initCDBDEV.ora.
$ vi initCDBDEV.ora
…
DB_CREATE_FILE_DEST='/u01/app/oracle/oradata'
ENABLE_PLUGGABLE_DATABASE=true

#With the editor still open, change the following initialization parameters to:
db_name='CDBDEV'
audit_file_dest='/u01/app/oracle/admin/CDBDEV/adump'
db_recovery_file_dest='/u01/app/oracle/fast_recovery_area'
diagnostic_dest='/u01/app/oracle'
dispatchers='(PROTOCOL=TCP) (SERVICE=CDBDEVXDB)'
control_files=('/u01/app/oracle/oradata/ora_control01.ctl','/u01
/app/oracle/fast_recovery_area/ora_control02.ctl')
compatible='19.0.0.0'

#Verify that the DB_CREATE_FILE_DEST, AUDIT_FILE_DEST, and the
DB_RECOVERY_FILE_DEST directories exist. The mkdir -p will create the directory if
it does not exist and does not report an error if the directory exists. If the ls command
returns anything, the directory exists.

$ mkdir -p /u01/app/oracle/admin/CDBDEV/adump
$ ls /u01/app/oracle/fast_recovery_area
CDBTEST ORCLCDB RCATCDB
$ ls /u01/app/oracle/oradata
CDBTEST ORCLCDB RCATCDB


Start the database instance in NOMOUNT mode.
$ sqlplus / AS SYSDBA
 STARTUP NOMOUNT
 
 Execute catalog and catproc scripts. The catalog.sql script takes ~ 3 minutes.
The catproc.sql script takes ~30 minutes
@$ORACLE_HOME/rdbms/admin/catalog.sql
@$ORACLE_HOME/rdbms/admin/catproc.sql

#Add a new entry in the /etc/oratab file with the following command.
$ echo "CDBDEV:/u01/app/oracle/product/19.3.0/dbhome_1:N" >>
/etc/oratab

#Verify the entry was added to the /etc/oratab file using the cat command:
$ cat /etc/oratab
orclcdb:/u01/app/oracle/product/19.3.0/dbhome_1:N
rcatcdb:/u01/app/oracle/product/19.3.0/dbhome_1:N
CDBTEST:/u01/app/oracle/product/19.3.0/dbhome_1:N
CDBDEV:/u01/app/oracle/product/19.3.0/dbhome_1:N

Verify that the characteristics of the database are correct.
a. Set the environment variables for your new database.
$ . oraenv
ORACLE_SID = [CDBDEV] ? CDBDEV
The Oracle base remains unchanged with value /u01/app/oracle

b. Verify that the database is a CDB.
$ sqlplus / as sysdba

SQL> select cdb from v$database;
CDB
c. Verify that the data files are in the correct location.
set pagesize 100
column name format a130
select name from v$datafile order by 1;

#Verify that the specified tablespaces are created for the CDB$ROOT.
associated with the current container, in this case the CDB$ROOT container. Selecting
from the CDB_TABLESPACES view would show all the tablespaces for all the open
containers.
SELECT tablespace_name, contents FROM dba_tablespaces;

#Verify that the EM Express port is correctly set
select dbms_xdb_config.gethttpsport() from dual;





