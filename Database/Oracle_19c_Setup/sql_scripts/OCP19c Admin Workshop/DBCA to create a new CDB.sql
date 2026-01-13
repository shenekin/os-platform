#select a  CDB and starup
export ORACLE_SID=orclb
sqlplus / as sysdba
startup

#Verify that CDBTEST is not already recorded in /etc/oratab
cat /etc/oratab
…
Multiple entries with the same $ORACLE_SID are not allowed.
#  N not startup with OS
#  Y startup with System
orclcdb:/u01/app/oracle/product/19.3.0/dbhome_1:N      
rcatcdb:/u01/app/oracle/product/19.3.0/dbhome_1:N


gedit CrCDBTEST.sh
...
$ORACLE_HOME/bin/dbca -silent -createDatabase -
templateName General_Purpose.dbc -gdbname CDBTEST -sid
CDBTEST -createAsContainerDatabase true -numberOfPDBs 0 -
useLocalUndoForPDBs true -responseFile NO_VALUE -totalMemory
1800 -sysPassword password -systemPassword password -
pdbAdminPassword password -emConfiguration DBEXPRESS -
dbsnmpPassword password -emExpressPort 5502 -enableArchive
true -recoveryAreaDestination
/u01/app/oracle/fast_recovery_area -recoveryAreaSize 15000 -
datafileDestination /u01/app/oracle/oradata

chmod 755 CrCDBTEST.sh

#Verify that there is a new entry in /etc/oratab
cat /etc/oratab

#Verify that the database is a CDB
 . oraenv  . oraenv  or source oraenv
ORACLE_SID = [orclcdb] ? CDBTEST

#Verify that the data files are in the correct directory.
SQL> col name format a58
SQL> select name from v$datafile order by 1;

#Verify that the tablespaces are created
 col tablespace_name format a15
col contents format a15
SELECT tablespace_name, contents FROM dba_tablespaces;

#Verify that the port for EM Express is set correctly
SELECT dbms_xdb_config.gethttpsport() FROM dual;




 
 