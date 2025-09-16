#how the Oracle Database server uses initialization parameter files to start the database instance
$ . oraenv
ORACLE_SID = [orclcdb] ? orclcdb
$ sqlplus / as sysdba
show parameter spfile

#View the init.ora file. This is the sample text initialization parameter file (PFILE) provided with the Oracle Database installation.
SQL> host
cd $ORACLE_HOME/dbs

more init.ora

SQL> create pfile='$ORACLE_HOME/dbs/initorclcdb.ora' from spfile;
$ more initorclcdb.ora

SQL> shutdown immediate

$ cd $ORACLE_HOME/dbs
SQL> show parameter spfile;
mv orig_spfileorclcdb.ora spfileorclcdb.ora

SQL> show parameter spfile;
$ sqlplus / as sysdba
SQL> show	parameter	db_name	;
SQL> show parameter db_domain;

SQL> show parameter db_recovery_file_dest
SQL> show parameter sga;

show parameter undo tablespace
SHOW PARAMETER compatible
show parameter control files
show parameter processes
show parameter sessions
show parameter transactions
show parameter db_files
show parameter commit_logging
show parameter commit_wait
show parameter shared_pool_size
show parameter db_block_size
show parameter db_cache_size
show parameter undo_management
show parameter memory_target
show parameter pga_aggregate_target

#Query Views for Parameter Values
set pagesize 100
select table_name from dictionary where table_name like '%PARAMETER%';
describe v$parameter;
col name format a35
col value format a20
select name, issys_modifiable, value from v$parameter
order by name;
select name, value from v$parameter where name like '%pool%';
describe v$spparameter
select name, value from v$spparameter;
describe v$parameter2
select name, value from v$parameter2;
describe v$system_parameter
select name, value from v$system_parameter;

#Modifying Initialization Parameters by Using SQL*Plus
    #•	Session-level parameter
    #•	Dynamic system-level parameter
    #•	Static system-level parameter

$ sqlplus / as sysdba
SQL> column NAME FORMAT A18
SQL> column VALUE Format A20
SQL> SELECT name, isses_modifiable, issys_modifiable, ispdb_modifiable, value
FROM v$parameter
WHERE name = 'nls_date_format';
SQL> SELECT name, value FROM v$parameter WHERE name = 'nls_territory';
SQL> ALTER SESSION SET container = ORCLPDB1;
SQL> SELECT last_name, hire_date FROM hr.employees;
SQL> ALTER SESSION SET nls_date_format = 'mon dd yyyy';
SQL> SELECT last_name, hire_date FROM hr.employees;
SQL> SHOW PARAMETER	nls_date_format	
SQL> ! hostname -f
SQL> ! lsnrctl status| grep tcp| grep PORT
SQL> Connect / as sysdba
SQL> col name format a20
SQL> col network_name format a20
SQL> SELECT name, network_name FROM V$SERVICES WHERE name = 'orclpdb1';
SQL> connect system/password@//<full hostname>:<port number>/<service name>
SQL> SELECT last_name, hire_date FROM hr.employees;
SQL> SHOW PARAMETER nls_date_format
SQL> column name format A20
SQL> column value format A20
SQL> SELECT name, isses_modifiable, issys_modifiable, value FROM v$parameter WHERE name = 'job_queue_processes';
SQL> ALTER SYSTEM SET job_queue_processes=15 SCOPE=BOTH;
SQL> SHOW PARAMETER job
SQL> SHUTDOWN IMMEDIATE
SQL> SHOW PARAMETER job
SQL> col name format a30
SQL> SELECT name, isses_modifiable, issys_modifiable, value FROM v$parameter WHERE name = 'sec_max_failed_login_attempts';
SQL> ALTER SYSTEM SET sec_max_failed_login_attempts = 2 COMMENT='Reduce for tighter security.' SCOPE=SPFILE;
SQL> SHOW PARAMETER sec_max
SQL> shutdown immediate
SQL> SHOW PARAMETER sec_max
SQL> col name format a30
SQL> col update_comment format a30
SQL> SELECT name, update_comment
FROM v$parameter WHERE name='sec_max_failed_login_attempts';
SQL> ALTER SYSTEM SET sec_max_failed_login_attempts = 3 COMMENT='' SCOPE=SPFILE;”

