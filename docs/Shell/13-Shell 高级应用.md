# 一、子 shell 概念及应用

## 1.1 子 shell 简介

​	在运行的 shell 中再启动另外一个 shell，他们之间的关系类似于父子关系，这个 shell 就交子 shell。

​	每个子 shell 都能有效的运行在其父 shell 的一个子进程里，也可以再启动属于自己的子 shell。脚本执行效率高，是因为这些被开启的子 shell 可同时执行多个子任务且能做串行处理。

​	开启子 shell 的方法，可以使用圆括号，子 shell 所要执行的任务，在圆括号中，用分号将命令隔开。

```bash
( command1;command2;command3 )
```

​	需要注意的是，子 shell 中的变量是不能被外面的 shell 引用的，相当于局部变量。

​	当然也可以在子 shell 中在开启一个子 shell。

```bash
#!/bin/bash

FILE=/etc/passwda
if [ -f $FILE ]
then
    echo "The file exists."
    (ls -l $FILE;exit)
else
	echo "No such file."
	(echo 'Creating the file...'
	(touch passwd;ls passwd;exit))
fi

exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
No such file.
Creating the file...
passwd
```



## 1.2 子 shell 应用

​	子 shell 的使用，使得脚本运行的速度更快，从而在一定程度上节省了时间。开启子 shell 时，用圆括号作为标记。

​	该脚本是一个使用 shell 对变量引用的例子，可通过该脚本了解父 shell 和子 shell 变量引用的关系。

```bash
#!/bin/bash

outer_variable=outer
(
    inner_variable=inner
    echo "inner_variable=$inner_variable"
    echo "outer_variable=$outer_variable"
)

if [ -z $inner_variable ]
then 
    echo "inner_variable undefined in main body shell"
else
	echo "inner_variable is defined in main body shell"
fi

echo "Main body of shell,inner_variable=$inner_variable"
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
inner_variable=inner
outer_variable=outer
inner_variable undefined in main body shell
Main body of shell,inner_variable=
```

​	使用脚本后发现，子 shell 可以引用父 shell 的变量，而父 shell 引用不到子 shell 的变量。

# 二、脚本递归调用

​	脚本也可以使用递归调用，所谓递归，就是函数自己调用自己。

```bash
#!/bin/bash

declare -i x=36
declare -i y=26

let "a=$x-$y"

if [ $a -lt $x ]
then
	echo "the value of a is: $a"
	sleep 1
	bash $0
fi
exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
the value of a is: 10
the value of a is: 10
the value of a is: 10
the value of a is: 10
the value of a is: 10
the value of a is: 10
^C
```

​	当满足 a 的值小于 x 的值，就执行 if 中的语句，然后调用脚本自己，因为再次调用还是满足 if 条件，所以实现递归调用。当然在工作总可以写一些更有用的递归调用脚本，比如监控某个程序是否存活。

```bash
#!/bin/bash

program_name="redis-server"
process_num=$(ps -ef | grep $program_name | wc -l)
interval=3

if [ $process_num -lt 1 ]
then
	echo "The program $program_name is down."
else
	echo "The program $program_name is running."
	sleep $interval
	bash $0
fi
```

​	运行结果，脚本会检测进程的个数，如果小于指定进程个数，则报警。如果不满足，则递归调用脚本继续监控。

```bash
[root@192 ~]# bash test.sh 
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is running.
The program redis-server is down.
```

​	当然递归会导致一个问题，就是如果一直满足 if 条件，则无限递归下去，我们的脚本进程会越来越多，所以我们一般都需要设置一个终止条件来结束递归。

```bash
[root@192 ~]# ps -ef|grep bash
root       1773   1769  0 03:37 pts/0    00:00:00 -bash
root       2150   2140  0 11:24 pts/1    00:00:00 -bash
root       2240   1773  0 11:27 pts/0    00:00:00 bash test.sh
root       2247   2240  0 11:27 pts/0    00:00:00 bash test.sh
root       2256   2247  0 11:27 pts/0    00:00:00 bash test.sh
root       2268   2256  0 11:27 pts/0    00:00:00 bash test.sh
root       2280   2268  0 11:27 pts/0    00:00:00 bash test.sh
root       2293   2280  0 11:27 pts/0    00:00:00 bash test.sh
root       2304   2293  0 11:27 pts/0    00:00:00 bash test.sh
root       2317   2304  0 11:27 pts/0    00:00:00 bash test.sh
root       2324   2317  0 11:27 pts/0    00:00:00 bash test.sh
root       2330   2324  0 11:27 pts/0    00:00:00 bash test.sh
root       2336   2330  0 11:27 pts/0    00:00:00 bash test.sh
root       2342   2336  0 11:27 pts/0    00:00:00 bash test.sh
root       2348   2342  0 11:27 pts/0    00:00:00 bash test.sh
root       2354   2348  0 11:27 pts/0    00:00:00 bash test.sh
root       2360   2354  0 11:27 pts/0    00:00:00 bash test.sh
root       2366   2360  0 11:28 pts/0    00:00:00 bash test.sh
root       2372   2366  0 11:28 pts/0    00:00:00 bash test.sh
root       2378   2372  0 11:28 pts/0    00:00:00 bash test.sh
root       2385   2378  0 11:28 pts/0    00:00:00 bash test.sh
root       2391   2385  0 11:28 pts/0    00:00:00 bash test.sh
root       2397   2391  0 11:28 pts/0    00:00:00 bash test.sh
root       2403   2397  0 11:28 pts/0    00:00:00 bash test.sh
root       2410   2150  0 11:28 pts/1    00:00:00 grep --color=auto bash
```

# 三、脚本优化问题

​	对于一些简单的问题，使用 shell 脚本处理时会很快得到解决，正因为这样，脚本运行效率的优化就成为一个重要的问题。

​	在使用 shell 脚本处理一些重要的任务时，脚本程序可能确实很好地运行且没有出现问题，但如果处理的速度太慢，那么程序的价值将大打折扣。对于这样的情况，可以选择用另一种可编译的语言将此代码重写，不过这可能不是一个非常好的选择。

​	若是遇到脚本运行效率低的情况，要做的是检查脚本中的循环体，将循环体运行时所需的时间与整个脚本运行的时间进行对比，并根据结果对循环体进行修改，如果条件允许，可以从循环中删除时间消耗多的代码段，甚至使用命令行来代替循环体；若条件不允许，则最简单的办法就是重写运行效率低的这部分代码。

​	优化的原理对于一些运行效率低下的 shell 脚本也同样适用。对于运行效率低的 shell 脚本，应尽量使用系统内建命令而不是系统外部命令，这是因为内建命令执行速度更快且一般不会产生新的子 shell。同样也应尽量避免管道的使用。因为管道运行时会产生新的子 shell 而导致时间消耗增加。

​	另外还需要注意在脚本中滥用 cat 命令的问题。对于一些耗时且脚本解决不够理想的问题，可以考虑用 C 甚至汇编语言将耗时的代码进行重写。对于文件的处理，应尽量减少文件 I/O，因为 bash 在文件处理上不是特别高效。若是需要对文件进行处理，可以更多地考虑在脚本中使用如 awk 等更合适的工具，使得各个模块能够依据需要组织起来。

​	一些适用于高级语言的优化技术也可以用在脚本上。以上这些内容，只是参考而不是定论。