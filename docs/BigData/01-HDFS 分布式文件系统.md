# 一、HDFS 基础架构

## 1.1 HDFS 简介

HDFS是Hadoop三大组件(HDFS、MapReduce、YARN)之一

- 全称是：Hadoop Distributed File System（Hadoop分布式文件系统）

- 是Hadoop技术栈内提供的**分布式数据存储**解决方案

- 可以在多台服务器上构建存储集群，存储海量的数据

![image-20240711162402578](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240711162402578.png)



## 1.2 HDFS 基础架构

![1720686322760](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/1720686322760.jpg)

**NameNode 角色：**

- HDFS 系统的主角色，是一个独立的进程
- 管理集群的元数据，记录 Edits 编辑日志文件

- 负责管理 DataNode，接收客户端的请求，分发存储和读取的任务

**SencondaryNameNode 角色：**

- NameNode 的辅助角色，是一个独立进程
- 主要功能定期合并 NameNode 的 Edits  与 FSImage 文件系统镜像文件

**DataNode 角色：**

- HDFS系统的从角色，是一个独立进程
- 主要负责数据的存储，即存入数据和取出数据



一个典型的 HDFS 集群，就是由1个 NameNode 加若干（至少一个）DataNode 组成。

![image-20240711164145549](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240711164145549.png)

# 二、HDFS 存储原理

## 2.1 Block 块与副本数

### 2.1.1 块大小

HDFS 中的文件在物理上是分块存储（Block），块的大小可以通过配置参数`dfs.blocksize`来设定。

![image-20240711173453103](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240711173453103.png)

对于块（block），hdfs默认设置为128 MB一个。

块大小可以通过 **hdfs-site.xml** 参数更改，单位为 Byte 字节：

```xml
<property>
  <name>dfs.blocksize</name>
  <value>268435456</value>
</property>
```

### 2.1.2 块副本

文件的各个 block 的存储管理由 DataNode 节点承担，每一个block都可以在多个 DataNode 上存储多个副本，副本数通过参数`dfs.replication` 设定。

![1720689192011](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/1720689192011.jpg)

通过在配置文件 **hdfs-site.xml** 中配置如下属性：

```xml
<property>
    <name>dfs.replication</name>
    <value>3</value>
</property>
```

这个属性默认是3，一般情况下，我们无需主动配置（除非需要设置非3的数值）

如果需要自定义这个属性，请修改每一台服务器的 **hdfs-site.xml** 文件，并设置此属性。

- 除了配置文件外，我们还可以在上传文件的时候，临时决定被上传文件以多少个副本存储。

  `hadoop fs -D dfs.replication=2 -put test.txt /tmp/`

  如上命令，就可以在上传 test.txt 的时候，临时设置其副本数为 2。

- 对于已经存在HDFS的文件，修改`dfs.replication`属性不会生效，如果要修改已存在文件可以通过命令：

  `hadoop fs -setrep [-R] 2 path`

  如上命令，指定path的内容将会被修改为2个副本存储。-R选项可选，使用-R表示对子目录也生效。

### 2.1.3 fsck 检查块详情

我们可以使用 hdfs 提供的 fsck 命令来检查文件的副本数：

```bash
hdfs fsck path [-files [-blocks [-locations]]]
```

- `-files` 可以列出路径内的文件状态
- `-files -blocks` 输出文件块报告（有几个块，多少副本）
- `-files -blocks -locations` 输出每一个 block 的详情

## 2.2 NameNode 元数据

NameNode基于一批 edits 和一个 fsimage 文件的配合，完成整个文件系统的管理和维护。

![image-20240711182006651](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240711182006651.png)

- edits文件，是一个流水账文件，记录了hdfs中的每一次操作，以及本次操作影响的文件其对应的block。

![image-20240711182139211](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240711182139211.png)

edits 文件记录每一次HDFS的操作，随着集群运行时间增加，edits 文件逐渐变得越来越大，edits 文件达到体积上限则会自动分割，生成新的 edits 文件，所以如果观察长时间运行的 NameNode 元数据目录，会看到很多 edits 文件。

当用户想要查看某文件内容，如：/tmp/data/test.txt，就需要在全部的edits中搜索，（还需要按顺序从头到尾，避免后期改名或删除）
效率非常低。

所以就需要定期合并 edits 文件，直接得到最终结果。这个合并后的文件就是 FSImage 文件。

![image-20240711182627141](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240711182627141.png)

NameNode基于edits和FSImage的配合，完成整个文件系统文件的管理。

1. 每次对HDFS的操作，均被edits文件记录，edits达到大小上线后，开启新的edits记录
2. SecondaryNameNode 定期将edits、fsimage文件拉取到本地
3. 在节点上对edits与fsimage进行合并操作，生成fsimage.ckpt
4. 将fsimage.ckpt传输回NameNode节点
5. NameNode节点保存最新的edits文件与fsimag文件。
6. 等待下一个合并周期重复1-5步骤操作。



![img](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/20170122172359916.png)



对于元数据的合并，是一个定时过程，基于：

- dfs.namenode.checkpoint.period，默认3600（秒）即1小时

- dfs.namenode.checkpoint.txns，默认1000000，即100W次事务

只要有一个达到条件就执行。

检查是否达到条件，默认60秒检查一次，基于：

- dfs.namenode.checkpoint.check.period，默认60（秒），来决定

## 2.3 数据的读写流程

### 2.3.1 数据写入流程

![image-20240716144211481](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240716144211481.png)

1. 客户端向NameNode发起写入请求。
2. NameNode 审核权限、剩余空间后，满足条件允许写入，并告知客户端写入的 DataNode 地址。
3. 客户端向指定的 DataNode 发送数据包
4. 被写入数据的 DataNode 同时完成数据副本的复制工作，将其接收的数据分发给其它 DataNode。如上图，DataNode1 复制给 DataNode2。
5. 6. 然后基于 DataNode2 复制给 Datanode3 和 DataNode4。

7. 写入完成客户端通知 NameNode，NameNode 做元数据记录工作。

### 2.3.2 数据读取流程

![image-20240716144528445](./01-HDFS%20%E5%88%86%E5%B8%83%E5%BC%8F%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F/image-20240716144528445.png)

1. 客户端向 NameNode 申请读取某文件。
2. NameNode 判断客户端权限等细节后，允许读取，并返回此文件的 block 列表。
3. 客户端拿到 block 列表后自行寻找 DataNode 读取即可。

### 2.3.3 读写总结

1、对于客户端读取HDFS数据的流程中，一定要知道

不论读、还是写，NameNode 都不经手数据，均是客户端和 DataNode 直接通讯，不然对NameNode压力太大。

2、写入和读取的流程，简单来说就是：

1. NameNode做授权判断（是否能写、是否能读）
2. 客户端直连DataNode进行写入（由DataNode自己完成副本复制）、客户端直连DataNode进行block读取
3. 写入，客户端会被分配找离自己最近的DataNode写数据
4. 读取，客户端拿到的block列表，会是网络距离最近的一份

3、网络距离

1. 最近的距离就是在同一台机器
2. 其次就是同一个局域网（交换机）
3. 再其次就是跨越交换机
4. 再其次就是跨越数据中心

HDFS内置网络距离计算算法，可以通过IP地址、路由表来推断网络距离。

**HDFS 适用于一次写入，多次读出的场景，且不支持文件的修改。**
