#In this practice, you perform the following tasks:
    #•	Examine the structure of the Automatic Diagnostic Repository (ADR)
    #•	View the alert log two ways—first through a text editor and then using the Automatic Diagnostic Repository Command Interpreter (ADRCI)
    #•	Enable DDL logging and log some DDL statements in the DDL log file

$ sqlplus / as sysdba
SQL> col name format a23 SQL> col value format a55
SQL> SELECT name, value FROM v$diag_info;

SQL> col name format a23
SQL> col value format a55
SQL> SELECT name, value FROM v$diag_info;

#View the Alert Log
cd /u01/app/oracle/diag/rdbms/orclcdb/orclcdb/alert

#Use ADRCI to View the Alert Log
$ adrci
adrci> show alert

#Log DDL Statements in the DDL Log File
$ sqlplus / as sysdba
SQL> ALTER SESSION SET CONTAINER = ORCLPDB1;
SQL> ALTER SESSION SET CONTAINER = ORCLPDB1;
SHOW PARAMETER enable ddl logging
SQL> ALTER SESSION SET enable_ddl_logging = TRUE;
SQL> create table test (name varchar2(15));
SQL> drop table test;
$ cd /u01/app/oracle/diag/rdbms/orclcdb/orclcdb/log
$ cat ddl_orclcdb.log

