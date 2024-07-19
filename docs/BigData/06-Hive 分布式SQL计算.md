# 一、Hive 概述

对数据进行统计分析，SQL 是目前最为方便的编程工具。

![image-20240718180019405](./06-Hive%20%E5%88%86%E5%B8%83%E5%BC%8FSQL%E8%AE%A1%E7%AE%97/image-20240718180019405.png)

大数据体系中充斥着非常多的统计分析场景，所以，使用 SQL 去处理数据，在大数据中也是有极大的需求的。

MapReduce 支持程序开发（Java、Python等），但又不支持SQL开发。

Apache Hive 是一款分布式 SQL 计算的工具， 其主要功能是：将 SQL 语句翻译成 MapReduce 程序运行。

![image-20240718175926847](./06-Hive%20%E5%88%86%E5%B8%83%E5%BC%8FSQL%E8%AE%A1%E7%AE%97/image-20240718175926847.png)

用户只需要将 SQL 语句提交给 Hive，Hive 会调用 MapReduce 去执行分布式计算，然后将结果返回给用户。

![image-20240718180437645](./06-Hive%20%E5%88%86%E5%B8%83%E5%BC%8FSQL%E8%AE%A1%E7%AE%97/image-20240718180437645.png)

# 二、Hive 架构

![image-20240718180705991](./06-Hive%20%E5%88%86%E5%B8%83%E5%BC%8FSQL%E8%AE%A1%E7%AE%97/image-20240718180705991.png)

- **Metastore 元数据存储**

  通常是存储在关系数据库如 mysql 中。Hive 中的元数据包括表的名字，表的列，分区及其属性，表的属性是否为外部表，表的数据所在目录等。

- **Hive Driver 驱动程序**

  完成 HQL 查询语句从词法分析、语法分析、编译、优化以及査询计划的生成。生成的査询计划存储在 HDFS 中，并在随后有执行引擎调用执行。
  这部分内容不是具体的服务进程，而是封装在 Hive 所依赖的 Jar 文件即 Java 代码中。

- **用户接口**

  包括CLI、JDBC/ODBC、WebGUl。其中：

  - CLI（command line interface）为 shell 命令行
  - Hive 中的 Thrit 服务器允许外部客户端通过网络与 Hive 进行交互，类似于JDBC或ODBC协议。
  - WebGUl 是通过浏览器访问 Hive。

