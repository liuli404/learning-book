# 一、服务器信息

| IP            | 主机名 | 组件                        |
| ------------- | ------ | --------------------------- |
| 192.168.1.100 | master | NameNode、SecondaryNameNode |
| 192.168.1.101 | node1  | DataNode                    |
| 192.168.1.102 | node2  | DataNode                    |
| 192.168.1.103 | node3  | DataNode                    |

# 二、服务器初始化

**服务器版本**：

```bash
[root@localhost ~]# cat /etc/redhat-release 
CentOS Linux release 7.9.2009 (Core)
```

## 2.1 配置 yum 源

由于 CentOS 自带国外YUM源，为了提高软件安装速度，可以切换成国内源，这里换成阿里云提供的：

```bash
mv /etc/yum.repos.d/CentOS-* /tmp/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all && yum makecache
```

安装一些常用工具

```bash
yum install -y vim wget lsof net-tools ntp bash-completion
source /usr/share/bash-completion/bash_completion
```

## 2.2 修改主机名

方便主机间互相通信，设置主机名并配置IP映射

```bash
# master 主机
hostnamectl set-hostname master
# node1 主机
hostnamectl set-hostname node1
# node2 主机
hostnamectl set-hostname node2
# node3 主机
hostnamectl set-hostname node3
```

添加 hosts 主机映射，客户端的windows也同样配置

```bash
cat >> /etc/hosts << EOF
192.168.1.100 master
192.168.1.101 node1
192.168.1.102 node2
192.168.1.103 node3
EOF
```

## 2.3 检查防火墙

查看防火墙状态：

```
systemctl status firewalld.service
```

如果是 active (running) 运行中，可使用命令关闭：

```bash
systemctl stop firewalld.service && systemctl disable firewalld.service
```

## 2.4 检查SeLinux

查看 SeLinux 状态：

```bash
getenforce
```

如果是 Enforcing 状态，则使用命令关闭：

```bash
setenforce 0 && sed -i 's/enforcing/disabled/g' /etc/selinux/config
```

## 2.5 检查时间校准与时区

检查当前服务器的时区：

```bash
[root@localhost ~]# ll /etc/localtime 
lrwxrwxrwx. 1 root root 35 Jul  5 19:16 /etc/localtime -> ../usr/share/zoneinfo/Asia/Shanghai
```

如果不是中国时区，则更改：

```bash
rm -rf /etc/localtime 
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

配置中国区的NTP时钟服务器地址：

```bash
vim /etc/chrony.conf

# 将时钟服务器改为中国区的
server 0.cn.pool.ntp.org
server 1.cn.pool.ntp.org
server 2.cn.pool.ntp.org
server 3.cn.pool.ntp.org
```

重启时间同步服务：

```bash
systemctl restart chronyd.service && systemctl enable chronyd.service
```

## 2.6 配置免密登录

创建 hadoop 用户

```bash
useradd hadoop
echo "123456" | passwd --stdin hadoop 
su - hadoop
```

配置四台服务器的免密登录，使用 ssh-keygen 工具为 hadoop 用户生成公钥。

```bash
$ ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (/home/hadoop/.ssh/id_rsa): 
Created directory '/home/hadoop/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/hadoop/.ssh/id_rsa.
Your public key has been saved in /home/hadoop/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:NFzF47owgYOkgPqxheQxafFymFlz92X1KPy8CMpFttI hadoop@master
The key's randomart image is:
+---[RSA 4096]----+
|. .oo . . .o+..  |
|o **.o o o +o  o |
|.==*o. .+ +.o.. .|
|. =oo o..= ..+   |
| . +   .S.E.  o  |
|  o    .o+.. . . |
|        oo .. .  |
|          .      |
|                 |
+----[SHA256]-----+
```

使用 ssh-copy-id 工具将公钥互相拷贝到每台服务器上

```bash
ssh-copy-id master
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3
```



# 三、HDFS 安装

## 3.1 JDK1.8 安装

官网下载 JDK 安装包，上传到各节点服务器，进行解压

```bash
tar -zxvf jdk-8u361-linux-x64.tar.gz -C /opt/
```

配置环境变量

```bash
vim /etc/profile
```

文件尾部追加环境变量

```bash
export JAVA_HOME=/opt/jdk1.8.0_361
export PATH=$JAVA_HOME/bin:$PATH
```

刷新文件，立即加载环境变量

```bash
source /etc/profile
```

查看jdk版本

```bash
java -version
javac -version
```

## 3.2 HDFS 安装

上传 hadoop 安装包到各节点，解压并进行配置。

```bash
tar -zxvf hadoop-3.3.4.tar.gz -C /opt/
```

HDFS 集群主要配置文件如下，这些文件均存在`$HADOOP_HOME/etc/hadoop`目录中：

- workers：配置从节点（DataNode）有哪些
- hadoop-env.sh：配置 Hadoop 的相关环境变量
- core-site.xml：Hadoop 核心配置文件
- hdfs-site.xml：HDFS 核心配置文件

**也可以先配置 master 节点的配置，然后分发配置好的文件到各节点。**

### 3.2.1 workers 文件

```bash
# 记录集群的 DataNode 节点列表
node1
node2
node3
```

### 3.2.2 hadoop-env.sh 文件

```bash
# JAVA_HOME，指明 JDK 环境的位置在哪
# HADOOP_HOME，指明 Hadoop 安装位置
# HADOOP_CONF_DIR，指明 Hadoop 配置文件目录位置
# HADOOP_LOG_DIR，指明 Hadoop 运行日志目录位置

export JAVA_HOME=/opt/jdk1.8.0_361
export HADOOP_HOME=/opt/hadoop-3.3.4
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_LOG_DIR=$HADOOP_HOME/logs
```

### 3.2.3 core-site.xml 文件

```xml
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://master:8020</value>
  </property>

  <property>
    <name>io.file.buffer.size</name>
    <value>131072</value>
  </property>
</configuration>
```

- 属性1：
  - name：fs.defaultFS
    - HDFS 文件系统的网络通讯路径
  - value：hdfs://master:8020
    - namenode 为 master，namenode 通讯端口为 8020
- 属性2：
  - name：io.file.buffer.size
    - io操作文件缓冲区大小
  - value：131072 bit

### 3.2.4 hdfs-site.xml 文件

```xml
<configuration>
  <property>
    <name>dfs.datanode.data.dir.perm</name>
    <value>700</value>
  </property>
    
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/data/nn</value>
  </property>
    
  <property>
    <name>dfs.namenode.hosts</name>
    <value>node1,node2,node3</value>
  </property>
    
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/data/dn</value>
  </property>
    
  <property>
    <name>dfs.blocksize</name>
    <value>268435456</value>
  </property>
    
  <property>
    <name>dfs.namenode.handler.count</name>
    <value>100</value>
  </property>
</configuration> 
```

- 属性1：
  - name：dfs.datanode.data.dir.perm
    - hdfs文件系统，默认创建的文件权限设置
  - value：700
    - 即：rwx------
- 属性2：
  - name：dfs.namenode.name.dir
    - NameNode元数据的存储位置
  - value：/data/nn
    - 在 master 节点的 /data/nn 目录下
- 属性3：
  - name：dfs.namenode.hosts
    - NameNode允许哪几个节点的DataNode连接（即允许加入集群）
  - value：node1,node2,node3
    - 这三台服务器被授权
- 属性4：
  - name：dfs.datanode.data.dir
    - DataNode的数据存储目录
  - value：/data/dn
    - 在 node 节点的 /data/dn 目录下
- 属性5：
  - name：dfs.blocksize
    - hdfs文件默认块大小
  - value：268435456
    - 258MB
- 属性6：
  - name：dfs.namenode.handler.count
    - namenode 处理的并发线程数
  - value：100
    - 以100个并行度处理文件系统的管理任务

### 3.2.5 hadoop 环境变量

添加 PATH 环境变量只是为了使用脚本方便，如果习惯写脚本的绝对路径可不配。

```bash
vim /etc/profile
```

文件尾部追加环境变量

```bash
export HADOOP_HOME=/opt/hadoop-3.3.4
export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
```

刷新文件，立即加载环境变量

```bash
source /etc/profile
```

将修改后的配置文件， scp 到其他 node 节点上。

```bash
cd /opt/hadoop-3.3.4/etc/hadoop
scp -r workers hadoop-env.sh hdfs-site.xml core-site.xml node1:`pwd`
scp -r workers hadoop-env.sh hdfs-site.xml core-site.xml node2:`pwd`
scp -r workers hadoop-env.sh hdfs-site.xml core-site.xml node3:`pwd`
```

创建数据存放目录

```bash
# 提前准备好数据盘，挂盘、创建目录 
mkdir /data/
mkfs.ext4 /dev/sdb
echo "/dev/sdb /data ext4 defaults 0 0" >> /etc/fstab
mount -a

# master,namenode程序存放元数据目录
mkdir /data/nn

# node1、node2、node3,datanode程序存放真实数据目录
mkdir /data/dn

# 授权目录给 hadoop 用户
chown -R hadoop:hadoop /opt
chown -R hadoop:hadoop /data
```

### 3.3 启动 HDFS

切换回 hadoop 用户

```bash
su - hadoop
```

格式化文件系统

```bash
# 格式化 namenode，master 节点执行就可以。
hadoop namenode -format
```

使用脚本启动 hdfs

```bash
# 一键启动hdfs集群
start-dfs.sh
# 一键关闭hdfs集群
stop-dfs.sh
```

除了一键启停外，也可以单独控制进程的启停。
1. `$HADOOP_HOME/sbin/hadoop-daemon.sh`，此脚本可以单独控制**所在机器**的进程的启停

  ```bash
  hadoop-daemon.sh (start|status|stop) (namenode|secondarynamenode|datanode)
  ```

2. `$HADOOP_HOME/bin/hdfs`，此程序也可以用以单独控制**所在机器**的进程的启停

  ```bash
  hdfs --daemon (start|status|stop) (namenode|secondarynamenode|datanode)
  ```

启动完成后，可以使用`jps`命令查看节点上的角色

```bash
# master 节点
SecondaryNameNode
NameNode

# node 节点
DataNode
```

在浏览器打开：http://master:9870，即可查看到hdfs文件系统的管理网页。

![image-20240718153534392](./02-HDFS%20%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20240718153534392.png)

## 3.4 其他配置

### 3.4.1 Trash 回收站配置

回收站功能默认关闭，修改 HDFS 每个节点的 `core-site.xml` 文件，增加属性配置。

无需重启集群，在哪个机器配置的，在哪个机器执行命令就生效。

删除的文件会被移动到`hdfs:///user/用户名(hadoop)/.Trash`目录中。想要从回收站恢复文件，只要从该目录将文件移回原目录即可。

```xml
  <property>
    <name>fs.trash.interval</name>
    <value>1440</value>
  </property>
 
  <property>
    <name>fs.trash.checkpoint.interval</name>
    <value>120</value>
  </property>
```

属性1：

- name：fs.trash.interval
  - 定义了文件或目录在被永久删除前，在Trash中保留的时间（单位为分钟）
- value：1440
  - 1440分钟，即24小时，意味着文件被删除后，会在Trash中保留24小时
  - 如果设置为0，Trash功能将被禁用，删除操作会立即生效，文件将无法恢复

属性2：

- name：fs.trash.checkpoint.interval
  - 定义了Trash检查点的间隔时间，即多久触发一次检查并清理达到保留时间的文件（单位为分钟）
- value：120
  - 120分钟，即每2小时检查下Trash有没有该清空的文件

### 3.4.2 Web 操作配置

使用 Web 浏览操作 HDFS 文件系统时，一般会遇到权限问题：

![image-20240710182011288](./02-HDFS/image-20240710182011288.png)

这是因为 Web 浏览器中是以匿名用户（dr.who）登陆的，其只有只读权限，多数操作是做不了的。

在Hadoop集群中，不同的服务（如 HDFS、YARN、MapReduce 等）需要通过 Web 界面或 API 与外部进行通信。为了提供安全和可控的访问，Hadoop引入了 HTTP 静态用户配置。

HTTP 静态用户配置的主要目的是确保 Hadoop 服务以相同的用户身份运行，以便它们可以共享相同的权限和访问控制策略。这样可以避免不同服务使用不同的用户身份，导致权限混乱和管理上的复杂性。

另外，通过配置相同的静态用户，管理员可以更好地控制集群资源的访问和使用。只有被授权的用户才能通过 Web 界面或 API 访问集群资源，从而提高了集群的安全性。

需要配置如下内容到 `core-site.xml` 并**重启集群**。

```xml
  <property>
    <name>hadoop.http.staticuser.user</name>
    <value>hadoop</value>
  </property>
```

属性1：

- name：hadoop.http.staticuser.user
  - 开启配置 http 静态用户
- value：hadoop
  - 将静态用户配置为 hadoop，该用户是启动集群的超级用户，拥有所有权限。
