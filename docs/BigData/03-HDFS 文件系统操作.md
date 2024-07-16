# 一、HDFS文件系统

HDFS作为分布式存储的文件系统，有其对数据的路径表达方式，HDFS同Linux系统一样，均是以`/`作为根目录的组织形式。

使用不同的协议头区分操作的是哪个文件系统：

- Linux：file://
- HDFS：hdfs://namenode:port

例如：

- Linux：file://**/usr/local/hello.txt**
- HDFS：hdfs://node1:8020**/usr/local/hello.txt**

通常情况下文件协议头是可以省略的，程序会自己判断操作的是哪个文件系统。

![image-20240711145502871](./03-HDFS%20Shell%E6%93%8D%E4%BD%9C/image-20240711145502871.png)

# 二、两套命令体系

关于HDFS文件系统的操作命令，Hadoop提供了2套命令体系。

- hadoop命令（老版本用法），用法：`hadoop fs [generic 选项]`
- hdfs命令（新版本用法），用法：`hdfs dfs [generic 选项]`

两者在文件系统操作上，用法完全一致，用哪个都可以。

# 三、文件系统常用命令

HDFS操作文件系统的命令与Linux类似，完整文件系统操作文档：https://hadoop.apache.org/docs/r3.3.0/hadoop-project-dist/hadoop-common/FileSystemShell.html

## 3.1 mkdir 创建文件夹

用法: `hadoop fs -mkdir [-p] <paths>`

选项:

- `-p`，选项的行为与Linux mkdir -p一致，它会沿着路径创建父目录

举例:

- `hadoop fs -mkdir /user/hadoop/dir1 /user/hadoop/dir2`
- `hadoop fs -mkdir hdfs://nn1.example.com/user/hadoop/dir hdfs://nn2.example.com/user/hadoop/dir`

## 3.2 ls 查看指定目录下内容

用法: `hadoop fs -ls [-C] [-d] [-h] [-q] [-R] [-t] [-S] [-r] [-u] [-e] <args>`

选项:

- `-C`: 仅显示文件和目录的路径。
- `-d`: 目录以普通文件的形式列出。
- `-h`: 以人类可读的方式格式化文件大小
- `-q`: 打印 ？而不是不可打印的字符。
- `-R`: 以递归方式列出遇到的子目录。
- `-t`: 按修改时间对输出进行排序。
- `-S`: 按文件大小对输出进行排序。
- `-r`: 颠倒排序顺序。
- `-u`: 使用访问时间而不是修改时间进行显示和排序。
- `-e`: 仅显示文件和目录的纠删码策略。

举例:

- `hadoop fs -ls /user/hadoop/file1`
- `hadoop fs -ls -e /ecdir`

## 3.3 put 上传文件到HDFS指定目录下

用法: `hadoop fs -put [-f] [-p] [-l] [-d] [ - | <localsrc1> .. ]. <dst>`

选项:

- `-p` : 保留访问和修改时间、所有权和权限。
- `-f` : 如果目标已存在，则覆盖该目标。
- `-l` : 允许 DataNode 将文件延迟保存到磁盘，强制复制因子为 1。
- `-d` : 跳过创建后缀为“.\_COPYING\_”的临时文件。

举例:

- `hadoop fs -put localfile /user/hadoop/hadoopfile`
- `hadoop fs -put -f localfile1 localfile2 /user/hadoop/hadoopdir`
- `hadoop fs -put -d localfile hdfs://nn.example.com/hadoop/hadoopfile`
- `hadoop fs -put - hdfs://nn.example.com/hadoop/hadoopfile` Reads the input from stdin.

## 3.4 get 下载HDFS文件

用法: `hadoop fs -get [-ignorecrc] [-crc] [-p] [-f] <src> <localdst>`

选项:

- `-p` : 保留访问和修改时间、所有权和权限。
- `-f` : 如果目标已存在，则覆盖该目标。
- `-ignorecrc` : 跳过对下载的文件的CRC检查。
- `-crc`: 为下载的文件写入 CRC 校验。

举例:

- `hadoop fs -get /user/hadoop/file localfile`
- `hadoop fs -get hdfs://nn.example.com/user/hadoop/file localfile`

## 3.5 cat 查看HDFS文件内容

用法: `hadoop fs -cat URI [URI ...]`

Example:

- `hadoop fs -cat hdfs://nn1.example.com/file1 hdfs://nn2.example.com/file2`
- `hadoop fs -cat file:///file3 /user/hadoop/file4`

## 3.6 cp 拷贝HDFS文件

用法: `hadoop fs -cp [-f] URI [URI ...] <dest>`

选项:

- `-f`: 如果目标已存在，则覆盖该目标。

举例:

- `hadoop fs -cp /user/hadoop/file1 /user/hadoop/file2`
- `hadoop fs -cp /user/hadoop/file1 /user/hadoop/file2 /user/hadoop/dir`

## 3.7 appendToFile 追加数据到HDFS文件中

用法: `hadoop fs -appendToFile <localsrc> ... <dst>`

举例：

- `hadoop fs -appendToFile localfile /user/hadoop/hadoopfile`
- `hadoop fs -appendToFile localfile1 localfile2 /user/hadoop/hadoopfile`
- `hadoop fs -appendToFile localfile hdfs://nn.example.com/hadoop/hadoopfile`
- `hadoop fs -appendToFile - hdfs://nn.example.com/hadoop/hadoopfile` 

## 3.8 mv HDFS数据移动操作

用法: `hadoop fs -mv URI [URI ...] <dest>`

举例:

- `hadoop fs -mv /user/hadoop/file1 /user/hadoop/file2`
- `hadoop fs -mv hdfs://nn.example.com/file1 hdfs://nn.example.com/file2 hdfs://nn.example.com/file3 hdfs://nn.example.com/dir1`

## 3.9 rm HDFS数据删除操作

用法: `hadoop fs -rm [-f] [-r |-R] [-skipTrash] URI [URI ...]`

选项:

- `-f`: 如果文件不存在，则该选项将不显示诊断消息或修改退出状态以反映错误。
- `-R`: 选项以递归方式删除目录及其下的任何内容。
- `-r`: 等价于 -R。
- `-skipTrash`: 不将文件放入 .Trash 回收站直接删除。

举例:

- `hadoop fs -rm hdfs://nn.example.com/file /user/hadoop/emptydir`

## 3.10 tail 查看文件末尾内容

用法: `hadoop fs -tail [-f] URI`

选项:

- `-f`：将随着文件的增长输出增加的数据，就像在 Unix 中一样。

举例:

- `hadoop fs -tail pathname`

# 四、root操作文件系统权限报错解决

由于 HDFS 的文件系统文件，默认被授权给 hadoop 用户与 supergroup 用户组，root 用户并没有权限，所以无法操作并报错：

```bash
Permission denied: user=root, access=WRITE, inode="/":hadoop:supergroup:drwxr-xr-x
```

有两种解决方案：

## 4.1 更改 root 的所属组

HDFS 文件系统的目录基本都属于 supergroup 用户组，所以就把用户添加到该用户组，即可解决很多权限问题。

**1、在Linux中执行如下命令增加supergroup**

```bash
groupadd supergroup
```

**2、如将用户root增加到supergroup中**

```bash
usermod -a -G supergroup root
```

**3、同步系统的权限信息到HDFS文件系统**

```bash
sudo -u hdfs hdfs dfsadmin -refreshUserToGroupsMappings
```

**4、查看属于supergroup用户组的用户**

```bash
grep 'supergroup:' /etc/group
```

## 4.2 更改文件权限

在HDFS中，可以使用和Linux一样的授权语句，即：chown和chmod

- 修改文件所属用户和组：

````bash
hadoop fs -chown [-R] root:root /xxx.txt
````

- 修改文件权限

```bash
hadoop fs -chmod [-R] 777 /xxx.txt
```