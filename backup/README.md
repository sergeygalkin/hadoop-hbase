# Scripts for backup and restore hbase tables to s3
## Throughput
'-bandwidth 4 -mappers 4' in my case is 68Mb/s. Be careful with this
options. With big numbers I had failed export "Error:
org.apache.http.NoHttpResponseException: The target server failed
to respond at.."

## Possible issues
### java.io.FileNotFoundException: ... (Is a directory) in userlogs
In application stderr looks like this
```
log4j:ERROR setFile(null,true) call failed.
java.io.FileNotFoundException: ../userlogs/application_1486918034142_0001/container_1486918034142_0001_01_000001 (Is a directory)
```

**This is not a big issue you may ignore it**

### Invalid resource request, requested memory ...
Can find it in yarn-hadoop-resourcemanager.log, looks like this
```
2017-02-12 12:00:04,592 INFO org.apache.hadoop.yarn.server.resourcemanager.rmapp.RMAppImpl: application_1486551942089_0031 State change from ACCEPTED to RUNNING
2017-02-12 12:00:05,615 WARN org.apache.hadoop.yarn.server.resourcemanager.ApplicationMasterService: Invalid resource ask by application appattempt_1486551942089_0031_000001
org.apache.hadoop.yarn.exceptions.InvalidResourceRequestException: Invalid resource request, requested memory < 0, or requested memory > max configured, requestedMemory=12288, maxMemory=8192
        at org.apache.hadoop.yarn.server.resourcemanager.scheduler.SchedulerUtils.validateResourceRequest(SchedulerUtils.java:268)
```

Memory setting should be increased

### Tasks hangs in PENDING state
Memory setting should be increased

## Cluster settings
### Hadoop memory settings for memory
Working settings in my case
#### mapred-site.xml
```xml
<property>
  <name>mapreduce.map.memory.mb</name>
  <value>12288</value>
</property>
<property>
  <name>mapreduce.reduce.memory.mb</name>
  <value>24576</value>
</property>
<property>
    <name>mapred.child.java.opts</name>
    <value>-Xmx1024m</value>
</property>
```
#### yarn-site.xml
```xml
<property>
  <name>yarn.nodemanager.resource.memory-mb</name>
  <value>26624</value>
</property>
<property>
  <name>yarn.scheduler.minimum-allocation-mb</name>
  <value>1024</value>
</property>
<property>
  <name>yarn.scheduler.maximum-allocation-mb</name>
  <value>24576</value>
</property>
```
