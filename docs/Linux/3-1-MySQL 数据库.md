# MySQL 安装
安装方式对比
|安装方式| 优点 | 缺点 
|--|--|--|
| rpm 包 | 安装卸载简单| 可定制性差
| glibc 包 | 可定制性较好|安装略复杂，需要手动初始化数据库
|源码包| 可定制性最强|安装麻烦，需要编译源码加手动初始化数据库

## 服务器标准化环境

| 软件 |  版本 | IP| 角色|
|--|--|--|--|
| CentOS| 7.9.2009 | 192.168.1.6| 编译安装方式
| CentOS| 7.9.2009 | 192.168.1.7| glibc 安装方式
| CentOS| 7.9.2009 | 192.168.1.8| rpm 安装方式

标准化环境需要每台主机都进行操作

1. 设置主机名

```bash
hostnamectl set-hostname mysql.server
```

2. 关闭 firewall 、SElinux

```bash
systemctl stop firewalld.service && systemctl disable firewalld.service
```
```bash
setenforce 0 && sed -i 's/enforcing/disabled/g' /etc/selinux/config
```

3. 配置 yum 源

```bash
mv /etc/yum.repos.d/CentOS-* /tmp/
```
```bash
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```
```bash
yum clean all && yum makecache
```

4. 安装基本工具

```bash
yum groupinstall -y "Development Tools"
```
```bash
yum install -y vim wget net-tools bash-completion
```
```bash
source /usr/share/bash-completion/bash_completion
```
## 一、源码包方式
| 选项 |  值| 
|--|:--|
|版本| mysql-boost-5.7.35
|安装目录 | /mysql_3306
|数据目录 |/mysql_3306/data
|端口|3306
|配置文件|/mysql_3306/my.cnf
|sock 文件|/mysql_3306/mysql.sock
|日志文件|/mysql_3306/data/mysql.server.err 
|字符集|utf8mb4

1. 下载安装包
```bash
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.35.tar.gz
```
```bash
tar -zxvf mysql-boost-5.7.35.tar.gz
```
2. 安装依赖包

```bash
yum install -y ncurses-devel cmake libaio-devel openssl-devel
```
3. 卸载自带的 `mariadb` 

```bash
yum remove -y mariadb* && rm -f /etc/my.cnf
```
4. 创建 `mysql` 用户

```bash
useradd -r -s /sbin/nologin mysql
```

5. `cmake` 配置

```bash
cd mysql-5.7.35/
```

```bash
cmake . \
-DCMAKE_INSTALL_PREFIX=/mysql_3306 \
-DMYSQL_DATADIR=/mysql_3306/data \
-DSYSCONFDIR=/mysql_3306 \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=/mysql_3306/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system \
-DWITH_BOOST=boost
```


- 常用配置选项

| 配置选项             | 描述                             | 默认值            | 建议值                                  |
| :-------------------- | :-------------------------------- | :----------------- | :--------------------------------------- |
| CMAKE_INSTALL_PREFIX | 安装基目录(basedir)              | /usr/local/mysql  | 根据需求                                |
| MYSQL_DATADIR        | 数据目录(datadir)                | $basedir/data     | 根据需求                                |
| SYSCONFDIR           | 默认配置文件my.cnf路径           |                   | /etc                                    |
| MYSQL_TCP_PORT       | TCP/IP端口                       | 3306              | 非默认端口                              |
| MYSQL_UNIX_ADDR      | 套接字socket文件路径             | /tmp/mysql.sock   | $basedir/                               |
| DEFAULT_CHARSET      | 默认字符集                       | latin1            | **utf8mb4**                             |
| DEFAULT_COLLATION    | 默认校验规则                     | latin1_swedish_ci | utf8mb4_general_ci                      |
| WITH_EXTRA_CHARSETS  | 扩展字符集                       | all               | all                                     |
| ENABLED_LOCAL_INFILE | 是否启用本地加载外部数据文件功能 | OFF               | 建议开启                                |
| WITH_SSL             | SSL支持类型                      | system            | 建议显式指定                            |
| WITH_BOOST           | Boost库源代码的位置              |                   | Boost库是构建MySQL所必需的,建议事先下载 |
- 存储引擎相关配置项

**说明：**

以下选项值均为布尔值；0 代表不编译到服务器中，1 代表编译，建议都静态编译到服务器中。

其他的存储引擎可以根据实际需求在安装时通过 `WITH_xxxx_STORAGE_ENGINE=1` 的方式编译到服务器中。

| 配置选项                      | 描述                                                         |
| :----------------------------- | :------------------------------------------------------------ |
| WITH_INNOBASE_STORAGE_ENGINE  | 将InnoDB存储引擎插件构建为静态模块编译到服务器中；建议编译到服务器中 |
| WITH_PARTITION_STORAGE_ENGINE | 是否支持分区                                                 |
| WITH_FEDERATED_STORAGE_ENGINE | 本地数据库是否可以访问远程mysql数据                          |
| WITH_BLACKHOLE_STORAGE_ENGINE | 黑洞存储引擎，接收数据，但不存储，直接丢弃                   |
| WITH_MYISAM_STORAGE_ENGINE    | 将MYISAM存储引擎静态编译到服务器中                           |
6. `make` 编译安装
```bash
make -j 4 && make install
```
>  -j [N], --jobs[=N]          同时允许 N 个任务，加快编译速度；无参数表明允许无限个任务。

7. 创建 `mysql-files` 目录并设置 `750` 权限

```bash
cd /mysql_3306/ && mkdir mysql-files && chmod 750 mysql-files/
```

8. 创建配置文件（基本配置）

```bash
vim /mysql_3306/my.cnf
```
添加以下内容
```bash
[mysqld]
port=3306
basedir=/mysql_3306
datadir=/mysql_3306/data
socket=/mysql_3306/mysql.sock
```
9. 初始化数据库，获取随机的 `root` 密码
```bash
chown -R mysql:mysql /mysql_3306/
```
```bash
bin/mysqld --defaults-file=/mysql_3306/my.cnf --initialize --user=mysql --basedir=/mysql_3306
```
```bash
# root 的临时初始密码为 =&t%RnJa!0yf
2021-10-29T07:56:21.884381Z 1 [Note] A temporary password is generated for root@localhost: =&t%RnJa!0yf
```

>  --defaults-file 	指定配置文件
 --initialize 		初始化参数
 --user=mysql 		以 mysql 用户身份执行，初始化产生的文件拥有者为 mysql 用户
 --basedir			mysql 的安装目录


10. 设置 `SSL` 加密链接，数据会采用加密形式

```bash
bin/mysql_ssl_rsa_setup --datadir=/mysql_3306/data
```

11. 启动数据库

```bash
cp support-files/mysql.server /etc/init.d/mysql_3306
```
```bash
service mysql_3306 start
```
启动成功
```bash
Starting MySQL.Logging to '/mysql_3306/data/mysql.server.err'.
 SUCCESS!
```
> 报错日志将在该文件中找到：/mysql_3306/data/mysql.server.err 

12. 设置开机自启

`chkconfig` 添加 `/etc/init.d/` 目录下的脚本名称
```bash
chkconfig --add mysql_3306
```
查看是否为 `enabled` 开机自启
```bash
systemctl is-enabled mysql_3306.service 
```
```bash
mysql_3306.service is not a native service, redirecting to /sbin/chkconfig.
Executing /sbin/chkconfig mysql_3306 --level=5
enabled
```

13. 配置环境变量

```bash
vim ~/.bashrc
```
追加以下内容
```bash
export MYSQL_3306_HOME=/mysql_3306/bin/
export PATH=$PATH:$MYSQL_3306_HOME
```
刷新生效

```bash
source ~/.bashrc
```

14. 修改 `root` 用户密码

```sql
# 方法一：使用 mysqladmin 工具修改
[root@mysql ~]# mysqladmin -u root password 'newpassword' -p
Enter password: # 这里输入旧密码

# 方法二：进入 mysql 命令行，使用 SQL 语句修改
[root@mysql ~]# mysql -u root -p
Enter password: # 这里输入旧密码
mysql> set password for root@localhost = password('newpassword');
mysql> flush privileges;
```

15. 授权 `root` 用户远程登录

```sql
mysql> grant all privileges on *.* to 'root'@'%' identified by 'newpassword';
mysql> flush privileges;
```

## 二、glibc 包方式
| 选项 |  值| 
|--|:--|
|版本| mysql-5.7.35-linux-glibc2.12-x86_64
|安装目录 | /mysql_3306
|数据目录 |/mysql_3306/data
|端口|3306
|配置文件|/mysql_3306/my.cnf
|日志文件|/mysql_3306/data/mysql.server.err 
|sock 文件|/tmp/mysql.sock

1. 下载安装包
```bash
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.35-linux-glibc2.12-x86_64.tar.gz
```
```bash
tar -zxvf mysql-5.7.35-linux-glibc2.12-x86_64.tar.gz
```

2. 安装依赖包

```bash
yum install -y libaio
```

3. 卸载自带的 `mariadb` 

```bash
yum remove -y mariadb* && rm -f /etc/my.cnf
```

4. 创建 `mysql` 用户

```bash
useradd -r -s /sbin/nologin mysql
```

5. 将解压后的包移到安装目录 `/mysql_3306`

```bash
mv mysql-5.7.35-linux-glibc2.12-x86_64 /mysql_3306
```

6. 创建 `mysql-files` 目录并设置 `750` 权限

```bash
cd /mysql_3306/ && mkdir mysql-files && chmod 750 mysql-files/
```

7. 创建配置文件（基本配置）

```bash
vim /mysql_3306/my.cnf
```
添加以下内容
```bash
[mysqld]
port=3306
basedir=/mysql_3306
datadir=/mysql_3306/data
socket=/tmp/mysql.sock
```

8. 初始化数据库，获取随机的 `root` 密码

```bash
chown -R mysql:mysql /mysql_3306/
```
```bash
bin/mysqld --defaults-file=/mysql_3306/my.cnf --initialize --user=mysql --basedir=/mysql_3306
```
```bash
2021-10-29T02:55:32.954642Z 1 [Note] A temporary password is generated for root@localhost: djAWswGVq1?2
# root 的初始密码为 djAWswGVq1?2
```

> --defaults-file 	指定配置文件
 --initialize 		初始化参数
 --user=mysql 		以 mysql 用户身份执行，初始化产生的文件拥有者为 mysql 用户
 --basedir			mysql 的安装目录


9. 设置 `SSL` 加密链接，数据会采用加密形式

```bash
bin/mysql_ssl_rsa_setup --datadir=/mysql_3306/data
```

10. 根据自己的安装目录修改启动脚本 

 由于不是使用的默认路径，所以要修改启动脚本中的两个变量
```bash
vim support-files/mysql.server
```
修改内容
```bash
basedir=/mysql_3306
datadir=/mysql_3306/data
```
```bash
cp support-files/mysql.server /etc/init.d/mysql_3306
```


11. 启动数据库

```bash
service mysql_3306 start 
```
```bash
Starting MySQL.Logging to '/mysql_3306/data/mysql.server.err'.
 SUCCESS!
```

> 报错日志将在该文件中找到：/mysql_3306/data/mysql.server.err 

12. 设置开机自启

`chkconfig` 添加 `/etc/init.d/` 目录下的脚本名称
```bash
chkconfig --add mysql_3306
```
查看是否为 `enabled` 开机自启
```bash
systemctl is-enabled mysql_3306.service 
```
```bash
mysql_3306.service is not a native service, redirecting to /sbin/chkconfig.
Executing /sbin/chkconfig mysql_3306 --level=5
enabled
```
13. 配置环境变量

```bash
vim ~/.bashrc
```
追加以下内容
```bash
export MYSQL_3306_HOME=/mysql_3306/bin/
export PATH=$PATH:$MYSQL_3306_HOME
```
刷新生效

```bash
source ~/.bashrc
```

14. 修改 `root` 用户密码

```sql
# 方法一：使用 mysqladmin 工具修改
[root@mysql ~]# mysqladmin -u root password 'newpassword' -p
Enter password: # 这里输入旧密码

# 方法二：进入 mysql 命令行，使用 SQL 语句修改
[root@mysql ~]# mysql -u root -p
Enter password: # 这里输入旧密码
mysql> set password for root@localhost = password('newpassword');
mysql> flush privileges;
```

15. 授权 `root` 用户远程登录

```sql
mysql> grant all privileges on *.* to 'root'@'%' identified by 'newpassword';
mysql> flush privileges;
```


## 三、rpm 包方式
**注**：`RPM 包` 为红帽系列系统的快捷安装包，其他系统不支持该方式安装
| 选项 |  值| 
|--|:--|
|版本| mysql-5.7.35-1.el7.x86_64.rpm-bundle
|数据目录 |/var/lib/mysql
|端口|3306
|配置文件|/etc/my.cnf
|sock 文件|/var/lib/mysql/mysql.sock
|日志文件|/var/log/mysqld.log

1. 下载安装包
```bash
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar
```
```bash
tar -xvf mysql-5.7.35-1.el7.x86_64.rpm-bundle.tar
```
2. 安装依赖包

```bash
yum install -y libaio
```
3. 卸载自带的 `mariadb` 

```bash
yum remove -y mariadb* && rm -f /etc/my.cnf
```
4. 安装 `rpm` 包

注意安装顺序要正确
```bash
rpm -ivh mysql-community-common-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-libs-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-client-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-server-5.7.35-1.el7.x86_64.rpm && \
rpm -ivh mysql-community-libs-compat-5.7.35-1.el7.x86_64.rpm
```

5. 启动并设置为开机自启

```bash
systemctl start mysqld.service && systemctl enable mysqld.service
```

6. 获取 `root` 初始密码

```bash
grep password /var/log/mysqld.log | sed 's/.*\(............\)$/\1/'
```


7. 修改 `root` 用户密码

```sql
# 方法一：使用 mysqladmin 工具修改
[root@mysql ~]# mysqladmin -u root password 'newpassword' -p
Enter password: # 这里输入旧密码

# 方法二：进入 mysql 命令行，使用 SQL 语句修改
[root@mysql ~]# mysql -u root -p
Enter password: # 这里输入旧密码
mysql> set password for root@localhost = password('newpassword');
mysql> flush privileges;
```


8. 授权 `root` 用户远程登录

```sql
mysql> grant all privileges on *.* to 'root'@'%' identified by 'newpassword';
mysql> flush privileges;
```
# SQL 语句简析
## 一、数据库
1. 创建数据库

```sql
# 创建 test_db 库
create database test_db1;

# 创建 test_db2 库并指定默认字符集
create database test_db2 default charset utf8;

# 如果不存在则创建 test_db3 库并指定默认字符集
create database if not exists test_db3 default charset utf8mb4;
```
 2. 显示数据库
```sql
# 查询所有数据库
show databases;

# 查看 test_db3 的创建语句
show create database test_db3;
```
3. 修改数据库

```sql
# 修改 test_db1 的默认字符编码为 gbk
alter database test_db1 default charset gbk; 
```
4. 删除数据库

```sql
# 删除 test_db 数据库
drop database test_db;
```
## 二、数据表
1. 创建数据表

```sql
# 创建 tb_admin 表，包含字段 id、username、password
create table tb_admin ( id int, username varchar(20), password char(32) );
```

2. 显示数据表
```sql
# 查询所有数据表
show tables;

# 查看 tb_admin 的创建语句
show create table tb_admin;

# 显示表字段
desc tb_admin;
```
3. 修改数据表

```sql
# 添加 phone 字段 
alter table tb_admin add phone int;

# 修改字段 username 类型
alter table tb_admin modify username char;

# 修改 password 字段名称为 passwd
alter table tb_admin change password passwd varchar(32);

# 删除 phone 字段
alter table tb_admin drop phone;

# 修改 tb_admin 名称为 tb_user
rename table tb_admin to tb_user;
```

4. 删除数据表

```bash
# 删除 tb_user 表
drop table tb_user;
```
## 三、数据
1. 增加数据

```sql
# 指定字段插入数据
insert into tb_admin ( id, username, password ) values ( 1, 'liuli', '123456' );
```

2. 查询数据

```sql
# 查询 tb_admin 表所有数据
select * from tb_admin;

# 查询指定字段
select id,username from tb_admin;

# 将字段合并后查询
SELECT
	emp_no,
	CONCAT( first_name,last_name ) AS `name` 
FROM
	employees;
```

3. 修改数据

```sql
# 将 id 为 1 的 username 改为 tester，密码改为 654321
update tb_admin set username = 'tester',password = '654321' where id = 1;
```

4. 删除数据

```sql
# 删除表数据
delete from tb_admin;

# 删除 id 为 1 的数据
delete from tb_admin where id = 1;

# 直接清空表数据
truncate tb_admin;
```
5. 自增与主键约束

自增（auto_increment）、主键（primary key）

```sql
# 将 id 字段进行自增编号，并设置为主键
create table tb_user ( id int not null auto_increment primary key, name varchar ( 20 ), phone varchar ( 11 ) )
```
## 四、数据类型
1. 数值类型
- 整数

| 类型 | 存储占用字节 |取值范围 | 无符号取值范围|适用场景
|--|--|--|--|--|
| TINYINT | 1 | -128 ~ 127 | 0 ~ 255 | 人的年龄、单科考试成绩
|SMALLINT|2| -32768 ~ 32767 |0 ~ 65535| 数据量较小项目
|MEDIUMINT|3| -8388608 ~ 8388607 | 0 ~ 16777215| 百万数据量项目
|INT|4| -2147483648 ~ 2147483647 |0 ~ 4294967295|中国人口信息
|BIGINT|8| -2^63^  ~ 2^63^ -1| 2 ^64^-1|世界人口信息

- 浮点数

| 类型 | 存储占用字节 |精确小数点|适用场景|
|--|--|--|--|
| FLOAT| 4 | 7 位小数 |  薪水
|DOUBLE|8| 15 位小数|  精确计算

2. 字符串类型

- CHAR

CHAR 类型的字符串长度为**定长**，长度范围是 0 到 255 之间的任何值，占用定长的存储空间，不足的部分用空格填充

应用场景：固定长度的内容

```sql
手机号	phone	char(11)
身份证	id_card char(18)
密码	passwd	char(32)
```
- VARCHAR

VARCHAR 类型的字符串长度为**可变长度**，仅使用必须的存储空间

应用场景：经常变化的字符长度

```sql
姓名	name varchar(32)
标题	title varchar(64)
```
- TEXT

TEXT 代表文本类型的字符串，当存储文本超过 VARCHAR 的长度后，可以使用 TEXT 文本类型

应用场景：长文本内容

```sql
文章	content text
详情	details	text
```
3. 日期时间类型

|类型|  格式| 范围
|--|--|--|
| DATA| 年-月-日| 1000-01-01 ~ 9999-12-31 |
|TIME|时:分:秒|-838:59:59 ~ 838:59:59|
|DATATIME|年-月-日 时:分:秒| 1000-01-01 00:00:00 ~ 9999-12-31 23:59:59
|TIMESTAMP|年-月-日 时:分:秒|1970-01-01 00:00:00 ~ 2038-01-19 03:14:07 
|YEAR|年|1901 ~ 2155|

## 五、查询语句
1. where 语句

like 模糊查询

```sql
# 获取以张开头的姓名
select * from user_info where _name like '张%';

# 获取年龄大于23的用户信息
select * from user_info where age > 23;

# 获取年龄18~25之间的用户
select * from user_info where age between 18 and 25;

# 获取 ID 为 2、4、6 的用户
select * from user_info where ID in (2,4,6);
```

2. group by 语句

group by 对数据进行分组

> 涉及对每个学科、部门、年级进行统计求和、求平均的，统一使用 group by

```sql
# 求男、女同学的总数
select gender,count(*) from student group by gender;

# 求男、女同学年龄的最大值
select gender,max(age) from student group by gender;
```

3. having 语句

用于对 group by 的结果进行筛选，必须在 group by 后面使用

```sql
# 求每个学科中，学科人数大于三人的学科
select subject,count(*) > 3 from student group by subject having count(*) > 3;
```

4. order by 语句

主要作用是对数据进行排序。
asc：升序；desc：降序。

```sql
# 按照成绩升序进行排序
select * from user_info order by score asc;
```

5. limit 语句

分页函数

```sql
# 只查询 10 条数据
select * from user_info limit 10;

# 从偏移量为 10 的数据往后查询 5 条数据（每页显示五条记录）
select * from user_info limit 0,5;
select * from user_info limit 5,5;
```
6. 内连接

> 把两个表或多个表进行链接，然后拿表1中的每一条记录与表2中的每一条记录进行匹配，如果有之对应的结果，则显示。反之，则忽略这条记录。

```sql
# 将学生表与成绩表通过学生 id 进行内联查询
select * from student inner join score student.id = score.sid limit 10;
```

7. 外连接

```sql
# 左外连接，把左表中的数据全部显示，右表只显示匹配的数据
select * from student left join score student.id = score.sid;

# 右外连接，把右表中的数据全部显示，左表只显示匹配的数据
select * from student right join score student.id = score.sid;
```
8. 别名

```bash
select * from student A right join score B A.id = B.sid;
```

# 用户与权限管理
## 一、用户的创建

语法：
```sql
# 创建
create user '用户名'@'被允许链接的主机ip' identified by '用户的密码';
# 查看
select user,host from mysql.user;
```
示例：
```sql
# 创建 Tom 账号，密码 ’123456@Tom‘，只允许 本机 访问数据库
create user 'Tom'@'localhost' identified by '123456@Tom';

# 创建 Jack 账号，密码 '123456@Jack'，只允许 ip 为 192.168.1.100 的主机访问
create user 'Jack'@'192.168.1.100' identified by '123456@Jack';

# 创建 Lily 账号，密码 '123456@Lily'，只允许 ip 网段为 192.168.1.% 的主机访问
create user 'Lily'@'192.168.1.%' identified by '123456@Jack';

# 创建 Lee 账户，密码 '123456@Lee'，允许所有的 ip 访问
create user 'Lily'@'%' identified by '123456@Jack';
```

## 二、用户删除
语法：

```sql
drop user '用户名'@'被允许链接的主机ip';
```
示例：

```sql
# 删除 Tom 账号
drop user 'Tom'@'localhost';
```

## 三、用户的修改
语法：
```sql
rename user '旧的用户信息' to '新的用户信息';
```
示例：
```sql
# 修改 Jack 的远程登陆主机为 % 所有主机
rename user 'Jack'@'192.168.1.100' to 'Jack'@'%';
```
## 四、用户授权

语法：

```sql
grant 权限1，权限2，权限3	on 库.表 to '用户'@'主机';
```
示例：

```sql
# 创建仅查询权限用户
create user 'xuchenghong'@'%' identified by 'XCH123@jiankang.com';

grant select on *.* to 'xuchenghong'@'%' identified by 'XCH123@jiankang.com';

flush privileges; 
```
授权时提示：`Access denied for user 'root'@'%' to database 'walle'`

```sql
mysql> GRANT ALL PRIVILEGES ON walle.* TO 'walle'@'%';
ERROR 1044 (42000): Access denied for user 'root'@'%' to database 'walle'
```
查看 `root@%` 的权限

```sql
mysql> select Host,User,Grant_priv,Super_priv from mysql.user;
+-----------+---------------+------------+------------+
| Host      | User          | Grant_priv | Super_priv |
+-----------+---------------+------------+------------+
| localhost | root          | Y          | Y          |
| localhost | mysql.session | N          | Y          |
| localhost | mysql.sys     | N          | N          |
| %         | root          | N          | Y          |
+-----------+---------------+------------+------------+
6 rows in set (0.00 sec)
```
设置 `Grant_priv` 为 `Y`

```sql
mysql> update mysql.user set Grant_priv='Y',Super_priv='Y' where user = 'root' and host = '%';
Query OK, 1 row affected (0.00 sec)
mysql> flush privileges;
Query OK, 0 rows affected (0.04 sec)
```
重启 MySQL 服务，就可以授权了
# MySQL 数据备份
## 一、逻辑备份
推荐工具：mysqldump、mysqlpump（多线程，5.7版本之后支持）

**本质**：导出的 SQL 语句文件
**优点**：无论采用什么引擎，都可导出 SQL 文件
**缺点**：速度较慢、无法直接增量备份
**备份级别**：表级、库级、全库

语法：

```bash
# 表级
mysqldump [OPTIONS] database [tables]
# 库级
mysqldump [OPTIONS] --databases [OPTIONS] DB1 [DB2 DB3...]
# 全库
mysqldump [OPTIONS] --all-databases [OPTIONS]

# 表级
mysqlpump [OPTIONS] database [tables]
# 库级
mysqlpump [OPTIONS] --databases DB1 [DB2 DB3...]
# 全库
mysqlpump [OPTIONS] [--all-databases]
```

示例：

1. 表级
```bash
# 备份 test-db 库中的 t_disease 表
mysqldump -h192.168.1.11 -uroot -P3306 -p123456Aa. test-db t_disease > /root/t_disease.sql
# 还原
mysql -h192.168.1.11 -uroot -P3306 -p123456Aa. test-db < /root/t_disease.sql
```
2. 库级
```bash
# 备份整个 test-db 库
mysqldump -h192.168.1.11 -uroot -P3306 -p123456Aa. --databases test-db > /root/test-db.sql
# 还原
mysql -h192.168.1.11 -uroot -P3306 -p123456Aa. < /root/test-db.sql
```
3. 全库

> 注意点
> 1. 必须开启 bin-log 日志
> 2. --master-data：将二进制日志位置和文件名写入到备份文件，=1：不注释该行，=2：注释该行，默认 0
> 3.  --single-transaction：适用于innoDB引擎，保证一致性，服务可用性

```bash
# 备份整个 MySQL 服务的所有库
mysqldump -h192.168.1.11 -uroot -P3306 -p123456Aa. --all-databases --master-data --single-transaction > all.sql
# 还原
mysql -h192.168.1.11 -uroot -P3306 -p123456Aa. < /root/all.sql
```
4. 全库 + 增量

> 需要搭配 bin-log 日志恢复

```bash
# 备份整个 MySQL 服务的所有库
mysqldump -h192.168.1.11 -uroot -P3306 -p123456Aa. --all-databases --master-data --single-transaction > all.sql
# 还原
mysql -h192.168.1.11 -uroot -P3306 -p123456Aa. < /root/all.sql
# 使用 bin-log 还原 mysql 指定位置：4 ~ 750 之间的操作数据
mysqlbinlog --start-position=4 --stop-position=750 /root/mysql-bin.000001 | -h192.168.1.11 -uroot -P3306 -p123456Aa.
```

## 二、物理备份
推荐工具：xtrabackup

**本质**：备份数据库的 data 文件
**优点**：快速、可靠、支持增量
**缺点**：只能增量备份 InnoDB 引擎的数据库

安装方式：
```bash
wget https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.9/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.9-1.el7.x86_64.rpm
```
```bash
yum install -y percona-xtrabackup-24-2.4.9-1.el7.x86_64.rpm 
```
1. 全库

① 首次全量备份
```bash
innobackupex --host=192.168.1.11 --port=3306 --user=root --password=123456Aa. /root/backup/
```
② 将备份过程中新产生的日志合并到备份文件中

```bash
innobackupex --host=192.168.1.11 --port=3306 --user=root --password=123456Aa. --apply-log /root/backup/2021-11-22_17-27-44
```
③ 恢复
```bash
innobackupex --defaults-file=/etc/my.cnf --copy-back /root/backup/2021-11-22_17-27-44/
```
④ 恢复文件权限

```bash
chown -R mysql:mysql /home/mysql/data/
```

2. 增量备份

增量备份只是重复步骤 ② ，即不断的将操作日志整合到全量备份文件中

```bash
innobackupex --host=192.168.1.11 --port=3306 --user=root --password=123456Aa. --apply-log --redo-only /root/backup/2021-11-22_17-27-44
```

# MySQL 主从复制
## 一、基本原理

> master 将数据库的改变写入二进制 binlog 日志，slave 同步二进制日志，并根据二进制日志进行数据重演操作，实现数据异步同步
> - slave 端的 IO 线程发送请求给 master 端的 binlog dump 线程。
> - master 端 binlog dump 线程获取二进制日志信息(文件名和位置信息)发送给 slave 端的 IO 线程。
> - salve 端 IO 线程获取到的内容依次写到 slave 端 relay log 里，并把 master 端的 bin-log 文件名和位置记录到 master.info 里
> - salve 端的 SQL 线程，检测到 relay log 中内容更新，就会解析 relay log 里更新的内容，并执行这些操作，从而达到和 master 数据一致
> 
> ![在这里插入图片描述](https://img-blog.csdnimg.cn/665458a656194cadb868bc57ff102901.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_20,color_FFFFFF,t_70,g_se,x_16)
> 
**扩展**：relay log 中继日志

**作用**：记录从(slave)服务器接收来自主(master)服务器的二进制日志.

**场景**：用于主从复制

master 主服务器将自己的二进制日志发送给 slave 从服务器，slave 先保存在自己的中继日志中，然后再执行自己本地的 relay log 里的 sql 达到数据库更改和 master 保持一致。
```bash
[mysqld]
#指定二进制日志存放位置及文件名
relay-log=/mysql/data/relaylog
```
## 二、常用架构

- **双机热备（AB复制）**

默认情况下，master 接受读写请求，slave 只接受读请求以减轻 master 的压力。
![在这里插入图片描述](https://img-blog.csdnimg.cn/e9cbedabf1404747a3971f182ebb1abd.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_17,color_FFFFFF,t_70,g_se,x_16)

- **并联复制（一主多从）**

**优点**：解决 slave 的单点故障，同时也分担读压力

**缺点**：间接增加 master 的压力（传输二进制日志压力）
![在这里插入图片描述](https://img-blog.csdnimg.cn/bfc5c23e57dc46c881a3705782ba911f.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_14,color_FFFFFF,t_70,g_se,x_16)
## 三、双机热备架构搭建
**标准化环境**
|主机名称  | IP地址 | 版本|角色|
|--|--|--|--|
| master.server | 192.168.1.6 |5.7.35|MASTER 主服务器
|slave.server|192.168.1.7|5.7.35|SLAVE 从服务器

**主从服务器搭建 MySQL**
| 选项 |  值| 
|--|:--|
|版本| mysql-boost-5.7.35
|安装目录 | /mysql
|数据目录 |/mysql/data
|配置文件|/mysql/my.cnf
|sock 文件|/mysql/mysql.sock
|端口|3306
|字符集|utf8mb4

### 1、安装 MySQL5.7
这里为了安装方便，使用脚本一键安装，slave 服务器只需修改脚本中的主机名变量即可

```bash
vi install.sh
```
内容如下
```bash
# MySQL安装主目录
basedir=/mysql
# 数据库 root 用户密码
passwd='123456Aa.'
# 主机名
hostname='master.server'

# 环境初始化
hostnamectl set-hostname $hostname
systemctl stop firewalld.service && systemctl disable firewalld.service
setenforce 0 && sed -i 's/enforcing/disabled/g' /etc/selinux/config
mv /etc/yum.repos.d/CentOS-* /tmp/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all && yum makecache

# 安装依赖
yum groupinstall -y "Development Tools"
yum install -y ncurses-devel cmake libaio-devel openssl-devel vim wget net-tools bash-completion
yum remove -y mariadb* && rm -f /etc/my.cnf
source /usr/share/bash-completion/bash_completion

# 下载源码包
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.35.tar.gz
tar -zxvf mysql-boost-5.7.35.tar.gz

# 编译安装
cd mysql-5.7.35/
cmake . \
-DCMAKE_INSTALL_PREFIX=$basedir \
-DMYSQL_DATADIR=$basedir/data \
-DSYSCONFDIR=$basedir \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=$basedir/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system \
-DWITH_BOOST=boost
make -j `cat /proc/cpuinfo | grep 'processor' | wc -l` && make install

# 创建基本配置文件
cat > $basedir/my.cnf << EOF
[mysqld]
port=3306
basedir=$basedir
datadir=$basedir/data
socket=$basedir/mysql.sock
EOF

# 初始化 mysql
cd $basedir && mkdir mysql-files && chmod 750 mysql-files/
useradd -r -s /sbin/nologin mysql
chown -R mysql:mysql $basedir
bin/mysqld --defaults-file=$basedir/my.cnf --initialize --user=mysql --basedir=$basedir &>> /tmp/passwd
bin/mysql_ssl_rsa_setup --datadir=$basedir/data
cp support-files/mysql.server /etc/init.d/mysql
service mysql start

# 配置 root 密码以及远程访问权限
cat > init_root.sql << EOF
set password for root@localhost = password('$passwd');
grant all privileges on *.* to 'root'@'%' identified by '$passwd';
flush privileges;
EOF
initpass=$(grep 'A temporary password' /tmp/passwd | awk '{print $NF}')
bin/mysql --connect-expired-password -uroot -p$initpass < init_root.sql
rm -f init_root.sql

# 配置mysql的开机启动
chkconfig --add mysql
chkconfig mysql on

# 配置环境变量
echo "export PATH=$PATH:$basedir/bin" >> ~/.bashrc
source ~/.bashrc
```
安装
```bash
source install.sh
```
### 2、开启 bin-log 配置
- **Master**

修改 master 服务器的配置，开启 bin-log

```bash
vi /mysql/my.cnf
```
添加如下内容
```bash
server-id=6
log-bin=/mysql/data/binlog
```
重启数据库生效
```bash
service mysql restart
```
- **Slave**

修改 Slave 服务器的配置，开启 relay-log
```bash
vi /mysql/my.cnf
```
```bash
server-id=7
relay-log=/mysql/data/relaylog
```
重启数据库生效
```bash
service mysql restart
```
### 3、配置主从同步
- **Master**

Master 数据库赋予 Slave（192.168.1.7）有读取日志的权限

```sql
mysql> grant FILE on *.* to 'root'@'192.168.1.7' identified by '123456Aa.';
mysql> grant replication slave on *.* to 'root'@'192.168.1.7' identified by '123456Aa.';
mysql> flush privileges;
```
查看二进制文件的名称及位置
```sql
mysql> show master status;
+---------------+----------+--------------+------------------+-------------------+
| File          | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+---------------+----------+--------------+------------------+-------------------+
| binlog.000001 |      879 |              |                  |                   |
+---------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)
```

- **Slave**

Slave 配置 Master 数据库的相关信息
> master_host：主机的IP地址
master_user：主机的user账号
master_password：主机的user账号密码
master_port：主机MySQL的端口号
master_log_file：二进制日志文件名称
master_log_pos：二进制日志文件位置

```sql
mysql> change master to master_host='192.168.1.6',master_user='root',master_password='123456Aa.',master_port=3306,master_log_file='binlog.000001',master_log_pos=879;
```
启动slave数据同步
```sql
mysql> start slave;
mysql> show slave status\G
```
看到这两项配置显示为 yes 说明成功

```sql
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```

**常见问题解决方案**

在配置主从时，一般遇到错误，大部分都是change master to语句写错了（80%），解决方案：
```sql
mysql> stop slave;
mysql> reset slave;
mysql> change master to master_host='10.1.1.10',master_user='slave',master_password='123',master_port=3306,master_log_file='binlog.000002',master_log_pos=597;
mysql> start slave;
```
### 4、半同步复制插件（可选）

> 半同步复制就是 master 每 commit 一个事务（简单来说就是做一个改变数据的操作），要确保 slave 接受完主服务器发送的 binlog 日志文件并写入到自己的中继日志 relay log 里，然后会给 master 信号，告诉对方已经接收完毕，这样 master才 能把事物成功 commit。这样就保证了 master-slave 的数据绝对的一致（但是以牺牲master的性能为代价，因为要等待 slave 的返回信号。)
![在这里插入图片描述](https://img-blog.csdnimg.cn/b109bdfd51c447c9b727070451e55d68.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_17,color_FFFFFF,t_70,g_se,x_16)

安装 plugin 插件，（需要先完成主从配置）

- **MASTER**
```sql
mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';
mysql> set global rpl_semi_sync_master_enabled=on;
mysql> show global variables like 'rpl_semi_sync%';
+-------------------------------------------+------------+
| Variable_name                             | Value      |
+-------------------------------------------+------------+
| rpl_semi_sync_master_enabled              | ON         |
| rpl_semi_sync_master_timeout              | 10000      |
| rpl_semi_sync_master_trace_level          | 32         |
| rpl_semi_sync_master_wait_for_slave_count | 1          |
| rpl_semi_sync_master_wait_no_slave        | ON         |
| rpl_semi_sync_master_wait_point           | AFTER_SYNC |
+-------------------------------------------+------------+
6 rows in set (0.00 sec)
```
- **SLAVE**
```sql
mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
mysql> set global rpl_semi_sync_slave_enabled=on;
mysql> show global variables like 'rpl_semi_sync%';
+---------------------------------+-------+
| Variable_name                   | Value |
+---------------------------------+-------+
| rpl_semi_sync_slave_enabled     | ON    |
| rpl_semi_sync_slave_trace_level | 32    |
+---------------------------------+-------+
2 rows in set (0.00 sec)
# 重启 IO 线程生效
mysql> stop slave IO_THREAD;
mysql> start slave IO_THREAD;
```
主库随便插入一条数据后，查看 `Rpl_semi_sync_master_yes_tx ` 值有增加则配置成功
```sql
mysql> show global status like 'rpl_semi_sync%_yes_tx'; 
+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| Rpl_semi_sync_master_yes_tx | 1     |
+-----------------------------+-------+
1 row in set (0.00 sec)
```
等待时间的修改（默认10s）
```sql
mysql> set global rpl_semi_sync_master_timeout=3000;
mysql> show global variables like 'rpl_semi_sync%';
+-------------------------------------------+------------+
| Variable_name                             | Value      |
+-------------------------------------------+------------+
| rpl_semi_sync_master_enabled              | ON         |
| rpl_semi_sync_master_timeout              | 3000       |
| rpl_semi_sync_master_trace_level          | 32         |
| rpl_semi_sync_master_wait_for_slave_count | 1          |
| rpl_semi_sync_master_wait_no_slave        | ON         |
| rpl_semi_sync_master_wait_point           | AFTER_SYNC |
+-------------------------------------------+------------+
6 rows in set (0.00 sec)
```
卸载半同步复制插件（不需要时）

```sql
mysql> select plugin_name,load_option from information_schema.plugins;
mysql> uninstall plugin 插件名称;
```

# MHA 高可用集群
## 一、MHA  简介

> MHA（Master High Availability）目前在 MySQL 高可用方面是一个相对成熟的解决方案，是一套优秀的作为 MySQL 高可用性环境下故障切换和主从提升的高可用软件。在 MySQL 故障切换过程中， MHA 能做到在 0~30秒 之内自动完成数据库的故障切换操作，并且在进行故障切换的过程中，MHA 能在较大程度上保证数据的一致性，以达到真正意义上的高可用。
![在这里插入图片描述](https://img-blog.csdnimg.cn/8c4ee449064446c58d4d506d0021c0b1.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_13,color_FFFFFF,t_70,g_se,x_16)


## 二、基本原理
![在这里插入图片描述](https://img-blog.csdnimg.cn/e7d3b739c7634bdaaa8470fddcf25243.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)

- 当 master 出现故障时，通过对比 slave 之间 I/O 线程读取 master 上 binlog 的位置，选取最接近的 slave 做为最新的 slave（latest slave）
- 其它 slave 通过与 latest slave 对比生成差异中继日志，并应用。
- 在 latest slave 上应用从 master 保存的 binlog，同时将 latest slave 提升为 master。
- 最后在其它 slave 上应用相应的差异中继日志并开始从新的 master 开始复制。

## 三、MHA 组件

- MHA Manager（管理节点）

通常单独部署在一台独立机器上管理多个 master/slave 集群(组)，每个 master/slave 集群称作一个 application，用来管理统筹整个集群。

MHA Manager 运行一些工具，比如 masterha_manager 工具实现自动监控 MySQL Master 和实现 master 故障切换，其它工具手动实现 master 故障切换、在线 mater 转移、连接检查等等。一个 Manager 可以管理多个 master-slave 集群
| 工具                      | 说明                       |
| ------------------------- | -------------------------- |
| masterha_check_ssh    | 检查MHA的SSH配置           |
| masterha_check_repl   | 检查MySQL复制              |
| masterha_manager    | 启动MHA                    |
| masterha_check_status | 检测当前MHA运行状态        |
| masterha_master_monitor   | 监测master是否宕机         |
| masterha_master_switch    | 控制故障转移(自动或手动)   |
| masterha_conf_host        | 添加或删除配置的server信息 |


- MHA Node（数据节点）

运行在每台 MySQL 服务器上(master/slave/manager)，它通过监控具备解析和清理 logs 功能的脚本来加快故障转移。

MHA Node 部署在所有运行 MySQL 的服务器上，无论是 master 还是 slave 。主要有三个作用：

1. 保存二进制日志：如果能够访问故障 master，会拷贝 master 的二进制日志
2. 应用差异中继日志：​从拥有最新数据的 slave 上生成差异中继日志，然后应用差异日志。
3. 清除中继日志：在不停止 SQL 线程的情况下删除中继日志。




| 工具                  | 说明                                            |
| --------------------- | ----------------------------------------------- |
| save_binary_logs      | 保存和复制master的二进制日志                    |
| apply_diff_relay_logs | 识别差异的中继日志事件并应用于其它slave         |
| filter_mysqlbinlog    | 去除不必要的ROLLBACK事件(MHA已不再使用这个工具) |
| purge_relay_logs      | 清除中继日志(不会阻塞SQL线程)                   |
## 四、MHA 架构搭建

本次数据库采用一主多从的并联架构
|主机名称  | IP地址|安装组件|角色|
|--|--|--|--|
| master.server | 192.168.1.6|MHA-Node、MySQL |MASTER 主服务器
|slave1.server|192.168.1.7|MHA-Node、MySQL|SLAVE1 从服务器
|slave2.server|192.168.1.8|MHA-Node、MySQL|SLAVE2 从服务器
|mha.server|192.168.1.9|MHA-Node、MHA-Manager|MHA 管理服务器

|系统版本|MySQL版本|MHA版本|
|--|--|--|
|CentOS 7.9|	MySQL-5.7.35|	mha4mysql-manager-0.58-0.el7、mha4mysql-node-0.58-0.el7

### 1、服务器标准化
服务器初始化脚本，所有服务器执行，只需修改主机名即可

```bash
vi init.sh
```
```bash
# 主机名
hostname='master.server'

# 初始化
hostnamectl set-hostname $hostname
systemctl stop firewalld.service && systemctl disable firewalld.service
setenforce 0 && sed -i 's/enforcing/disabled/g' /etc/selinux/config
mv /etc/yum.repos.d/CentOS-* /tmp/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all && yum makecache

# 安装依赖
yum install -y vim wget net-tools ntp bash-completion
source /usr/share/bash-completion/bash_completion

# 配置时间同步
cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
server 0.cn.pool.ntp.org
server 1.cn.pool.ntp.org
server 2.cn.pool.ntp.org
server 3.cn.pool.ntp.org
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF
systemctl stop chronyd && systemctl disable chronyd
systemctl start ntpd && systemctl enable ntpd
ntpdate -u 0.cn.pool.ntp.org
hwclock --systohc
```

```bash
source init.sh
```

配置免密登录

```bash
ssh-keygen
```
依次将公钥发送到每个服务器上，此步骤为两两互信的，所以每台服务器都要执行该步骤，确保互联互通
```bash
for i in 6 7 8 9;do ssh-copy-id 192.168.1.$i;done
```
给 Master 主机网卡挂载虚拟IP ：192.168.1.5

```bash
# 创建虚拟网卡ens33:0 IP地址为 192.168.1.5
ifconfig ens33:0 192.168.1.5 broadcast 192.168.1.255 netmask 255.255.255.0 up
```
永久生效

```bash
cat > /etc/sysconfig/network-scripts/ifcfg-ens33:0 << EOF
DEVICE=ens33:0                                      
ONBOOT=yes                
BOOTPROTO=static                  
IPADDR=192.168.1.5
NETMASK=255.255.255.0      
GATEWAY=192.168.1.1
USERCTL=no   
EOF
```

### 2、部署 MySQL 主从同步
**本次采用一主两从的架构，并且同步方式使用 GTID 模式**

首先在 master.server、slave1.server、slave2.server 上执行数据库安装脚本，不同服务器只需修改主机名变量。

```bash
vi install.sh
```

```bash
# MySQL安装主目录
basedir=/mysql
# 数据库 root 用户密码
passwd='123456Aa.'
# 主机名
hostname='master.server'

# 安装依赖
yum groupinstall -y "Development Tools"
yum install -y ncurses-devel cmake libaio-devel openssl-devel
yum remove -y mariadb* && rm -f /etc/my.cnf
source /usr/share/bash-completion/bash_completion

# 下载源码包
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.35.tar.gz
tar -zxvf mysql-boost-5.7.35.tar.gz

# 编译安装
cd mysql-5.7.35/
cmake . \
-DCMAKE_INSTALL_PREFIX=$basedir \
-DMYSQL_DATADIR=$basedir/data \
-DSYSCONFDIR=$basedir \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=$basedir/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system \
-DWITH_BOOST=boost
make -j `cat /proc/cpuinfo | grep 'processor' | wc -l` && make install

# 创建基本配置文件
cat > $basedir/my.cnf << EOF
[mysqld]
port=3306
basedir=$basedir
datadir=$basedir/data
socket=$basedir/mysql.sock
EOF

# 初始化 mysql
cd $basedir && mkdir mysql-files && chmod 750 mysql-files/
useradd -r -s /sbin/nologin mysql
chown -R mysql:mysql $basedir
bin/mysqld --defaults-file=$basedir/my.cnf --initialize --user=mysql --basedir=$basedir &>> /tmp/passwd
bin/mysql_ssl_rsa_setup --datadir=$basedir/data
cp support-files/mysql.server /etc/init.d/mysql
service mysql start

# 配置 root 密码以及远程访问权限
cat > init_root.sql << EOF
set password for root@localhost = password('$passwd');
grant all privileges on *.* to 'root'@'%' identified by '$passwd';
flush privileges;
EOF
initpass=$(grep 'A temporary password' /tmp/passwd | awk '{print $NF}')
bin/mysql --connect-expired-password -uroot -p$initpass < init_root.sql
rm -f init_root.sql

# 配置mysql的开机启动
chkconfig --add mysql
chkconfig mysql on

# 配置环境变量
echo "export PATH=$PATH:$basedir/bin" >> ~/.bashrc
source ~/.bashrc
```

```bash
source install.sh
```
**开启 GTID 配置**

- **MASTER**
```bash
vi /mysql/my.cnf
```
添加如下内容
```bash
server-id=6
log-bin=/mysql/data/binlog
gtid-mode=on
log-slave-updates=1
enforce-gtid-consistency
```
重启数据库生效
```bash
service mysql restart
```
- **Slave1**
```bash
vi /mysql/my.cnf
```
添加如下内容
```bash
server-id=7
log-bin=/mysql/data/binlog
relay-log=/mysql/data/relaylog
gtid-mode=on
log-slave-updates=1
enforce-gtid-consistency
skip-slave-start
```
重启数据库生效
```bash
service mysql restart
```
- **Slave2**
```bash
vi /mysql/my.cnf
```
添加如下内容
```bash
server-id=8
log-bin=/mysql/data/binlog
relay-log=/mysql/data/relaylog
gtid-mode=on
log-slave-updates=1
enforce-gtid-consistency
skip-slave-start
```
重启数据库生效
```bash
service mysql restart
```

**配置主从数据同步**

第一步：在 MASTER 服务器中创建一个 slave 同步账号

```sql
mysql> create user 'slave'@'%' identified by '123456Aa.';
mysql> grant replication slave on *.* to 'slave'@'%';
mysql> flush privileges;
```

第二步：创建一个 mha 账号（方便后期 MHA 监控主从同步状态）

```sql
mysql> create user 'mha'@'%' identified by '123456Aa.';
mysql> grant all privileges on *.* to 'mha'@'%';
mysql> flush privileges;
```

第三步：在 slave1 与 slave2 中配置主从数据同步

```sql
mysql> change master to master_host='192.168.1.6',master_port=3306,master_user='slave',master_password='123456Aa.',master_auto_position=1;
mysql> start slave;
mysql> show slave status\G
```
看到这两项配置显示为 yes 说明成功

```sql
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```

### 3、部署 MHA
- **所有主机都要安装 mha-node**
```bash
yum install -y https://github.com/yoshinorim/mha4mysql-node/releases/download/v0.58/mha4mysql-node-0.58-0.el7.centos.noarch.rpm
```
**注意**：这里会将 mariadb 作为依赖安装，所以要删除自动生成的 /etc/my.cnf 文件，以免影响 MySQL 启动。

```bash
rm -f /etc/my.cnf
```


- **接下来的操作全部在 mha.server 管理主机上进行**

**3.1、mha 管理主机下载安装 mha-manager**
```bash
yum install -y https://github.com/yoshinorim/mha4mysql-manager/releases/download/v0.58/mha4mysql-manager-0.58-0.el7.centos.noarch.rpm
```


**3.2、创建 mha 工作目录**
```bash
mkdir -p /data/mha/{bin,etc,log,mysql}
```

**3.3、创建 `master_ip_failover.sh` 脚本**

```bash
vim /data/mha/bin/master_ip_failover.sh
```
内容如下
```perl
#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;

my (
    $command,          $ssh_user,        $orig_master_host, $orig_master_ip,
    $orig_master_port, $new_master_host, $new_master_ip,    $new_master_port
);

my $gateway = '192.168.1.1';
my $vip  = shift;
my $bcast = '192.168.1.255';
my $netmask = '255.255.255.0';
my $interface = 'ens33';
my $key = shift;
my $ssh_start_vip = "sudo /sbin/ifconfig $interface:$key $vip netmask $netmask && sudo /sbin/arping -f -q -c 5 -w 5 -I $interface -s $vip  -U $gateway";
my $ssh_stop_vip = "sudo /sbin/ifconfig $interface:$key down";

GetOptions(
    'command=s'          => \$command,
    'ssh_user=s'         => \$ssh_user,
    'orig_master_host=s' => \$orig_master_host,
    'orig_master_ip=s'   => \$orig_master_ip,
    'orig_master_port=i' => \$orig_master_port,
    'new_master_host=s'  => \$new_master_host,
    'new_master_ip=s'    => \$new_master_ip,
    'new_master_port=i'  => \$new_master_port,
);

exit &main();

sub main {

    #print "\n\nIN SCRIPT TEST====$ssh_stop_vip==$ssh_start_vip===\n\n";

    if ( $command eq "stop" || $command eq "stopssh" ) {

        my $exit_code = 1;
        eval {
            print "Disabling the VIP on old master: $orig_master_host \n";
            &stop_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn "Got Error: $@\n";
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "start" ) {

        my $exit_code = 10;
        eval {
            print "Enabling the VIP - $vip on the new master - $new_master_host \n";
            &start_vip();
            $exit_code = 0;
        };
        if ($@) {
            warn $@;
            exit $exit_code;
        }
        exit $exit_code;
    }
    elsif ( $command eq "status" ) {
        print "Checking the Status of the script.. OK \n";
        exit 0;
    }
    else {
        &usage();
        exit 1;
    }
}

sub start_vip() {
    my $bcast  = `ssh $ssh_user\@$new_master_host sudo /sbin/ifconfig | grep 'Bcast' | head -1 | awk '{print \$3}' | awk -F":" '{print \$2}'`;
    chomp $bcast;
    my $gateway  = `ssh $ssh_user\@$new_master_host sudo /sbin/route -n  | grep 'UG' | awk '{print \$2}'`;
    chomp $gateway;
    my $netmask  = `ssh $ssh_user\@$new_master_host sudo /sbin/ifconfig | grep 'Bcast' | head -1 | awk '{print \$4}' | awk -F":" '{print \$2}'`;
    chomp $netmask;
    my $ssh_start_vip = "sudo /sbin/ifconfig $interface:$key $vip broadcast $bcast netmask $netmask && sudo /sbin/arping -f -q -c 5 -w 5 -I $interface -s $vip  -U $gateway";
    print "=======$ssh_start_vip=================\n";
    `ssh $ssh_user\@$new_master_host \" $ssh_start_vip \"`;
}
sub stop_vip() {
    my $ssh_user = "root";
    print "=======$ssh_stop_vip==================\n";
    `ssh $ssh_user\@$orig_master_host \" $ssh_stop_vip \"`;
}

sub usage {
    print
    "Usage: master_ip_failover --command=start|stop|stopssh|status --orig_master_host=host --orig_master_ip=ip --orig_master_port=port --new_master_host=host --new_master_ip=ip --new_master_port=port\n";
}
```
添加可执行权限
```bash
chmod + /data/mha/bin/master_ip_failover.sh
```

**3.4、创建 MHA 管理配置文件**
```bash
vim /data/mha/etc/app1.conf
```
```bash
[server default]
# 设置监控用户和密码
user=mha
password=123456Aa.
# 设置复制环境中的复制用户和密码
repl_user=root
repl_password=123456Aa.
# 设置ssh的登录用户名
ssh_user=root
# 设置监控主库,发送ping包的时间间隔,默认是3秒,尝试三次没有回应的时候自动进行failover
ping_interval=3
# 设置mgr的工作目录
manager_workdir=/data/mha/
# 设置mysql master保存binlog的目录,以便MHA可以找到master的二进制日志
master_binlog_dir=/mysql/data/
# 设置master的pid文件
master_pid_file=/mysql/data/master.server.pid
# 设置mysql master在发生切换时保存binlog的目录（在mysql master上创建这个目录）
remote_workdir=/data/mha/mysql/
# 设置mgr日志文件（MHA遇到问题，主要看这个日志）
manager_log=/data/mha/log/app1.log
# MHA到master的监控之间出现问题,MHA Manager将会尝试从slave1和slave2登录到master上
secondary_check_script=/usr/bin/masterha_secondary_check -s 192.168.1.7 -s 192.168.1.8 --user=root --port=22 --master_host=192.168.1.6 --master_port=3306
# 设置自动failover时候的切换脚本（故障发生时，自动挂载VIP到SLAVE1或SLAVE2）
master_ip_failover_script="/data/mha/bin/master_ip_failover.sh 192.168.1.5 1"
# 设置手动切换时候的切换脚本
#master_ip_online_change_script="/data/mha/bin/master_ip_online_change.sh 192.168.1.5 1"
# 设置故障发生后关闭故障主机脚本
#shutdown_script="/data/mha/bin/power_manager"
[server1]
hostname=192.168.1.6
port= 3306
candidate_master=1
[server2]
hostname=192.168.1.7
port= 3306
candidate_master=1
[server3]
hostname=192.168.1.8
port= 3306
candidate_master=1
```

**3.5、检测初始状态**

```bash
# 检测主机 SSH 是否互信
masterha_check_ssh --conf=/data/mha/etc/app1.conf

# 检测 MySQL 集群状态
masterha_check_repl --conf=/data/mha/etc/app1.conf

# 检查 MHA 状态
masterha_check_status --conf=/data/mha/etc/app1.conf
```
**3.6、开启 MHA Manager 监控**
```bash
nohup masterha_manager --conf=/data/mha/etc/app1.conf --remove_dead_master_conf --ignore_last_failover >> /data/mha/log/manager.log 2>&1 &
```
再次查看监控状态：
```bash
masterha_check_status --conf=/data/mha/etc/app1.conf
```
如果正常，会显示 `PING_OK` ，否则会显示 `NOT_RUNNING` ，说明 MHA 监控没有开启


**3.7、手动停止监控命令:**
```bash
masterha_stop --conf=/data/mha/etc/app1.conf
```
### 4、FailOver 故障验证
停止 master 数据库服务器，模拟故障

```bash
shutdown -h now
```
已经发现 vip 漂移到 192.168.1.7 服务器上

```bash
[root@slave1 ~]# ifconfig 
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.7  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::41c3:1703:365c:49e6  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:ab:e9:1b  txqueuelen 1000  (Ethernet)
        RX packets 215840  bytes 286572560 (273.2 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 127683  bytes 15762276 (15.0 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens33:1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.5  netmask 255.255.255.0  broadcast 192.168.1.255
        ether 00:0c:29:ab:e9:1b  txqueuelen 1000  (Ethernet)

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 153  bytes 27784 (27.1 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 153  bytes 27784 (27.1 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

查看 Slave 服务器的状态，master 主机已经切换为 192.168.1.7

```bash
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.1.7
                  Master_User: root
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: binlog.000002
          Read_Master_Log_Pos: 362
               Relay_Log_File: relaylog.000002
                Relay_Log_Pos: 405
        Relay_Master_Log_File: binlog.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```
# MySQL 读写分离
## 一、读写分离介绍
当数据库请求增多时，单例数据库不能够满足业务需求。需要进行数据库实例的扩容。多台数据库同时相应请求。也就是说需要对数据库的请求，进行负载均衡。

但是由于数据库服务特殊原因，数据库扩容基本要求为：数据的一致性和完整性。所以要保证多台数据库实例的数据一致性和完整性，以 MySQL 为例来说，官方提供了主从复制机制。

数据库的负载均衡不同于其他服务的负载均衡，数据要求一致性。基于主从复制的基础上，常见的数据库负载均衡使用的是读写分离方式。写入主数据库，读取到从数据库。可以认为数据库读写分离，是一种特殊的负载均衡实现。

## 二、常见的实现方式

**1. 业务代码的读写分离**

需要在业务代码中，判断数据操作是读还是写，读连接从数据服务器操作，写连接主数据库服务器操作

**2. 中间件代理方式的读写分离**

![在这里插入图片描述](https://img-blog.csdnimg.cn/f4d492ebce3e4c0299091c2a6d98a792.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_20,color_FFFFFF,t_70,g_se,x_16)

在业务代码中，数据库的操作，不直接连接数据库，而是先请求到中间件服务器（代理）

由代理服务器，判断是读操作去从数据服务器，写操作去主数据服务器
|软件名 | 类型 |
| ----------- | --------------------------------------------------------- |
| MySQL Proxy | MySQL官方 测试版 不再维护
| Atlas       | 奇虎360
| DBProxy     | 美团点评
| Amoeba      | 早期阿里巴巴
| cobar       | 阿里巴巴
| MyCat       | 基于阿里开源的Cobar
| kingshared  | go语言开发
| proxysql    | <http://www.proxysql.com>

问：如何选择？

- 业务实现读写分离，操作方便，成本低，当前的开发框架基本支持读写分离

- 中间件代理服务器，除了能够实现读写分离，还可以作为数据库集群的管理平台

## 三、MyCAT 读写分离搭建

|主机名称|IP地址|版本|角色
|--|--|--|--|
|master.server|	192.168.1.6|	5.7.35|	MASTER 主服务器
|slave.server|	192.168.1.7|	5.7.35	|SLAVE 从服务器
|mycat.server|	192.168.1.8|	1.6.7.4|MYCAT 中间代理服务器

### 1、MySQL 主从搭建

首先在 master.server、slave.server 上执行数据库安装脚本，不同服务器只需修改主机名变量。

```bash
vi install.sh
```

```bash
# MySQL安装主目录
basedir=/mysql
# 数据库 root 用户密码
passwd='123456Aa.'
# 主机名
hostname='master.server'

# 主机初始化
hostnamectl set-hostname $hostname
systemctl stop firewalld.service && systemctl disable firewalld.service
setenforce 0 && sed -i 's/enforcing/disabled/g' /etc/selinux/config
mv /etc/yum.repos.d/CentOS-* /tmp/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all && yum makecache

# 安装依赖
yum groupinstall -y "Development Tools"
yum install -y ncurses-devel cmake libaio-devel openssl-devel vim wget net-tools ntp bash-completion
yum remove -y mariadb* && rm -f /etc/my.cnf
source /usr/share/bash-completion/bash_completion

# 配置时间同步
cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/drift
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict ::1
server 0.cn.pool.ntp.org
server 1.cn.pool.ntp.org
server 2.cn.pool.ntp.org
server 3.cn.pool.ntp.org
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
EOF
systemctl stop chronyd && systemctl disable chronyd
systemctl start ntpd && systemctl enable ntpd
ntpdate -u 0.cn.pool.ntp.org
hwclock --systohc

# 下载源码包
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.35.tar.gz
tar -zxvf mysql-boost-5.7.35.tar.gz

# 编译安装
cd mysql-5.7.35/
cmake . \
-DCMAKE_INSTALL_PREFIX=$basedir \
-DMYSQL_DATADIR=$basedir/data \
-DSYSCONFDIR=$basedir \
-DMYSQL_TCP_PORT=3306 \
-DMYSQL_UNIX_ADDR=$basedir/mysql.sock \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_SSL=system \
-DWITH_BOOST=boost
make -j `cat /proc/cpuinfo | grep 'processor' | wc -l` && make install

# 创建基本配置文件
cat > $basedir/my.cnf << EOF
[mysqld]
port=3306
basedir=$basedir
datadir=$basedir/data
socket=$basedir/mysql.sock
EOF

# 初始化 mysql
cd $basedir && mkdir mysql-files && chmod 750 mysql-files/
useradd -r -s /sbin/nologin mysql
chown -R mysql:mysql $basedir
bin/mysqld --defaults-file=$basedir/my.cnf --initialize --user=mysql --basedir=$basedir &>> /tmp/passwd
bin/mysql_ssl_rsa_setup --datadir=$basedir/data
cp support-files/mysql.server /etc/init.d/mysql
service mysql start

# 配置 root 密码以及远程访问权限
cat > init_root.sql << EOF
set password for root@localhost = password('$passwd');
grant all privileges on *.* to 'root'@'%' identified by '$passwd';
flush privileges;
EOF
initpass=$(grep 'A temporary password' /tmp/passwd | awk '{print $NF}')
bin/mysql --connect-expired-password -uroot -p$initpass < init_root.sql
rm -f init_root.sql

# 配置mysql的开机启动
chkconfig --add mysql
chkconfig mysql on

# 配置环境变量
echo "export PATH=$PATH:$basedir/bin" >> ~/.bashrc
source ~/.bashrc
```
安装
```bash
source install.sh
```

**开启 GTID 配置**

- **MASTER**
```bash
vi /mysql/my.cnf
```
添加如下内容
```bash
server-id=6
log-bin=/mysql/data/binlog
gtid-mode=on
log-slave-updates=1
enforce-gtid-consistency
```
重启数据库生效
```bash
service mysql restart
```
- **Slave**
```bash
vi /mysql/my.cnf
```
添加如下内容
```bash
server-id=7
log-bin=/mysql/data/binlog
relay-log=/mysql/data/relaylog
gtid-mode=on
log-slave-updates=1
enforce-gtid-consistency
skip-slave-start
```
重启数据库生效
```bash
service mysql restart
```

**配置主从数据同步**

第一步：在 master 服务器中创建一个 slave 同步账号

```sql
mysql> create user 'slave'@'%' identified by '123456Aa.';
mysql> grant replication slave on *.* to 'slave'@'%';
mysql> flush privileges;
```
第二步：在 slave 中配置主从数据同步

```sql
mysql> change master to master_host='192.168.1.6',master_port=3306,master_user='slave',master_password='123456Aa.',master_auto_position=1;
mysql> start slave;
mysql> show slave status\G
```
查看到两个 yes，主从复制成功。否则，查看显示最下面信息，通过 error 信息进行排查问题。
```sql
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```
Master 创建一个测试数据库

```sql
mysql> create database test_db;
```
Slave 查看是否同步创建

```sql
mysql> show databases;
```

### 2、JDK 安装
因为 Mycat 是由 java 语言开发，必须使用 java 的运行环境才能进行启动和操作

**① 下载安装 jdk**

下载页面：<https://www.oracle.com/java/technologies/downloads/#java8>

下载完后上传至服务器，解压至 `/opt` 目录
```shell
tar -zxvf jdk-8u311-linux-x64.tar.gz -C /opt/
```

**② 配置环境变量**

```shell
echo 'PATH=/opt/jdk1.8.0_311/bin/:$PATH' >> ~/.bashrc
```
```bash
source ~/.bashrc
```
检测 java 环境变量，如果看到版本信息即为成功 
```bash
java -version
```

### 3、Mycat 安装

**① 解压安装 Mycat**

```shell
wget http://dl.mycat.org.cn/1.6.7.4/Mycat-server-1.6.7.4-release/Mycat-server-1.6.7.4-release-20200105164103-linux.tar.gz
```
```bash
tar -zxvf Mycat-server-1.6.7.4-release-20200105164103-linux.tar.gz -C /opt/
```

```bash
echo 'PATH=/opt/mycat/bin:$PATH' >> ~/.bashrc
```
```bash
source ~/.bashrc
```

**② 启动 Mycat**

```bash
[root@localhost ~]# mycat console
Running Mycat-server...
wrapper  | --> Wrapper Started as Console
wrapper  | Launching a JVM...
jvm 1    | Wrapper (Version 3.2.3) http://wrapper.tanukisoftware.org
jvm 1    |   Copyright 1999-2006 Tanuki Software, Inc.  All Rights Reserved.
jvm 1    | 
jvm 1    | MyCAT Server startup successfully. see logs in logs/mycat.log
```

### 4、Mycat 配置读写分离

读写分离的配置文件：

| 文件名称   | 作用                                                 |
| ---------- | ---------------------------------------------------- |
| server.xml | 配置 mycat 的对外的用户、密码、映射数据库名称等信息    |
| schema.xml | 配置后端真实数据库的用户、密码、真实数据库名称等信息 |

**① 查看 server.xml**

默认 `server.xml` 可以不用修改，配置 mycat 对外的使用用户信息
![在这里插入图片描述](https://img-blog.csdnimg.cn/e72bb52042c94c869e806fffaf3f59f0.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_20,color_FFFFFF,t_70,g_se,x_16)
**② 修改 schema.xml**

- schema 标签里配置 name 的 server.xml 里的虚拟数据库名称
- dataNode 填写后面使用的 dataNode 名称
- dataNode 标签和 dataHost 指定配置使用
- dataHost 标签里配置 writeHost 和 readHost（密码，地址，用户名称）

精简过的配置文件，注意修改后端真实数据库的名称 `test_db`
```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
    <!-- 1、TESTDB 和 server.xml 配置文件中的映射的数据库名称要一致，dataNone 填写下面的 dataNode 名称 -->
	<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1"></schema>
	<!-- 2、dataNode name和上面的一致  dataHost填写下面的dataHost的name名称  database填写后端真实数据库名称-->
    <dataNode name="dn1" dataHost="localhost1" database="test_db" />
    <!-- 3、可以配置负载均衡、读写分离算法   暂时可以不用动-->
	<dataHost name="localhost1" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
        <!-- 对后端数据库服务器 发送的心跳检测 -->
		<heartbeat>select user()</heartbeat>
		<!-- can have multi write hosts -->
        <!-- 4、配置后端真实数据库的相关登录信息 -->
		<writeHost host="hostM1" url="192.168.1.6:3306" user="root" password="123456Aa.">
			<!-- can have multi read hosts -->
			<readHost host="hostS2" url="192.168.1.7:3306" user="root" password="123456Aa." />
		</writeHost>
	</dataHost>
</mycat:schema>
```
**③ 启动 mycat 服务**

```shell
mycat start
```

确认 mycat 是否真的启动，查看它的端口 9066、8066

```bash
netstat -anpt|grep 9066
netstat -anpt|grep 8066
```

### 5、Mycat 客户端

连接 Mycat 客户端

```bash
yum install -y mysql
```

```bash
mysql -h127.0.0.1 -uroot -p123456 -P8066
```

创建一个表，查看结果

```sql
MySQL [TESTDB]> show databases;
MySQL [TESTDB]> use TESTDB;
MySQL [TESTDB]> create table table_test (id int, name varchar(255), age int(255));
```

### 6、Mycat 管理端

连接 mycat 管理端

```shell
mysql -h127.0.0.1 -uroot -p123456 -P9066
```

执行管理命令查看

```sql
MySQL [(none)]>  show @@heartbeat; 
+--------+-------+-------------+------+---------+-------+--------+---------+--------------+---------------------+-------+
| NAME   | TYPE  | HOST        | PORT | RS_CODE | RETRY | STATUS | TIMEOUT | EXECUTE_TIME | LAST_ACTIVE_TIME    | STOP  |
+--------+-------+-------------+------+---------+-------+--------+---------+--------------+---------------------+-------+
| hostM1 | mysql | 192.168.1.6 | 3306 |       1 |     0 | idle   |   30000 | 1,0,1        | 2021-11-29 17:49:39 | false |
| hostS2 | mysql | 192.168.1.7 | 3306 |       1 |     0 | idle   |   30000 | 0,0,1        | 2021-11-29 17:49:39 | false |
+--------+-------+-------------+------+---------+-------+--------+---------+--------------+---------------------+-------+
2 rows in set (0.00 sec)
```

