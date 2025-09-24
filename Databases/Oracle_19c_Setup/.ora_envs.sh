# ========================
# Oracle Multi-DB Profiles
# ========================

# Base Oracle directory
export ORACLE_BASE=/u01/app/oracle

# Function to switch DB
setdb() {
  case "$1" in
    orcl)
      export ORACLE_HOME=$ORACLE_BASE/product/19c/dbhome_1
      export ORACLE_SID=orcl
      export ORACLE_UNQNAME=$ORACLE_SID
      ;;
    testdb)
      export ORACLE_HOME=$ORACLE_BASE/product/19c/dbhome_1
      export ORACLE_SID=testdb
      export ORACLE_UNQNAME=$ORACLE_SID
      ;;
    sales)
      export ORACLE_HOME=$ORACLE_BASE/product/19c/dbhome_2
      export ORACLE_SID=sales
      export ORACLE_UNQNAME=$ORACLE_SID
      ;;
    *)
      echo "Usage: setdb {orcl|testdb|sales}"
      return 1
      ;;
  esac

  # Common variables
  export TNS_ADMIN=$ORACLE_HOME/network/admin
  export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$PATH
  export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
  export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
  export JAVA_HOME=$ORACLE_HOME/jdk
  export PATH=$JAVA_HOME/bin:$PATH

  # SQL*Plus prompt
  export SQLPROMPT="[$ORACLE_SID]> "

  echo "Switched to database: $ORACLE_SID (Home: $ORACLE_HOME)"
}
