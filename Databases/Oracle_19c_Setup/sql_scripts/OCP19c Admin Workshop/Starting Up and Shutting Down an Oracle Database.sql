#The OS command pgrep -lf smon will show any databases that are started, and pgrep -lf tns will report any listener processes that are running
pgrep -lf   and pgrep -lf
# As the oracle OS user, source the oraenv script

!mkdir /u01/app/oracle/oradata/ORCLCDB/orclpdb3

SQL> CREATE PLUGGABLE DATABASE ORCLPDB3
2 ADMIN USER admin IDENTIFIED BY cloud_4U ROLES=(CONNECT)
SQL> alter PLUGGABLE DATABASE ORCLPDB3 open;

SQL> create user test identified by cloud_4U; 
SQL> grant dba to test; 
SQL> create table test.bigtab (label varchar2(30)); 
SQL> begin
    for i in 1..10000 loop
    insert into test.bigtab values ('DATA FROM test.bigtab');
    commit;
    end loop;
    end;
7	/

SQL> SHUTDOWN IMMEDIATE;
SQL> SHOW USER 
SQL> show con_name
SQL> startup nomount;
SQL> alter database mount;
SQL> alter database open;
show con_name;
show user;
SQL> COLUMN name FORMAT A10
SQL> SELECT con_id, name, open_mode FROM v$pdbs;

SQL> COLUMN con_name format a16
SQL> SELECT con_id, con_name, state FROM DBA_PDB_SAVED_STATES;

#Remove the saved states
SQL> alter pluggable database all close;
SQL> alter pluggable database all save state;
SQL> SELECT con_id, con_name, state FROM DBA_PDB_SAVED_STATES;
SQL> SHUTDOWN IMMEDIATE;
SQL> STARTUP

SQL> alter pluggable database all open;
SQL> alter pluggable database all save state;
SQL> select con_id, con_name, state from dba_pdb_saved_states;
SQL> alter pluggable database orclpdb3 close;
SQL> show pdbs;
SQL> drop pluggable database orclpdb3 including datafiles;







