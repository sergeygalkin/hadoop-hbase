# Python script for decommissioning and recommissioning slave nodes
This is script for decommissioning and recommissioning slave nodes with interface on [Dailog](https://en.wikipedia.org/wiki/Dialog_\(software\))
[Decommissioning slave nodes](https://www.ibm.com/support/knowledgecenter/en/SSPT3X_4.1.0/com.ibm.swg.im.infosphere.biginsights.admin.doc/doc/iop_decom_nodes.htmls)
## Python
All requirements you can find in [requirements.txt](requirements.txt)
## Warining
Paths are hardcoded. 
* Hadoop settings are expecting in /opt/hadoop/
* Hadoop settings are expecting in /opt/hadoop/etc/ 
## Cluster settings
Working settings in my case
You should to add this settings in you hadoop configuration files
#### hdfs-site.xm
```xml
<property>
  <name>dfs.hosts.exclude</name>
  <value>/home/hadoop/hadoop/etc/hadoop/dfs.exclude</value>
</property>
```
#### yarn-site.xml
```xml
<property>
  <name>yarn.resourcemanager.nodes.exclude-path</name>        
  <value>/home/hadoop/hadoop/etc/hadoop/yarn.exclude</value>
  <final>true</final>   
</property>
```

