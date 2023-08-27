欢迎来到我的学习笔记，也可以逛逛我的其他站点：<a href="https://blog.liuli.host/" style="text-decoration: none;"> <img src="./index/avatar.jpg" alt="个人博客" width="40" height="40">技术博客 </a><a href="https://github.com/liuli404" style="text-decoration: none;"> <img src="./index/49890141-1693123503435-8.jpeg" alt="Github" width="40" height="40">GitHub主页  </a><a href="https://blog.csdn.net/qq_39680564" style="text-decoration: none;"> <img src="./index/330f74740ea44b34a2317fe71b75c0eb_qq_39680564.png" alt="CSDN博客" width="40" height="40">CSDN博客 </a>


---

# 系统初始化

```bash
#!/bin/bash
# 设置时区并同步时间
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
if ! crontab -l |grep ntpdate &>/dev/null ; then
(echo "* 1 * * * ntpdate time.windows.com >/dev/null 2>&1";crontab -l)
|crontab
fi

# 禁用 selinux
setenforce 0 && sed -i '/SELINUX/{s/permissive/disabled/}' /etc/selinux/config

# 关闭防火墙
if egrep "7.[0-9]" /etc/redhat-release &>/dev/null; then
systemctl stop firewalld
systemctl disable firewalld
elif egrep "6.[0-9]" /etc/redhat-release &>/dev/null; then
service iptables stop
chkconfig iptables off
fi

# 历史命令显示操作时间
if ! grep HISTTIMEFORMAT /etc/bashrc; then
echo 'export HISTTIMEFORMAT="%F %T `whoami` "' >> /etc/bashrc
fi

# SSH 超时时间
if ! grep "TMOUT=600" /etc/profile &>/dev/null; then
echo "export TMOUT=600" >> /etc/profile
fi

# 禁止 root 远程登录
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 禁止定时任务向发送邮件
sed -i 's/^MAILTO=root/MAILTO=""/' /etc/crontab

# 设置最大打开文件数
if ! grep "* soft nofile 65535" /etc/security/limits.conf &>/dev/null; then
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
EOF
fi

# 系统内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 20480
net.ipv4.tcp_max_syn_backlog = 20480
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_fin_timeout = 20
EOF

# 减少SWAP使用
echo "0" > /proc/sys/vm/swappiness
```

# 打印各种时间格式

```bash
echo "显示星期简称(如:Sun)"
date +%a
echo "显示星期全称(如:Sunday)"
date +%A
echo "显示月份简称(如:Jan)"
date +%b
echo "显示月份全称(如:January)"
date +%B
echo "显示数字月份(如:12)"
date +%m
echo "显示数字日期(如:01 号)"
date +%d
echo "显示数字年(如:01 号)"
date +%Y 
echo "显示年-月-日"
date +%F
echo "显示小时(24 小时制)"
date +%H
echo "显示分钟(00..59)"
date +%M
echo "显示秒"
date +%S
echo "显示纳秒"
date +%N
echo "组合显示"
date +"%Y%m%d %H:%M:%S"
```

# MySQL 数据库备份

```bash
#!/bin/bash
DATE=$(date +%F_%H-%M-%S)
HOST=localhost
USER=backup
PASS=123.com
BACKUP_DIR=/data/db_backup
DB_LIST=$(mysql -h$HOST -u$USER -p$PASS -s -e "show databases;" 2>/dev/null
|egrep -v "Database|information_schema|mysql|performance_schema|sys")

for DB in $DB_LIST; do
	BACKUP_NAME=$BACKUP_DIR/${DB}_${DATE}.sql
	if ! mysqldump -h$HOST -u$USER -p$PASS --databases $DB > $BACKUP_NAME 2>/dev/null;
	then
		echo "$BACKUP_NAME 备份失败!"
	fi
done
```

# Nginx 访问日志分析

```bash
#!/bin/bash
# 日志格式: $remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"

LOG_FILE=$1
echo "统计访问最多的10个IP"
awk '{a[$1]++}END{print "UV:",length(a);for(v in a)print v,a[v]}' $LOG_FILE |sort -k2 -nr |head -10
echo "----------------------"

echo "统计时间段访问最多的IP"
awk '$4>="[01/Dec/2018:13:20:25" && $4<="[27/Nov/2018:16:20:49"{a[$1]++}END{for(v in a)print v,a[v]}' $LOG_FILE |sort -k2 -nr|head -10
echo "----------------------"

echo "统计访问最多的10个页面"
awk '{a[$7]++}END{print "PV:",length(a);for(v in a){if(a[v]>10)print v,a[v]}}'
$LOG_FILE |sort -k2 -nr
echo "----------------------"

echo "统计访问页面状态码数量"
awk '{a[$7" "$9]++}END{for(v in a){if(a[v]>5)print v,a[v]}}'
```

# 查看网卡实时流量

```bash
#!/bin/bash
NIC=$1
echo -e " In ------ Out"
while true; do
	OLD_IN=$(awk '$0~"'$NIC'"{print $2}' /proc/net/dev)
	OLD_OUT=$(awk '$0~"'$NIC'"{print $10}' /proc/net/dev)
	sleep 1
	NEW_IN=$(awk '$0~"'$NIC'"{print $2}' /proc/net/dev)
	NEW_OUT=$(awk '$0~"'$NIC'"{print $10}' /proc/net/dev)
	IN=$(printf "%.1f%s" "$((($NEW_IN-$OLD_IN)/1024))" "KB/s")
	OUT=$(printf "%.1f%s" "$((($NEW_OUT-$OLD_OUT)/1024))" "KB/s")
	echo "$IN $OUT"
	sleep 1
done
```

# 查看服务器状态

```bash
#!/bin/bash
function cpu(){
	util=$(vmstat | awk '{if(NR==3)print $13+$14}')
	iowait=$(vmstat | awk '{if(NR==3)print $16}')
	echo "CPU - 使用率: ${util}% ,等待磁盘 IO 相应使用率: ${iowait}:${iowait}%"
}

function memory (){
	total=`free -m |awk '{if(NR==2)printf "%.1f",$2/1024}'`
	used=`free -m |awk '{if(NR==2) printf "%.1f",($2-$NF)/1024}'`
	available=`free -m |awk '{if(NR==2) printf "%.1f",$NF/1024}'`
	echo "内存 - 总大小: ${total}G, 使用: ${used}G, 剩余: ${available}G"
}

function disk(){
	fs=$(df -h |awk '/^\/dev/{print $1}')
	for p in $fs; do
		mounted=$(df -h |awk '$1=="'$p'"{print $NF}')
		size=$(df -h |awk '$1=="'$p'"{print $2}')
		used=$(df -h |awk '$1=="'$p'"{print $3}')
		used_percent=$(df -h |awk '$1=="'$p'"{print $5}')
		echo "硬盘 - 挂载点: $mounted, 总大小: $size, 使用: $used, 使用率:$used_percent"
	done
}

function tcp_status() {
	summary=$(ss -antp |awk '{status[$1]++}END{for(i in status) printf i":"status[i]" "}')
	echo "TCP连接状态 - $summary"
}

cpu
memory
disk
tcp_status
```

# 查看内存CPU使用过高的程序

```bash
#!/bin/bash
echo "-------------------CUP占用前10排序--------------------------------"
ps -eo user,pid,pcpu,pmem,args --sort=-pcpu |head -n 10
echo "-------------------内存占用前10排序--------------------------------"
ps -eo user,pid,pcpu,pmem,args --sort=-pmem |head -n 10
```

# 检测网站是否异常并发送邮件

```bash
#!/bin/bash
URL_LIST="baidu.com blog.liuli.host"
for URL in $URL_LIST; do
	FAIL_COUNT=0
	for ((i=1;i<=3;i++)); do
		HTTP_CODE=$(curl -o /dev/null --connect-timeout 3 -s -w "%{http_code}" $URL)
		if [ $HTTP_CODE -eq 200 ]; then
			echo "$URL OK"
			break
		else
			echo "$URL retry $FAIL_COUNT"
			sleep 2
			let FAIL_COUNT++
		fi
	done
	if [ $FAIL_COUNT -eq 3 ]; then
	echo "Warning: $URL Access failure!"
	echo "网站$URL坏掉，请及时处理" | mail -s "$URL网站高危" 1xxxxxxxx@qq.com
	fi
done
```

# 带选择的程序示例

```bash
#!/bin/bash
echo "*cmd menu* 1-date 2-ls 3-who 4-pwd 0-exit"
while :
do
	# 捕获用户键入值
	read -p "please input number :" n
	n1=`echo $n|sed s'/[0-9]//'g`
	# 空输入检测
	if [ -z "$n" ]
	then
		continue
	fi
	# 非数字输入检测
	if [ -n "$n1" ]
	then
		exit 0
	fi
	break
done
case $n in
	1)
	date
	;;
	2)
	ls
	;;
	3)
	who
	;;
	4)
	pwd
	;;
	0)
	break
	;;
	#输入数字非1-4的提示
	*)
	echo "please input number is [1-4]"
esac
```

# 检测IP可用性

```bash
#!/bin/bash
myping(){
	ping -c 2 -i 0.3 -W 1 $1 &>/dev/null
	if [ $? -eq 0 ];then
		echo "$1 is up"
	else
		echo "$1 is down"
	fi
}

for i in {1..254}
do
	myping 192.168.4.$i &
done
```







---





































