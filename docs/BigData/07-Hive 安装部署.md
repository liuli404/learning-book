# 一、服务器规划

Hive 为单机程序，选择一台服务器搭建即可，另外元数据需要存储在 MySQL 中，需要另一台服务器。

| IP           | 主机名角色 | 组件  |
| ------------ | ---------- | ----- |
| 192.168.1.99 | hive       | Hive  |
| 192.168.1.50 | mysql      | MySQL |

服务器的环境初始化步骤与 HDFS 服务器集群一致，只是多了hosts文件解析

```bash
cat >> /etc/hosts << EOF
192.168.1.100 master
192.168.1.101 node1
192.168.1.102 node2
192.168.1.103 node3
192.168.1.99 hive
192.168.1.50 mysql
EOF
```

**原 HDFS 集群也需要增加 hive 与 mysql 主机的解析**

# 二、MySQL 数据库搭建

1. 下载安装包
```bash
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar
```
```bash
tar -xvf mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar
```
2. 卸载自带的 `mariadb` 

```bash
yum remove -y mariadb* && rm -f /etc/my.cnf
```
3. 安装 `rpm` 包

注意安装顺序要正确
```bash
rpm -ivh mysql-community-common-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-libs-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-client-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-server-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-libs-compat-5.7.35-1.el7.x86_64.rpm
```

4. 启动并设置为开机自启

```bash
systemctl start mysqld.service && systemctl enable mysqld.service
```

5. 获取 `root` 初始密码

```bash
grep password /var/log/mysqld.log | sed 's/.*\(............\)$/\1/'
```

6. 修改 `root` 用户密码

```sql
# 方法一：使用 mysqladmin 工具修改
[root@mysql ~]# mysqladmin -u root password '123456Aa.' -p
Enter password: # 这里输入旧密码

# 方法二：进入 mysql 命令行，使用 SQL 语句修改
[root@mysql ~]# mysql -u root -p
Enter password: # 这里输入旧密码
mysql> set password for root@localhost = password('123456Aa.');
mysql> flush privileges;
```

7. 授权 `root` 用户远程登录

```sql
mysql> grant all privileges on *.* to 'root'@'%' identified by '123456Aa.';

mysql> flush privileges;
```

# 三、Hive 配置部署

上传 Hive 安装包并解压：

```bash
tar -zxvf apache-hive-3.1.3-bin.tar.gz -C /opt/
```

Hive 的运行依赖于 Hadoop（HDFS、MapReduce、YARN都依赖）同时涉及到 HDFS 文件系统的访问，所以需要配置 Hadoop 的代理用户，即设置 hadoop 用户允许代理（模拟）其它用户。

配置如下内容在 Hadoop 的 `core-site.xml` 中，并分发到其它节点，且重启 HDFS 集群。

```xml
  <property>
    <name>hadoop.proxyuser.hadoop.hosts</name>
    <value>*</value>
  </property>

  <property>
    <name>hadoop.proxyuser.hadoop.groups</name>
    <value>*</value>
  </property>
```

配置 mysql 驱动：

```bash
# 放入 Hive 安装文件夹的 lib 目录内
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.34/mysql-connector-java-5.1.34.jar -O /opt/apache-hive-3.1.3-bin/lib/mysql-connector-java-5.1.34.jar
```

生成配置文件

```bash
cd /opt/apache-hive-3.1.3-bin/conf
cp hive-env.sh.template hive-env.sh
cp hive-default.xml.template hive-site.xml
```

- hive-env.sh 文件

添加以下内容

```bash
export HADOOP_HOME=/opt/hadoop-3.3.4
export HIVE_CONF_DIR=/opt/apache-hive-3.1.3-bin/conf
export HIVE_AUX_JARS_PATH=/opt/apache-hive-3.1.3-bin/lib
```

- hive-site.xml

```xml
<configuration>
    
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mysql://mysql:3306/hive?createDatabaseIfNotExist=true&amp;useSSL=false&amp;useUnicode=true&amp;characterEncoding=UTF-8</value>
    <description>Mysql连接信息</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>com.mysql.jdbc.Driver</value>
    <description>Mysql驱动版本</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>root</value>
    <description>Mysql用户名</description>
  </property>

  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>123456Aa.</value>
    <description>Mysql用户密码</description>
  </property>

  <property>
    <name>hive.server2.thrift.bind.host</name>
    <value>hive</value>
    <description>thrift服务绑定的主机</description>
  </property>

  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://hive:9083</value>
    <description>hive</description>
  </property>

  <property>
    <name>hive.metastore.event.db.notification.api.auth</name>
    <value>false</value>
    <description>hive api接口鉴权功能关闭</description>
  </property>

  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://master:8020</value>
    <description>远程 HDFS 的地址</description>
  </property>
    
  <property>
    <name>hive.exec.local.scratchdir</name>
    <value>/opt/apache-hive-3.1.3-bin/tmp/</value>
    <description>Hive作业的本地暂存空间</description>
  </property>
    
  <property>
    <name>hive.downloaded.resources.dir</name>
    <value>/opt/apache-hive-3.1.3-bin/tmp/${hive.session.id}_resources</value>
    <description>远程文件系统中添加资源的临时本地目录</description>
  </property>
    
  <property>
    <name>hive.server2.logging.operation.log.location</name>
    <value>/opt/apache-hive-3.1.3-bin/tmp/operation_logs</value>
    <description>如果启用了日志记录功能，则配置存储操作日志的顶级目录</description>
  </property>
    
</configuration>
```

即使 Hive 和 HDFS 不在同一台机器上，Hive 仍然需要访问 Hadoop 客户端。因此，需要在 Hive 机器上**安装 Hadoop 客户端**，并设置环境变量。jdk 和 hadoop 可直接从配置好的 HDFS 集群机器上 copy 过来。

hive 环境变量配置 `/etc/profile`

```bash
export HIVE_HOME=/opt/apache-hive-3.1.3-bin/
export PATH=$PATH:$HIVE_HOME/bin

export JAVA_HOME=/opt/jdk1.8.0_361
export PATH=$JAVA_HOME/bin:$PATH

export HADOOP_HOME=/opt/hadoop-3.3.4
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
```

```bash
source /etc/profile
```

# 四、Hive 服务启动

在MySQL中创建 hive 元数据存放的数据库：

```sql
create database hive charset utf8;
```

目录授权给 hadoop用户

```bash
chown -R hadoop:hadoop /opt/apache-hive-3.1.3-bin
chown -R hadoop:hadoop /opt/jdk1.8.0_361
chown -R hadoop:hadoop /opt/hadoop-3.3.4
```

```bash
su - hadoop
```

## 4.1 hive元数据初始化

```bash
schematool -initSchema -dbType mysql -verbos
```

*如果提示特殊字符报错，进入 hive-site.xml 把不支持的字符删掉就行。*

执行完毕后，出现以下提示说明元数据表在mysql中初始化完成。

```bash
Initialization script completed
schemaTool completed
```

## 4.2 启动 hvie 元数据管理服务

**前台启动**，终端关闭则服务中断。

```bash
hive --service metastore
```

**后台启动**，放在后台运行，终端关闭不影响。

```bash
nohup hive --service metastore >> ${HIVE_HOME}/metastore.log 2>&1 &
```

## 4.3 启动 hive 客户端

hive 的客户端有两种形式：

- Hive Shell 客户端（Hive 内置功能）

```bash
# Hive Shell 客户端，可直接写SQL
hive
```

- 第三方客户端（Hive 开启 ThriftServer 服务，让三方客户端连接） 

```bash
# Hive ThriftServer 方式，不可直接写SQL，只提供API方式，可使用外部客户端连接
nohup hive --service hiveserver2 >> ${HIVE_HOME}/hiveserver2.log 2>&1 &
```

# 五、Hive 客户端

 Hive 一共有两种客户端：

- hive，即Hive的Shell客户端，可以直接写SQL。比较难用，一般不用。

- HiveServer2，是 Hive 内置的一个 ThriftServer 服务，提供 Thrift 端口供其它客户端链接，协议的地址是：`jdbc:hive2://hive:10000`
  - Hive 内置的 beeline 客户端工具（命令行工具）
  - 图形化 SQL 工具，如 DataGrip、DBeaver、Navicat等

![image-20240719173500466](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719173500466.png)

## 5.1 beeline

Beeline 是 Hive 安装包中提供的 JDBC 的客户端，可通过 JDBC 协议和 Hiveserver2 服务进行通信。

```bash
[hadoop@hive ~]$ beeline 
Beeline version 3.1.3 by Apache Hive
beeline> ! connect jdbc:hive2://hive:10000 # 访问 HiveServer2 的地址
Connecting to jdbc:hive2://hive:10000
Enter username for jdbc:hive2://hive:10000: hadoop # 用户名，要有 HDFS 的操作权限
Enter password for jdbc:hive2://hive:10000: # 密码为空
Connected to: Apache Hive (version 3.1.3)
Driver: Hive JDBC (version 3.1.3)
Transaction isolation: TRANSACTION_REPEATABLE_READ
0: jdbc:hive2://hive:10000> show databases;
+----------------+
| database_name  |
+----------------+
| default        |
+----------------+
1 row selected (1.217 seconds)
```

## 5.2 DBeaver

一款开源的数据库管理软件，下载地址：https://dbeaver.io/download/

**1、新建Hive连接**

![image-20240719175017979](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719175017979.png)

**2、配置 hive 库连接**

![image-20240719175143586](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719175143586.png)

**3、下载驱动**

测试连接时，会提示让下载驱动，联网点击下载即可。

![image-20240719175238866](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719175238866.png)

如果下载慢也可删掉自带的驱动，手动添加与 hive 版本匹配的驱动，该驱动可以在 hive 的 jdbc 目录下找到。

![image-20240719175704707](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719175704707.png)

**4、手动添加驱动步骤**

编辑驱动设置 → 库 → 添加文件 → 选择驱动文件 → 确定

![image-20240719180158701](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719180158701.png)

![image-20240719180308881](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719180308881.png)

![image-20240719180323632](./07-Hive%20%E5%AE%89%E8%A3%85%E9%83%A8%E7%BD%B2/image-20240719180323632.png)
