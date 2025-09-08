<<<<<<< HEAD
/bin/bash
ALTER PLUGGABLE DATABASE ORCLPDB3 CLOSE;
!mkdir /u01/app/oracle/oradata/ORCL/ORCLCDB/orclpdb3
=======
#!/bin/bash
# Script to create PDB3 in CDBDEV

export ORACLE_SID=cdbdev
export ORACLE_HOME=/u01/app/oracle/product/19/db_1/
export PATH=$ORACLE_HOME/bin:$PATH
>>>>>>> d757695a12ca04d796614fbeac5ec172bff5b2b2

sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Create PDB3
CREATE PLUGGABLE DATABASE pdb3
  ADMIN USER pdbadmin IDENTIFIED BY Oracle123
  FILE_NAME_CONVERT=(
    '/u01/app/oracle/oradata/ORCL/cdbdev/pdbseed/',
    '/u01/app/oracle/oradata/ORCL/cdbdev/pdb3/'
  );

-- Open it
ALTER PLUGGABLE DATABASE pdb3 OPEN;
ALTER PLUGGABLE DATABASE pdb3 SAVE STATE;

EXIT
EOF
