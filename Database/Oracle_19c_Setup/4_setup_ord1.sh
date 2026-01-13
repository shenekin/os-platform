#!/bin/bash

# ==============================
# Oracle Environment Variables
# ==============================
export ORACLE_SID=ord1
export ORACLE_HOME=/or01/app/oracle/product/19c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

INIT_FILE="$ORACLE_HOME/dbs/init${ORACLE_SID}.ora"

echo "Using ORACLE_SID=$ORACLE_SID"
echo "Using ORACLE_HOME=$ORACLE_HOME"
echo "Creating PFILE: $INIT_FILE"

# ==============================
# Create init.ora
# ==============================
cat > "$INIT_FILE" <<EOF
db_name=$ORACLE_SID
memory_target=1G
control_files=('/or01/app/oracle/oradata/$ORACLE_SID/control01.ctl','/or01/app/oracle/oradata/$ORACLE_SID/control02.ctl')
EOF

echo "PFILE created at $INIT_FILE"

# ==============================
# Startup NOMOUNT and Create SPFILE
# ==============================
sqlplus / as sysdba <<EOF
STARTUP NOMOUNT PFILE='$INIT_FILE';
CREATE SPFILE FROM PFILE='$INIT_FILE';
SHUTDOWN IMMEDIATE;
STARTUP;
EOF

echo "Oracle instance started successfully with SPFILE!"

# ==============================
# Next Step: CREATE DATABASE (uncomment below if ready)
# ==============================
sqlplus / as sysdba <<EOF
 CREATE DATABASE $ORACLE_SID
     USER SYS IDENTIFIED BY oracle19c
     USER SYSTEM IDENTIFIED BY oracle19c
     LOGFILE GROUP 1 ('/or01/app/oracle/oradata/$ORACLE_SID/redo01.log') SIZE 200M,
             GROUP 2 ('/or01/app/oracle/oradata/$ORACLE_SID/redo02.log') SIZE 200M
     MAXLOGFILES 5
     MAXLOGMEMBERS 5
     MAXDATAFILES 100
     CHARACTER SET AL32UTF8
     NATIONAL CHARACTER SET AL16UTF16
     DATAFILE '/or01/app/oracle/oradata/$ORACLE_SID/system01.dbf' SIZE 500M REUSE
     SYSAUX DATAFILE '/or01/app/oracle/oradata/$ORACLE_SID/sysaux01.dbf' SIZE 500M REUSE
     DEFAULT TABLESPACE users
     DATAFILE '/or01/app/oracle/oradata/$ORACLE_SID/users01.dbf' SIZE 200M REUSE
     DEFAULT TEMPORARY TABLESPACE temp
     TEMPFILE '/or01/app/oracle/oradata/$ORACLE_SID/temp01.dbf' SIZE 200M REUSE
     UNDO TABLESPACE undotbs
     DATAFILE '/or01/app/oracle/oradata/$ORACLE_SID/undotbs01.dbf' SIZE 200M REUSE;
EOF

# echo "Database created successfully!"




#!/bin/bash
# =========================================
# Oracle 19c Automated DB + Listener Setup
# =========================================
export ORACLE_SID=ord1
export ORACLE_HOME=/or01/app/oracle/product/19c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH

DATA_DIR=/or01/app/oracle/oradata/$ORACLE_SID
INIT_FILE=$ORACLE_HOME/dbs/init${ORACLE_SID}.ora

echo ">>> Setting up Oracle Database: $ORACLE_SID"
echo ">>> ORACLE_HOME=$ORACLE_HOME"
echo ">>> Data directory=$DATA_DIR"

# ==============================
# Create required directories
# ==============================
mkdir -p $DATA_DIR
mkdir -p $ORACLE_HOME/dbs

# ==============================
# Create init.ora (PFILE)
# ==============================
cat > "$INIT_FILE" <<EOF
db_name=$ORACLE_SID
memory_target=1G
control_files=('$DATA_DIR/control01.ctl','$DATA_DIR/control02.ctl')
EOF
echo ">>> Created PFILE: $INIT_FILE"

# ==============================
# Start Oracle NOMOUNT + Create SPFILE
# ==============================
sqlplus / as sysdba <<EOF
STARTUP NOMOUNT PFILE='$INIT_FILE';
CREATE SPFILE FROM PFILE='$INIT_FILE';
SHUTDOWN IMMEDIATE;
STARTUP NOMOUNT;
EOF

# ==============================
# Create Database
# ==============================
sqlplus / as sysdba <<EOF
CREATE DATABASE $ORACLE_SID
   USER SYS IDENTIFIED BY oracle19c
   USER SYSTEM IDENTIFIED BY oracle19c
   LOGFILE GROUP 1 ('$DATA_DIR/redo01.log') SIZE 200M,
           GROUP 2 ('$DATA_DIR/redo02.log') SIZE 200M
   MAXLOGFILES 5
   MAXLOGMEMBERS 5
   MAXDATAFILES 100
   CHARACTER SET AL32UTF8
   NATIONAL CHARACTER SET AL16UTF16
   DATAFILE '$DATA_DIR/system01.dbf' SIZE 500M REUSE
   SYSAUX DATAFILE '$DATA_DIR/sysaux01.dbf' SIZE 500M REUSE
   DEFAULT TABLESPACE users
   DATAFILE '$DATA_DIR/users01.dbf' SIZE 200M REUSE
   DEFAULT TEMPORARY TABLESPACE temp
   TEMPFILE '$DATA_DIR/temp01.dbf' SIZE 200M REUSE
   UNDO TABLESPACE undotbs
   DATAFILE '$DATA_DIR/undotbs01.dbf' SIZE 200M REUSE;
EOF

# ==============================
# Create Listener
# ==============================
lsnrctl stop LISTENER_ORD1 > /dev/null 2>&1
netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp <<EOF
LISTENER_NAMES="LISTENER_ORD1"
PORT_NUMBER=1521
EOF

# ==============================
# Register Instance with Listener
# ==============================
lsnrctl start LISTENER_ORD1
sqlplus / as sysdba <<EOF
ALTER SYSTEM REGISTER;
EOF

echo ">>> Oracle database $ORACLE_SID created and listener LISTENER_ORD1 configured!"
