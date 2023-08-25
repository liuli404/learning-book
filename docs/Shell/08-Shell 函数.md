# 一、函数的定义

​	函数（function）表示某一种对应关系，即每个输入值都对应一个唯一的输出值。在一个函数定义中，包含某个函数所有输入值的集合，该集合被称作这个函数的定义域，而包含所有输出值的集合称作值域。

​	shell 函数是由一组命令集或语句形成的一个可用的代码块，他是用于完成特定任务的"黑盒子"。对于一个需要执行次数多但只需要少量代码的程序，可以考虑使用函数来完成

​	在函数中，标题即为函数名，二函数体则为函数内的命令集合。在函数中，标题名应该是唯一存在的，否则会造成运行结果混淆。函数的基本格式如下：

```bash
函数名 (){
	命令1
	命令2
	命令3
}
```

​	或者使用 function 关键字创建函数

```bash
function 函数名 (){
	命令1
	命令2
	命令3
}
```

​	用户也可以把函数看作是 shell 脚本程序中的一段代码块，只不过函数在执行时，会保留当前 shell 的相关内容。此外如果执行或调用一个脚本文件的一段代码时，改代码将在一个单独的子 shell 中运行。

​	可以将多个不同功能的函数放在同一个文件中，作为一段代码，也可以将每个函数放在单独的文件中。函数不比包含很多语句或命令，一个简单的函数有时甚至只包含一个 echo 命令。

```bash
#!/bin/bash

hello (){
	echo "hello linux~"
	echo "hello world"
}

hello

exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
hello linux~
hello world
```

​	在使用函数前必须要先定义，在一个程序中，可将函数放在程序的开始处。

​	调用函数时，直接使用函数名即可，如上面例子中的 hello 函数。

​	也可以在一个函数中嵌套另一个函数，例子如下：

```bash
#!/bin/bash

funky (){
    funky2 (){
        echo "Funky2 in Funky1"
    }
}

funky
funky2

exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
Funky2 in Funky1
```

# 二、函数的调用

​	程序对函数的调用可以分为两种形式：一种是在脚本内部定义并调用函数，另一种是一个脚本调用其他脚本中定义的函数。

## 2.1 在脚本中调用

​	要实现在脚本中调用函数，需要在调用前创建该函数，否则会调用失败。

```bash
#!/bin/bash

is_a_file (){
    FILE_NAME=$1
    echo "the file exists"
    
    if [ ! -f $FILE_NAME ]
    then
        return 1
    else
    	return 0
    fi
    
    error_mesg (){
    	echo -e "\007"
    	echo $@
    	echo -e "\007"
    	return 0
    }
    
    touch_file (){
    	touch $FILE_NAME
    }
}

for files in *
do
	echo -n "Enter the file name: "
	read DIREC
	if [ -f $DIREC ]
	then
		echo "check files..."
		sleep 1
		break 2
	else
		touch file2
		echo "Create file,Please wait..."
		sleep 1
		echo "Finish,New file name is file2"
	fi
done

if [ $? != 0 ]
then
	error_msg
	exit 1
fi

is_a_file
exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
Enter the file name: test.sh
check files...
the file exists
[root@192 ~]# bash test.sh 
Enter the file name: 123.txt
Create file,Please wait...
Finish,New file name is file2
the file exists
[root@192 ~]# 
[root@192 ~]# ls
file2  test.sh
```

## 2.2 调用脚本文件

​	通过调用其他脚本中的函数，可以实现函数的复用。我们先创建一个函数脚本 func.sh，定义函数

```bash
#!/bin/bash

func_1 (){
        echo "hello [func1] "
}

func_2 (){
        echo "hello [func2] "
}
```

​	编写另一个脚本 main.sh，实现对上一个脚本函数的调用。在脚本程序中，要调用的函数位于脚本的开始处。

```bash
#!/bin/bash
# 使用 source 或 . 的方式引入函数文件
source /root/func.sh
#. /root/func.sh

func_1
```

​	运行结果

```bash
[root@192 ~]# bash main.sh 
hello [func1] 
```

# 三、函数参数传递

## 3.1 位置参数

​	函数可以根据位置的引用自动处理传递过来的参数，这些参数为位置函数。

```bash
#!/bin/bash

funWithParam(){
    echo "第一个参数为 $1 !"
    echo "第二个参数为 $2 !"
    echo "第十个参数为 $10 !"
    echo "第十个参数为 ${10} !"
    echo "第十一个参数为 ${11} !"
    echo "参数总数有 $# 个!"
    echo "作为一个字符串输出所有参数 $* !"
}
funWithParam 1 2 3 4 5 6 7 8 9 34 73
```

​	运行结果，注意，$10 不能获取第十个参数，获取第十个参数需要 ${10}。当 n>=10 时，需要使用${n}来获取参数。

```bash
[root@192 ~]# bash test.sh 
第一个参数为 1 !
第二个参数为 2 !
第十个参数为 10 !
第十个参数为 34 !
第十一个参数为 73 !
参数总数有 11 个!
作为一个字符串输出所有参数 1 2 3 4 5 6 7 8 9 34 73 !
```

​	特殊的参数

| 参数处理 | 说明                                                         |
| :------- | :----------------------------------------------------------- |
| $#       | 传递到脚本或函数的参数个数                                   |
| $*       | 以一个单字符串显示所有向脚本传递的参数                       |
| $$       | 脚本运行的当前进程ID号                                       |
| $!       | 后台运行的最后一个进程的ID号                                 |
| $@       | 与$*相同，但是使用时加引号，并在引号中返回每个参数。         |
| $-       | 显示Shell使用的当前选项，与set命令功能相同。                 |
| $?       | 显示最后命令的退出状态。0表示没有错误，其他任何值表明有错误。 |

## 3.2 间接变量引用

​	一般 shell 脚本只是将值传递给函数。若将变量名作为参数传递给函数，就会被看成是字符串。如果想实现将变量赋值给变量或函数，需要使用间接变量引用方式。该方式是将变量的指针传递给函数的笨拙机制。如下示例：

```bash
#!/bin/bash

echo_str (){
	echo $1
}

var1="var2"
var2="hello linux"

echo_str "$var1"
echo_str "${!var1}"

# 重新赋值
var2="HELLO LINUX"
echo_str "$var1"
echo_str "${!var1}"
```

​	运行结果，发现没有使用间接引用方式的直接将变量名当作字符串输出了。而使用了间接引用方式的，会去寻找变量名对应的变量值。

```bash
[root@192 ~]# bash test.sh 
var2
hello linux
var2
HELLO LINUX
```

​	如下，我想用 for 循环 ping A、B、C 三台主机的 IP，如果直接通过变量赋值给变量的方式，会出现什么结果呢？

```bash
#!/bin/bash
hostA=10.10.0.11
hostB=10.10.0.12
hostC=10.10.0.13

for i in A B C
do
	hostIP=host$i
	echo $hostIP
	ping -c 1 $hostIP
done
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
hostA
ping: hostA: Name or service not known
hostB
ping: hostB: Name or service not known
hostC
ping: hostC: Name or service not known
```

​	可以看到虽然通过 for 循环的方式将变量名 hostA、hostB、hostC 拼接出来了，但是赋值时也只是将变量名赋值给了 hostIP，并没有将对应的值传递过去。修改脚本

```bash
#!/bin/bash
hostA=10.10.0.11
hostB=10.10.0.12
hostC=10.10.0.13

for i in A B C
do
	hostIP=host$i
	echo ${!hostIP}
	ping -c 1 ${!hostIP}
done
```

​	运行结果，可以看到已经实现的间接引用，将 IP 赋值给 hostIP 了

```bash
[root@192 ~]# bash test.sh 
10.10.0.11
PING 10.10.0.11 (10.10.0.11) 56(84) bytes of data.
10.10.0.12
PING 10.10.0.12 (10.10.0.12) 56(84) bytes of data.
10.10.0.13
PING 10.10.0.13 (10.10.0.13) 56(84) bytes of data.
```

# 四、函数返回与退出

​	函数的返回值是一个成为退出状态（exit status）的值，即状态值。可以使用 return 来指定声明，否则函数的退出状态值即是函数最后一个执行命令的退出状态值。

​	一般情况下，函数返回的最大值只能为 255。若想返回的值大于 255，那么就只能通过直接将返回值传递到一个全局变量，并使用变量来直接返回这个大于 255 的值。

```bash
#!/bin/bash

RETURN (){
	fvar=$1
	return
}

RETURN 1
echo "value1=$fvar"
RETURN 256
echo "value2=$fvar"
RETURN -256
echo "value3=$fvar"
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
value1=1
value2=256
value3=-256
```

# 五、函数输入重定向

​	从本质上来说，函数其实是一个代码块，可以就意味着可以对函数的输入进行重定向。

​	可以使用函数标准输入方法，从脚本编程上理解重定向操作。在函数内的代码块中包含标准输入重定向命令。在代码块中定义的格式一般有三种

```bash
# 第一种
func (){
	.....
} < file

# 第二种
func (){
	{
	...
	}
	
} < file
# 第三种
func (){
	{
		echo $*
	}
}
```

​	例如接下来要使用重定向方式读取 passwd 文件的内容

```bash
#!/bin/bash

file_path=/etc/passwd

file_index (){
	while read line
	do
		echo $line
	done
} < $file_path

file_index
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/spool/mail:/sbin/nologin
operator:x:11:0:operator:/root:/sbin/nologin
games:x:12:100:games:/usr/games:/sbin/nologin
ftp:x:14:50:FTP User:/var/ftp:/sbin/nologin
nobody:x:99:99:Nobody:/:/sbin/nologin
systemd-network:x:192:192:systemd Network Management:/:/sbin/nologin
dbus:x:81:81:System message bus:/:/sbin/nologin
polkitd:x:999:998:User for polkitd:/:/sbin/nologin
sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
postfix:x:89:89::/var/spool/postfix:/sbin/nologin
chrony:x:998:996::/var/lib/chrony:/sbin/nologin
```

# 