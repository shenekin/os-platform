$ORACLE_HOME/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname CDBTEST -sid CDBTEST -createAsContainerDatabase true -numberOfPDBs 0 -useLocalUndoForPDBs true -responseFile NO_VALUE -totalMemory 1800
 -sysPassword oracle1qaz@WSX -systemPassword oracle1qaz@WSX -pdbAdminPassword oracle1qaz@WSX -emConfiguration DBEXPRESS -dbsnmpPassword oracle1qaz@WSX -emExpressPort 5502 -enableArchive true
 -recoveryAreaDestination /u01/app/oracle/fast_recovery_area -recoveryAreaSize 15000 -datafileDestination /u01/app/oracle/ordata

dbca -silent -createDatabase \
  -gdbName orcl \
  -templateName General_Purpose.dbc \
  -createAsContainerDatabase true \
  -numberOfPDBs 1 \
  -pdbName pdb1 \
  -createListener LISTENER:1521 \
  -sysPassword oracle19c \
  -systemPassword oracle19c \
  -pdbAdminPassword oracle19c \
  -datafileDestination /u01/app/oracle/oradata \
  -automaticMemoryManagement true \
  -storageType FS \
  -characterSet AL32UTF8 \
  -nationalCharacterSet AL16UTF16 \
  -databaseType MULTIPURPOSE \
  -emConfiguration NONE

