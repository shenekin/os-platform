show CON_NAME
select username,common,con_id from cdb_users where common='NO'
order by username
select username,common,con_id from cdb_users where common='No' ORDER by username

select file_name,file_id,tablespace_name,con_id from cdb_data_files

alter session set container=orclpdb

select file_name,file_id,tablespace_name,con_id from cdb_temp_files

alter session set container=orclpdb;

#PDB save status
alter pluggable database open
alter pluggable database orclpdb save state

#Operate PDB

ALTER SESSION SET CONTAINER=CDB$ROOT;


ALTER PLUGGABLE DATABASE PDB$SEED OPEN;


ALTER SESSION SET CONTAINER=pdb1;


#Create PDB from PDBSEED

CREATE PLUGGABLE DATABASE pdblab 
    ADMIN USER pdb_admin IDENTIFIED BY oracle19c
    ROLES = (dba)
    DEFAULT TABLESPACE users
    DATAFILE '/u01/app/oracle/oradata/ORCL/pdblab/pdblab01.dbf' SIZE 250M AUTOEXTEND ON
    FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/ORCL/pdbseed/',
                         '/u01/app/oracle/oradata/ORCL/pdblab/');
