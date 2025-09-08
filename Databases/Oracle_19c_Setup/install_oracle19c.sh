#!/bin/bash
# ============================================================
# Oracle Database 19c One-Click Installation Script
# Tested on Oracle Linux 7.9
# Author: Ekin
# ============================================================
#This script will:

	#Install dependencies

	#Create Oracle user environment

	#Extract Oracle software

	#Install database software (silent)

	#Run required root scripts

	#Configure listener

	#Create a CDB with one PDB

ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=$ORACLE_BASE/product/19.0.0/dbhome_1
ORACLE_SID=orcl
ORACLE_PDB=pdb1
ORACLE_PWD=Oracle123

echo ">>> Updating system packages..."
yum update -y

echo ">>> Installing Oracle prerequisites..."
yum install -y oracle-database-preinstall-19c unzip

echo ">>> Creating Oracle directories..."
mkdir -p $ORACLE_HOME
mkdir -p /u01/app/oraInventory
chown -R oracle:oinstall /u01
chmod -R 775 /u01

echo ">>> Setting environment variables for Oracle user..."
cat <<EOF >> /home/oracle/.bash_profile

# Oracle Settings
export ORACLE_BASE=$ORACLE_BASE
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export LANG=en_US.UTF-8
EOF

echo ">>> Preparing Oracle software..."
su - oracle -c "unzip -q /tmp/LINUX.X64_193000_db_home.zip -d $ORACLE_HOME"

echo ">>> Installing Oracle Database software (silent mode)..."
su - oracle -c "cd $ORACLE_HOME && ./runInstaller -silent -ignorePrereqFailure \
    -responseFile $ORACLE_HOME/install/response/db_install.rsp \
    oracle.install.option=INSTALL_DB_SWONLY \
    ORACLE_HOME=$ORACLE_HOME \
    ORACLE_BASE=$ORACLE_BASE \
    oracle.install.db.InstallEdition=EE \
    oracle.install.db.OSDBA_GROUP=dba \
    oracle.install.db.OSOPER_GROUP=oper \
    oracle.install.db.OSBACKUPDBA_GROUP=dba \
    oracle.install.db.OSDGDBA_GROUP=dba \
    oracle.install.db.OSKMDBA_GROUP=dba \
    oracle.install.db.OSRACDBA_GROUP=dba \
    DECLINE_SECURITY_UPDATES=true"

echo ">>> Running root scripts..."
/u01/app/oraInventory/orainstRoot.sh
$ORACLE_HOME/root.sh

echo ">>> Configuring Oracle Net Listener..."
su - oracle -c "netca -silent -responseFile $ORACLE_HOME/assistants/netca/netca.rsp"

echo ">>> Creating Oracle Database (silent mode)..."
su - oracle -c "dbca -silent -createDatabase \
    -templateName General_Purpose.dbc \
    -gdbname $ORACLE_SID -sid $ORACLE_SID \
    -createAsContainerDatabase true \
    -numberOfPDBs 1 -pdbName $ORACLE_PDB \
    -createListener LISTENER,1521 \
    -responseFile NO_VALUE \
    -characterSet AL32UTF8 \
    -memoryPercentage 30 \
    -emConfiguration DBEXPRESS \
    -emExpressPort 5500 \
    -sysPassword $ORACLE_PWD \
    -systemPassword $ORACLE_PWD \
    -pdbAdminPassword $ORACLE_PWD"

echo ">>> Installation complete!"
echo ">>> Connect as: sqlplus / as sysdba"