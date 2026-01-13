#you will configure network files so that you can access a database on another server. You will also configure access to a PDB
. oraenv
more /etc/oratab
cd $ORACLE_HOME/network/admin
hostname -f
$ netmgr
#Create a net service name, MyPDB1, for ORCLPDB1 by using Oracle Net Manager.
#	Invoke Oracle Net Manager.
#	Expand Local and select Service Naming.
#	Click the green plus sign.
#	In the Service Name field, enter MY1PDB1 and then click Next.
#	Select TCP/IP and then click Next.
#	In the Host Name field, enter the fully qualified host name (hint, step 4 last section) . In the Port Number field, enter 1521 and then click Next.
#	In the Service field, enter ORCLPDB1 .
#	Under Connection type, select Dedicated Server and then click Next.
#	Click Test.
#	In the Connection test dialog box, the test failed because scott does exist. Click Change Login and Change Login Box, enter username system and password. See Appendix - Product-Specific Credentials for the password. Click OK.
#	Click Test.
#	When " The connection test was successful" message appears, click Close and then Finish.
#Click File > Save Network Configuration.

cd $ORACLE_HOME/network/admin
cat tnsnames.ora
tnsping mypdb1
SQL> SHOW con_name
#Configuring and Administering the Listener
$ . oraenv
#ORACLE_SID = [oracle] ? orclcdb
#SQL> SHOW PARAMETER	INSTANCE_NAME	
#SQL> show parameter service_names
#SQL> show parameter local_listener
#SQL> show parameter remote_listener
#$ cd $ORACLE_HOME/network/admin
#$ lsnrctl
#LSNRCTL> show current_listener
#LSNRCTL> services
#LSNRCTL> show log_status
#cd $ORACLE_HOME/network/admin
#$ cp tnsnames.ora tnsnames.ora.3-2
#$ . oraenv
#SQL> SHOW PARAMETER local_listener
#SQL> select isses_modifiable, issys_modifiable from v$parameter where name='local_listener';
#SQL> alter system set local_listener="LISTENER_ORCLCDB,LISTENER2";
#SQL> show parameter local_listener
#$ cd $ORACLE_HOME/network/admin
#$ cp listener.ora listener.old
#LSNRCTL> status LISTENER2
#LSNRCTL> start listener2
#LSNRCTL> status listener2

#Connecting to a Database Service Using the New Listener
#$ sqlplus system/password@localhost:1561/orclcdb
