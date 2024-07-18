# 一、服务器角色规划

沿用之前搭建好 HDFS 服务器集群，将YARN的角色组件部署。

| IP            | 主机名角色 | 组件                                                         |
| ------------- | ---------- | ------------------------------------------------------------ |
| 192.168.1.100 | master     | NameNode、SecondaryNameNode、**ResourceManager**、**ProxyServer**、**JobHistoryServer** |
| 192.168.1.101 | node1      | DataNode、**NodeManager**                                    |
| 192.168.1.102 | node2      | DataNode、**NodeManager**                                    |
| 192.168.1.103 | node3      | DataNode、**NodeManager**                                    |

# 二、MapReduce 配置

MapReduce 运行在 YARN 容器内，无需启动独立进程，修改配置后随 YARN 程序一同启动。

- mapred-env.sh 文件


```bash
# JDK 家目录
export JAVA_HOME=/opt/jdk1.8.0_361
# JobHistoryServer 分配运行内存 1G
export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=1024
# 设置记录的日志级别
export HADOOP_MAPRED_ROOT_LOGGER=INFO,RFA
```

- mapred-site.xml 文件

```xml
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
    <description>MapReduce的运行框架设置为 yarn</description>
  </property>

  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>master:10020</value>
    <description>任务历史服务器通信端口设置为 master:10020</description>
  </property>

  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>master:19888</value>
    <description>任务历史服务器web访问端口设置为 master:19888</description>
  </property>

  <property>
    <name>mapreduce.jobhistory.intermediate-done-dir</name>
    <value>/data/mr-history/tmp</value>
    <description>任务历史信息记录在HDFS文件系统中的临时目录路径</description>
  </property>

  <property>
    <name>mapreduce.jobhistory.done-dir</name>
    <value>/data/mr-history/done</value>
    <description>任务历史信息记录在HDFS文件系统中的路径</description>
  </property>
      
  <property>
    <name>yarn.app.mapreduce.am.env</name>
    <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
    <description>MapReduce HOME 设置为HADOOP HOME</description>
  </property>
      
  <property>
    <name>mapreduce.map.env</name>
    <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
    <description>MapReduce HOME 设置为HADOOP HOME</description>
  </property>
    
  <property>
    <name>mapreduce.reduce.env</name>
    <value>HADOOP_MAPRED_HOME=$HADOOP_HOME</value>
    <description>MapReduce HOME 设置为HADOOP HOME</description>
  </property>
</configuration>
```

# 三、Yarn 配置

- yarn-env.sh 文件


```bash
# JDK 家目录
export JAVA_HOME=/opt/jdk1.8.0_361
# hadoop 家目录
export HADOOP_HOME=/opt/hadoop-3.3.4
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_LOG_DIR=$HADOOP_HOME/logs
```

- yarn-site.xml 文件

```xml
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>master</value>
    <description>ResourceManager设置在master节点</description>
  </property>

  <property>
    <name>yarn.nodemanager.local-dirs</name>
    <value>/data/nm-local</value>
    <description>NodeManager中间数据本地文件系统存储路径</description>
  </property>
    
  <property>
    <name>yarn.nodemanager.log-dirs</name>
    <value>/data/nm-log</value>
    <description>NodeManager数据日志本地存储路径</description>
  </property>
    
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
    <description>为MapReduce程序开启Shuffle服务</description>
  </property>
      
  <property>
    <name>yarn.log.server.url</name>
    <value>http://master:19888/jobhistory/logs</value>
    <description>历史服务器URL</description>
  </property>

  <property>
    <name>yarn.web-proxy.address</name>
    <value>master:8089</value>
    <description>代理服务器主机和端口</description>
  </property>

  <property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
    <description>开启日志聚合</description>
  </property>

  <property>
    <name>yarn.nodemanager.remote-app-log-dir</name>
    <value>/tmp/logs</value>
    <description>程序日志HDFS文件系统存储路径</description>
  </property>

  <property>
    <name>yarn.resourcemanager.scheduler.class</name>
    <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
    <description>选择公平调度器</description>
  </property>

  <property>
    <name>yarn.nodemanager.log.retain-seconds</name>
    <value>10800</value>
    <description>在NodeManager上保留日志文件的默认时间（秒）仅在禁用日志聚合时适用</description>
  </property>
</configuration>
```


# 四、启动程序

分发 MapReduce 和 YARN 的配置文件

```bash
cd /opt/hadoop-3.3.4/etc/hadoop
scp -r mapred-env.sh mapred-site.xml yarn-env.sh yarn-site.xml node1:`pwd`
scp -r mapred-env.sh mapred-site.xml yarn-env.sh yarn-site.xml node2:`pwd`
scp -r mapred-env.sh mapred-site.xml yarn-env.sh yarn-site.xml node3:`pwd`
```

## 4.1 YARN 程序启动

**一键启动 YARN 集群：**`$HADOOP_HOME/sbin/start-yarn.sh`

- 会基于 `yarn-site.xml` 中配置的 `yarn.resourcemanager.hostname` 来决定在哪台机器上启动 `ResourceManager`

- 会基于 `workers` 文件配置的主机启动 `NodeManager`

**一键停止 YARN 集群：**`$HADOOP_HOME/sbin/stop-yarn.sh`

**在当前机器，单独启动或停止进程**

```bash
$HADOOP_HOME/bin/yarn --daemon start|stop resourcemanager|nodemanager|proxyserver
```

- start和stop决定启动和停止

- 可控制resourcemanager、nodemanager、proxyserver三种进程

## 4.2 历史服务器启动和停止

历史服务器需要单独的命令启动、停止：

````bash
$HADOOP_HOME/bin/mapred --daemon start|stop historyserver
````

yarn和历史服务器启动完成后，可以使用`jps`命令查看节点上的角色

```bash
# master 节点
JobHistoryServer
SecondaryNameNode
NameNode
WebAppProxyServer
ResourceManager

# node 节点
NodeManager
DataNode
```

在浏览器打开：http://master:8088 即可看到YARN集群的监控页面（ResourceManager的WEB UI）

![image-20240718173921555](./05-MapReduce&YARN%20%E9%83%A8%E7%BD%B2%E6%90%AD%E5%BB%BA/image-20240718173921555.png)