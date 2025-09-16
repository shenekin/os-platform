source oraenv
sqlplus / as sysdba
column name format a30
column value format a20

#Check if the database is using AMM or ASMM
select name,value  from v$parameter where name in ('sga_target','sga_max_size','memory_target','memory_max_target') ORDER by 1;
select name,value from v$parameter where name in ('shared_pool_size','large_pool_size','db_cache_size','java_pool_size','streams_pool_size');

#View v$memeory_dynamic_components
desc v$memory_dynamic_components

#how much memory is assigned to each pool/cache
column component format a30
select component,current_size,min_size,max_size,last_oper_type from v$memory_dynamic_components order by 1 desc;

#Both ASMM and AMM update the spfile with the current memory configuration information.Create a readable version of the spfile to view the contents
create pfile='/tmp/initorclcb.ora' from spfile;
!cat /tmp/initorclcb.ora

desc v$memory_resize_ops

#Display the history of all memory resize operation
column component format a20
select component,oper_type,initial_size,target_size,final_size,end_time from v$memory_resize_ops where OPER_TYPE !='STATIC' order by end_time;


