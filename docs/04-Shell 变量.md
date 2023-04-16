# 一、变量概述

​	变量是一段有名字的连续存储空间，是程序中数据的临时存放场所。一般在代码中是通过定义变量来申请并命名这样的存储空间，并通过索定义的变量名来使用多个变量。

​	变量中所存储的被定义的数据，被称为变量值，他们一般是暂时存在的。shell 中的变量是没有整型、浮点型变量区分的，若要指定变量形态，可以使用 declare 指令。

​	在 shell 中的变量值，只对当前的 shell 有效。也就是说在当前 shell 中所定义的变量，不能在其他的 shell 中找到并使用。

​	当然，在系统中也有已定义的变量存在，这些变量为用户提供一个初始化的工作环境，而用户则可根据实际需求改变变量值，并保存在指定的变量中。

# 二、变量的类型

​	在 Linux 系统中，一般情况下有两种类型的变量，即环境变量和局部变量，但还有一种变量称为特殊变量，此变量以只读的形式存在。

## 2.1 局部变量

​	局部变量即存在生命周期的变量，局部变量只在局部进程中可见，若是 shell 中启动新的进程或是退出。则此变量值将不存在。

​	可以使用 set 命令查看当前系统中定义的局部变量

```bash
[root@192 ~]# set 
BASH=/bin/bash
BASHOPTS=checkwinsize:cmdhist:expand_aliases:extquote:force_fignore:histappend:hostcomplete:interactive_comments:login_shell:progcomp:promptvars:sourcepath
BASH_ALIASES=()
BASH_ARGC=()
BASH_ARGV=()
BASH_CMDS=()
BASH_LINENO=()
BASH_SOURCE=()
BASH_VERSINFO=([0]="4" [1]="2" [2]="46" [3]="2" [4]="release" [5]="x86_64-redhat-linux-gnu")
BASH_VERSION='4.2.46(2)-release'
COLUMNS=236
DIRSTACK=()
EUID=0
GROUPS=()
HISTCONTROL=ignoredups
HISTFILE=/root/.bash_history
HISTFILESIZE=1000
HISTSIZE=1000
HOME=/root
HOSTNAME=192.168.124.45
HOSTTYPE=x86_64
```

## 2.2 环境变量

​	在 Linux 中，通常使用环境变量存储会话和工作环境的信息。存储于环境变量中的数据，是一些永久性的数据，如系统配置信息，用户账号信息以及其他数据信息等。

​	使用 env 命令查看当前系统中的环境变量

```bash
[root@192 ~]# env
XDG_SESSION_ID=8
HOSTNAME=192.168.124.45
SELINUX_ROLE_REQUESTED=
TERM=xterm
SHELL=/bin/bash
HISTSIZE=1000
SSH_CLIENT=192.168.124.21 63719 22
SELINUX_USE_CURRENT_RANGE=
SSH_TTY=/dev/pts/0
USER=root
```

## 2.3 特殊变量

​	shell 脚本中经常出现一些特殊参数，如 $0、$1、$2。其中 $0 表示脚本文件名称，而 $1 表示第一个参数，$2 表示第二个参数。当参数超过十个就需要用 {} 括起来，如 ${10}。

​	还有两个特殊变量：$*、$@，他们表示所有的位置参数，实例如下

```bash
#!/bin/bash

echo "The name of this script is $0"
echo 

if [ -n $1 ]
then
	echo "The first parameter is $1."
fi

if [ -n $2 ]
then
	echo "The first parameter is $2."
fi

if [ -n $3 ]
then
	echo "The first parameter is $3."
fi

echo
echo "All the command_line parameters arg is "$*"."

exit 0
```

执行结果

```bash
[root@192 ~]# bash test.sh a b c d e f g
The name of this script is test.sh

The first parameter is a.
The first parameter is b.
The first parameter is c.

All the command_line parameters arg is a b c d e f g.
```

# 三、系统内置变量

​	在 bash 中默认定义了许多内置变量，这些内置变量的设置使用，直接影响到 bash 脚本的行为。以下列举一些常用的内置变量：

1. $HISTFILE，记录历史命令文件的路径

```bash
[root@192 ~]# echo $HISTFILE
/root/.bash_history
```

2. $HISTFILESIZE，记录历史命令的行数

```bash
[root@192 ~]# echo $HISTFILESIZE
1000
```

3. $HOSTNAME，当前主机名

```bash
[root@192 ~]# echo $HOSTNAME
192.168.124.45
```

4. $HOME，当前用户的家目录

```bash
[root@192 ~]# echo $HOME
/root
```

5. $HOSTTYPE，当前主机的类型

```bash
[root@192 ~]# echo $HOSTTYPE
x86_64
```

6. $LANG，当前系统的语言类型

```bash
[root@192 ~]# echo $LANG
en_US.UTF-8
```

7. $LOGNAME，当前登陆的用户名

```bash
[root@192 ~]# echo $LOGNAME
root
```

8. $LINENO，记录当前 shell 脚本中的行号

```bash
  1 #!/bin/bash
  2 
  3 echo "line number is $LINENO"
  4 echo "line number is $LINENO"
  5 
  6 exit 0
```

```bash
[root@192 ~]# bash 1.sh 
line number is 3
line number is 4
```

9. $PATH，定义外部命令的路径，为了安全起见，一般不把当前目录加到 PATH 中，且执行程序时，一般使用 ./ 的方式执行。

```bash
[root@192 ~]# echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
```

10. $PWD，当前的工作目录，与 pwd 命令效果一样

```bash
[root@192 ~]# echo $PWD
/root
[root@192 ~]# pwd
/root
```

11. $SECONDS，记录某个脚本的运行时间，单位为秒

```bash
 #!/bin/bash

time_limit=6
time_interval=1

while [ "$SECONDS" -le "$time_limit" ]
do
        if [ $SECONDS -lt 7 ]
        then
                second=1
                let seconds+=1
        fi
        echo "This script already running $seconds s"
        sleep $time_interval
done

echo "Total spends time $SECONDS s"
exit 0
```

12. $RANDOM，随机输出一个随机数

```BASH
[root@192 ~]# echo $RANDOM
4479
[root@192 ~]# echo $RANDOM
11519
```



# 四、变量的设置

​	在 Linux 系统中，变量值按变量的生存周期来划分，可以分为两类，即永久变量和临时变量。若需要定义永久变量，则应该修改配置文件，以使变量永久生效；而临时变量，可以使用 export 命令声明，所声明的临时变量在关闭 shell 时失效。

## 4.1 在 /etc/profile 文件中定义

​	在 `/etc/profile` 文件中定义变量，对 Linux 下的所有用户都有效，并且是永久性存在的变量。

```bash
[root@192 ~]# echo "export JAVA_PATH=/opt/java/bin" >> /etc/profile
```

​	在添加了变量后，不会立即生效，需要重启系统后或刷新环境变量才会生效

```bash
[root@192 ~]# echo $JAVA_PATH

[root@192 ~]# source /etc/profile
[root@192 ~]# echo $JAVA_PATH
/opt/java/bin
```

## 4.2 在 ~/.bash_profile 文件中定义

​	在 `~/.bash_profile` 中定义的变量只对单用户生效，也就是修改了哪个用户家目录下的文件，则只对这个用户生效。由于该文件引用 `~/.bashrc` 文件，所以修改 `~/.bashrc` 文件达到的效果一致。

```bash
[root@192 ~]# echo "NODE_HOME=/opt/node/bin" >> ~/.bash_profile 
```

​	同样需要刷新文件生效

```bash
[root@192 ~]# echo $NODE_HOME

[root@192 ~]# source ~/.bash_profile 
[root@192 ~]# echo $NODE_HOME
/opt/node/bin
```

## 4.3 使用 export 命令定义

​	使用 export 设置的变量只对当前 shell 终端生效，为临时变量。

```bash
[root@192 ~]# export myname=jack
[root@192 ~]# echo $myname
jack
```

# 五、变量应用

## 5.1 变量的赋值

​	对于变量的赋值，可以用 "=" 号来实现，需要注意的是 "=" 两边不可以有空格，更不能与 -eq 来混合使用。

​	变量的赋值方式可以直接使用 "=" 赋值，也可以搭配 let 赋值。

```bash
#!/bin/bash

var1=3
echo "The value of var1 is $var1"
echo

let var2=2+2
echo "The value of var2 is $var2"
echo

for var3 in {7..9}
do
	echo "The value of var3 is $var3"
	echo
done

exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
The value of var1 is 3

The value of var2 is 4

The value of var3 is 7

The value of var3 is 8

The value of var3 is 9
```

​	如果是定义字符串字符，最好使用引号将变量值引起来

```bash
[root@192 ~]# h="hello linux"
[root@192 ~]# echo $h
hello linux
[root@192 ~]# h='hello linux'
[root@192 ~]# echo $h
hello linux
```

## 5.2 变量引用与转义

​	使用双引号来引用变量表达式，可以防止所引用的变量被分割，这些双引号内的变量会被系统作为一个参数进行传递。

```bash
#!/bin/bash

var1="The first variable"
echo $var1

var2="The second variable"
echo $var2

var3="The        third variable"
echo $var3

echo $var2 $var3
echo "$var2 $var3"

exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
The first variable
The second variable
The third variable
The second variable The third variable
The second variable The        third variable
```

​	转义是指在 shell 中，有一些字符，在前面加上反斜杠 \ 后，便具有了特殊意义。如字符 n，加上反斜杠后就表示换行。其中 \n 被成为转义序列，\ 被称为转义字符。使用 -e 可以打印转义字符。

| 转义序列 | 相关说明                               |
| -------- | -------------------------------------- |
| \a       | 表示蜂鸣，操作出现某种错误时会提示响声 |
| \b       | 删除                                   |
| \r       | 回车                                   |
| \n       | 换行                                   |
| \t       | tab 制表符                             |
| \v       | 垂直 tab                               |
| \0xx     | 转换成 8 进制 ASCLL码                  |

```bash
#!/bin/bash

echo "Vertical list:"
echo -e "\v\v\v"

echo -e "\042"

echo "new line and beep"
echo -e "\n"
echo -e "\a"

exit 0
```

