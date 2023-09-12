# 一、文件命名规则

## 1.1 可以使用哪些字符

理论上**除了字符“/”之外，所有的字符都可以使用**，但是要注意，在目录名或文件名中，不建议使用某些特殊字符，例如， <、>、？、* 等，尽量避免使用。

工作时文件的命名规则：

① 由于 Linux 严格区分大小写，所以**尽量都用小写字母**

② 如果必须**对文件名进行分割，建议使用"_"**，例如：nginx_error_2020.log

> _ 下划线，在 Linux 操作系统中，可以使用 Shift 键 + 减号 

## 1.2 文件名的长度

目录名或文件名的长度不能超过 255 个字符

> 尽量不要太长，另外文件名称一定要见名知意，可以使用英文单词 

## 1.3 文件名的大小写

Linux 目录名或文件名是区分大小写的。如 yunwei 和 Yunwei ，是互不相同的目录名或文件名。

个人建议：

不要使用字符大小写来区分不同的文件或目录。
建议文件名**一律使用小写字母**

## 1.4 Linux 文件扩展名

 Linux 文件的扩展名对  Linux  操作系统没有特殊的含义， Linux  系统并不以文件的扩展名开分区文件类型。例如，liuli.exe 只是一个文件，其扩展名 .exe 并不代表此文件就一定是可执行的。

在 Linux 系统中，文件扩展名的用途为了**使运维人员更好的区分不同的文件类型**。

>  在 Linux 操作系统中，文件的类型是依靠权限位的标识符来进行区分的。当然也可以通过颜色，如黑色普通文件，天蓝色文件夹 

# 二、文件管理

## 2.1 目录创建

### 2.1.1 创建目录

基本语法：`mkdir 目录名称`

主要功能：就是根据目录的名称创建一个目录

> mkdir = make directory 

```bash
# 在家目录下创建一个 liuli 的文件夹
mkdir liuli
```

### 2.1.2 递归创建目录

基本语法：`mkdir -p 多级目录`

选项说明：

- -p：递归创建，从左边的路径开始一级一级创建目录，直到路径结束



```bash
# 在已知目录（/usr/local）下创建多级目录（nginx/conf）
mkdir -p /usr/local/nginx/conf
```

### 2.1.3 同时创建多个目录

基本语法：`mkdir 目录名称1 目录名称2 目录名称3 ...`

```bash
# 在当前目录下创建a、b、c三个目录
mkdir a
mkdir b
mkdir c
# 或
mkdir a b c
```

## 2.2 目录删除

### 2.2.1 移除空目录

基本语法：`rmdir 目录名称`

> rmdir = remove  directory，移除目录 

```bash
# 把家目录下的 liuli 删除（空目录）
rmdir liuli
```

### 2.2.2 递归删除空目录

基本语法：`rmdir -p 目录名称1/目录名称2/目录名称3/...`

主要功能：从右向左一级一级删除空目录

```bash
# 递归删除 liuli 文件夹中的 yunwei 文件夹中的 shenzhen3
rmdir -p liuli/yunwei/shenzhen3
```

### 2.2.3 同时删除多个空目录

基本语法：`rmdir 目录名称1 目录名称2 目录名称3 ...`

```bash
# 删除家目录中的a、b、c三个空目录
rmdir a b c
```

## 2.3 文件创建

### 2.3.1 创建文件

基本语法：`touch 文件名称`

主要功能：在 Linux 系统中的当前目录下创建一个空文件

```bash
# 在当前目录下创建一个 readme.txt 文件
touch readme.txt
```

### 2.3.2 同时创建多个文件

基本语法：`touch 文件名称1 文件名称2 文件名称3 ...`

```bash
# 创建一个 shop 商城文件夹，然后在内部创建 index.php、admin.php、config.php 三个文件
mkdir shop
touch shop/index.php
touch shop/admin.php
touch shop/config.php
# 或
touch shop/index.php shop/admin.php shop/config.php
```

### 2.3.3 根据序号同时创建多个文件

基本语法：`touch 文件名称{开始序号..结束序号}`

主要功能：根据提供的开始序号~结束序号，一个一个创建文件

```bash
# 创建 file1、file2、file3、file4、file5 共 5 个文件
touch file1
touch file2
touch file3
touch file4
touch file5
# 或
touch file{1..5}
```

## 2.4 文件删除

基本语法：`rm [选项] 文件或文件夹的名称`

选项说明：

- -r：针对文件夹，代表递归删除，先把目录下的所有文件删除，然后在删除文件夹
- -f：强制删除，不提示，初学者一定要慎重！！！

```bash
# 删除 readme.txt 文件
rm readme.txt
# rm: remove regular empty file ‘readme.txt’? 这里可以回复y or n
# y 代表确认删除
# n 代表取消删除
```

```bash
# 强制删除 admin.php，不提示（慎重）
rm -f admin.php
```

```bash
# 删除非空的文件夹（-rf 强制递归删除，不提示）
rm -rf shop
```

```bash
rm -rf /*   # 代表删除根目录下的所有文件（如果没有备份，恢复的几率不高）
# rm ：删除
# -r ：递归删除（无论文件夹是否为空）
# -f ：强制删除不提示
# /  ：代表根分区
# *  ：所有
```

## 2.5 复制操作

### 2.5.1 复制

基本语法：cp [选项] 源文件或文件夹 目标路径

选项说明：

- -r ：递归复制，主要针对文件夹

>  cp = copy复制 

```bash
# 把 readme.txt 文件从当前目录复制一份放到 /tmp 文件夹中
cp readme.txt /tmp/
```

### 2.5.2 复制并重命名文件

基本语法：`cp [选项] 源文件或文件夹 目标路径/新文件或文件夹的名称`

```bash
# 把 readme.txt 文件从当前目录复制一份放到 /tmp 文件夹中并重命名为 readme.txt.bak
cp readme.txt /tmp/readme.txt.bak
```

### 2.5.3 复制文件夹到指定路径

基本语法：`cp -r 源文件夹名称 目标路径/`

```bash
# 把 shop 目录连通其内部的文件统一复制到 /tmp 目录下
mkdir shop
touch shop/index.php shop/admin.php shop/config.php
cp -r shop /tmp/
```

## 2.6 剪切操作

基本语法：`mv 源文件或文件夹 目标路径`

>  mv = move，剪切、移动的含义 

```bash
# 把 readme.txt 文件剪切到 /tmp 目录下
mv readme.txt /tmp/
```

```bash
# 把 shop 文件夹移动到 /usr/local/nginx 目录下
mkdir /usr/local/nginx
mv shop /usr/local/nginx/
```

## 2.7 重命名操作

什么是重命名？简单来说，就是给一个文件或文件夹更改名称

基本语法：`mv 源文件或文件夹名称 新文件或文件夹的名称`

```bash
# 把 readme.txt 文件更名为 README.md 文件
mv readme.txt README.md
```

```bash
# 把 shop 文件目录更名为 wechat 目录
mkdir shop
mv shop wechat
```

## 2.8 打包、压缩与解压缩

### 2.8.1 几个概念

**打包**：默认情况下， Linux 的压缩概念一次只能压缩一个文件。针对多文件或文件夹无法进行直接压缩。所以需要提前对多个文件或文件夹进行打包，这样才可以进行压缩操作。

>  打包只是把多个文件或文件夹打包放在一个文件中，但是并没有进行压缩，所以其大小还是原来所有文件的总和。 

**压缩**：也是一个文件和目录的集合，且这个集合也被存储在一个文件中，但它们的不同之处在于，压缩文件所占用的磁盘空间**比集合中所有文件大小的总和要小。**

### 2.8.2 打包操作

基本语法：`tar [选项] 打包后的名称.tar 多个文件或文件夹`

选项说明：

- -c：打包
- -f：filename，打包后的文件名称
- -v：显示打包的进度
- -u：update缩写，更新原打包文件中的文件（了解）
- -t：查看打包的文件内容（了解）

```bash
# 把 a.txt、b.txt、c.txt 文件打包到 abc.tar 文件中
tar -cvf abc.tar a.txt b.txt c.txt
```

```bash
# 把 wechat 文件夹进行打包 wechat.tar
tar -cvf wechat.tar wechat
```

### 2.8.3 tar -tf 以及 tar -uf

基本语法：`tar -tf 打包后的文件名称`

主要功能：查看 tar 包中的文件信息

```bash
# 查看 abc.tar 包中的文件信息
tar -tf abc.tar
```

```bash
# 如果还想往 tar 包中更新或追加内容都可以通过-u选项
tar -uf 打包后的文件名称
```

>  u = update 

```bash
# 向 abc.tar 包中添加一个 d.txt 文件
touch d.txt
tar -uf abc.tar d.txt
# 查看是否添加成功
tar -tf abc.tar
```

扩展：如何把tar包中的文件释放出来

```bash
# 打包
tar -cf abc.tar a.txt b.txt c.txt

# 释放
tar -xf abc.tar
```

### 2.8.4 打包并压缩

基本语法：`tar [选项] 压缩后的压缩包名称 要压缩的文件或文件夹`

选项说明：

- -cf：对文件或文件夹进行打包
- -v：显示压缩进度
- -z：使用gzip压缩工具把打包后的文件压缩为.gz
- -j：使用bzip2压缩工具把打包后的文件压缩为.bz2
- -J：使用xz压缩工具把打包后的文件压缩为.xz

```bash
# 把 a.txt、b.txt、c.txt 文件打包并压缩为 abc.tar.gz
tar -zcf abc.tar.gz a.txt b.txt c.txt
```

```bash
# 把 wechat 文件夹压缩为 wechat.tar.gz 格式的压缩包
tar -zcf wechat.tar.gz wechat
```

### 2.8.5 对压缩包进行解压

解压过程非常简单，就是把压缩的参数中的 c 换成 x 就可以实现解压缩了

```bash
# *.tar.gz 格式的压缩包
tar -zxf 名称.tar.gz

# *.tar.bz2 格式的压缩包
tar -jxf 名称.tar.bz2

# *.tar.xz 格式的压缩包
tar -Jxf 名称.tar.xz
```

```bash
# 把 abc.tar.gz 格式的压缩包进行解压缩操作
tar -zxf abc.tar.gz
```

```bash
# 把 wechat.tar.gz 格式的压缩包进行解压缩操作
tar -zxf wechat.tar.gz
```

## 2.9 zip 与 unzip

### 2.9.1 zip 压缩

基本语法：`zip [选项] 压缩后的文件名称.zip 文件或文件夹`

选项说明：

- -r ：递归压缩，主要针对的是文件夹

>   Linux 下已经有 gzip、bzip2 以及 xz 压缩命令了，为什么还需要使用 zip 压缩呢？ 

>  答：zip 格式在 Windows 以及 Linux 中都是可以正常使用的。 

```bash
# 把 a.txt、b.txt、c.txt 进行压缩为 abc.zip
zip abc.zip a.txt b.txt c.txt
```

```bash
# 把 wechat 文件夹压缩为 wechat.zip
zip -r wechat.zip wechat
```

### 2.9.2 unzip 解压缩

基本语法：`unzip 压缩包名称`,`unzip 压缩包名称 -d 指定路径`

选项说明：

- -d：解压到指定路径下

```bash
# 对abc.zip文件进行解压缩
unzip abc.zip
```

```bash
# 把 wechat.zip 解压到 /usr/local/nginx 目录下
unzip wechat.zip -d /usr/local/nginx/
```

# 三、文本处理

## 3.1 查看文件内容

### 3.1.1 cat 查看及合并

命令：cat

作用：查看文件内容

基本语法：`cat 文件名称`， `cat 文件1 文件2 > 文件3`

```bash
# 用法一：cat 文件名
cat 1.txt
# 含义：显示 1.txt 文件的内容
# 特别注意：cat 命令用于查看文件内容时，不论文件内容有多少，都会一次性显示。如果文件非常大，那么文件开头的内容就看不到了。cat 命令适合查看不太大的文件。

# 用法二：cat 文件1 文件2 > 文件3
cat 1.txt 2.txt > 3.txt
# 含义：将 1.txt 和 2.txt 文件内容合并后，输出到 3.txt
```

### 3.1.2 more 分屏显示文件

命令：more

作用：分屏查看文件

基本语法：`more 文件名`

基本语法：more 在读取文件时，默认已经加载文件的全部内容。

```bash
more /var/log/boot.log
# 含义：分页显示 /var/log/boot.log 文件的内容
```

more 命令的执行会打开一个交互界面，下面是一些常用交互命令：

| 回车键   | 向下移动一行。               |
| -------- | ---------------------------- |
| d        | 向下移动半页。               |
| 空格键   | 向下移动一页。               |
| b        | 向上移动一页。               |
| / 字符串 | 搜索指定的字符串。           |
| :f       | 显示当前文件的文件名和行号。 |
| q 或 Q   | 退出   more。                |

### 3.1.3 less 分屏显示文件

命令：less

作用：分屏查看文件

基本语法：`less 文件名`

流程：不是加载整个文件，而是一点一点进行加载，相对而言，读取大文件时，效率比较高。

```bash
less /var/log/boot.log
# 含义：分页显示 /var/log/boot.log 文件的内容
```

less 命令的执行也会打开一个交互界面，下面是一些常用交互命令（和more相同）：

| 回车键   | 向下移动一行。               |
| -------- | ---------------------------- |
| d        | 向下移动半页。               |
| 空格键   | 向下移动一页。               |
| b        | 向上移动一页。               |
| / 字符串 | 搜索指定的字符串。           |
| :f       | 显示当前文件的文件名和行号。 |
| q 或 Q   | 退出   more。                |

### 3.1.4 三者的对比

|            | cat                    | more                   | less                   |
| ---------- | ---------------------- | ---------------------- | ---------------------- |
| 作用       | 显示小文件（一屏以内） | 显示大文件（超过一屏） | 显示大文件（超过一屏） |
| 交互命令   | 无                     | 有                     | 有                     |
| 上下键翻行 | 无                     | 无                     | 有                     |

### 3.1.5 head 显示文件开头行

命令：head

作用：查看一个文件的前 n 行，如果不指定 n，则默认显示前 10 行。

基本语法：`head [参数选项] 文件名`

常见参数：-n 表示显示前 n 行的内容，n 等于行数

```bash
# 用法一：head 文件名
head /var/log/boot.log
# 含义：显示 /var/log/boot.log 文件的内容，默认为前 10 行

# 用法二：head -n 文件名
head -3 /var/log/boot.log
# 含义：显示 /var/log/boot.log 文件的前 3 行内容
```

### 3.1.6 tail 显示文件结尾行

命令：tail

作用：查看一个文件的最后n 行，如果n 不指定默认显示最后10 行

基本语法：`tail -n 文件路径`【n 表示数字】

常见参数：

- -n：显示最后 n 行的内容，n 等于行数
- -f：输出文件变化后新增加的数据

```bash
# 用法一：tail 文件名
tail /var/log/boot.log
含义：显示 /var/log/boot.log 文件的内容，默认为最后 10 行

# 用法二：tail -n 文件名
tail -5 /var/log/boot.log
含义：显示 /var/log/boot.log 文件的最后 5 行内容

# 用法三：tail -f 文件名
tail -f /var/log/messages
含义：显示 /var/log/messages 文件中，执行 tail -f 命令后，新增的数据。
注意：作用相当于查看一个文件动态变化的内容，一般用于查看系统的日志的变化，按下 ctrl+c 可以退出查看状态
```

## 3.2 统计文本信息

### 3.2.1 wc 统计文件内容数量

命令：wc（wc = word count）

作用：用于统计文件内容信息（包含行数、单词数、字节数）

基本语法：`wc [参数选项] 文件名`

常见参数：

- -l：表示 lines，行数（以回车/换行符为标准）

- -w：表示 words，单词数 依照空格来判断单词数量

- -c：表示 bytes，字节数（空格，回车，换行）

```bash
wc -lwc /var/log/boot.log
# 含义：统计 /var/log/boot.log 文件的行数，单词数，字节数
# 注意：wc命令选项可以混在一起搭配使用，但选项的顺序不影响输出结果，第一个是行数，第二个是单词数，第三个数字节数。
```

### 3.2.2 du 统计文件大小

命令：du

作用：查看文件或目录（会递归显示子目录）占用磁盘空间大小

基本语法：`du [参数选项] 文件名或目录名`

常见参数：

- -s ：summaries，只显示汇总的大小，统计文件夹的大小

- -h：human，表示以人类高可读性的形式进行显示，如果不写 -h，默认以 KB 的形式显示文件大小

```bash
# 用法一：du 文件名
du /var/log/boot.log
# 含义：统计 /var/log/boot.log 文件的大小

# 用法二：du -h 文件名
du -h /var/log/boot.log
# 含义：统计 /var/log/boot.log 文件的大小，以高可读性显示

# 用法三：du 目录名
du /var/log/
# 含义：统计 /var/log/ 目录的大小，包含目录下每一个单独文件的大小

# 用法四：du -s 目录名
du -s /var/log/
# 含义：统计/var/log/boot.log文件的大小，汇总只显示目录大小

# 用法五：du -sh 目录名
du -sh /var/log/
# 含义：统计 /var/log/boot.log 文件的大小，汇总只显示目录大小，并采用高可读性
```

## 3.3 文本处理

### 3.3.1 find 文件查找 

命令：find

作用：用于查找文档

基本语法：`find 路径范围 选项1 选项1的值 [选项2 选项2的值…]`

常用参数：

- -name：按照文档名称进行搜索（支持模糊搜索）

- -type：按照文档的类型进行搜索，文档类型的值，f（file）表示文件，d（directory）表示文件夹

```bash
# 用法一：find 路径范围 选项1 选项1的值 选项2 选项2的值
find /var/ -name boot.log -type f
# 含义：在 /var/ 目录下，查找名称等于 boot.log，类型是文件的文档

# 用法二：find 路径范围 选项1 选项1的值 选项2 选项2的值
find /var/log -name "*.log" -type f
# 含义：在 /var/log 目录下，查找所有 .log 结尾，类型是文件的文档，*.log 需要用引号引起来。

# 用法三：find 路径范围 选项1 选项1的值
find /var/log -type d
# 含义：在 /var/log 目录下，查找所有文件夹
```

### 3.3.2 grep 搜索文件内容

命令：grep

作用：在文件中直接找到包含指定信息的那些行，并把这些信息显示出来

基本语法：`grep 要查找的内容 文件名`

```bash
# 用法一：grep 查找的内容 文件名
grep network boot.log
# 含义：在 boot.log 文件中，查找包含 network 的行

# 用法二：grep 查找的内容 多个文件
grep network /var/log/*
# 含义：在 /var/log 目录下的所有文件中，查找包含 network 的行
```

