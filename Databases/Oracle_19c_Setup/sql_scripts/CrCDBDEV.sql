CREATE DATABASE cdbdev
   USER SYS IDENTIFIED BY "SysPassw0rd"
   USER SYSTEM IDENTIFIED BY "SysPassw0rd"
   LOGFILE GROUP 1 ('/u01/app/oracle/oradata/cdbdev/redo01.log') SIZE 200M,
           GROUP 2 ('/u01/app/oracle/oradata/cdbdev/redo02.log') SIZE 200M,
           GROUP 3 ('/u01/app/oracle/oradata/cdbdev/redo03.log') SIZE 200M
   MAXLOGFILES 5
   MAXDATAFILES 100
   DATAFILE '/u01/app/oracle/oradata/cdbdev/system01.dbf' SIZE 700M REUSE
   SYSAUX DATAFILE '/u01/app/oracle/oradata/cdbdev/sysaux01.dbf' SIZE 550M REUSE
   DEFAULT TEMPORARY TABLESPACE temp
      TEMPFILE '/u01/app/oracle/oradata/cdbdev/temp01.dbf' SIZE 100M REUSE
   DEFAULT TABLESPACE users
      DATAFILE '/u01/app/oracle/oradata/cdbdev/users01.dbf' SIZE 100M REUSE
   UNDO TABLESPACE undotbs1
      DATAFILE '/u01/app/oracle/oradata/cdbdev/undotbs01.dbf' SIZE 200M REUSE
   EXTENT MANAGEMENT LOCAL
   ENABLE PLUGGABLE DATABASE
   SEED FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/cdbdev/', '/u01/app/oracle/oradata/cdbdev/pdbseed/');
