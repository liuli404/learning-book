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

# 配置阿里 YUM 源

```bash
mv /etc/yum.repos.d/CentOS-* /tmp/ && \
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && \
yum clean all && yum makecache 
```

# 安装 Docker 

```bash
yum install -y yum-utils device-mapper-persistent-data lvm2 \
&& yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo \
&& yum makecache fast \
&& yum -y install docker-ce \
&& systemctl start docker && systemctl enable docker \
&& yum install -y bash-completion \
&& source /usr/share/bash-completion/bash_completion \
&& source /usr/share/bash-completion/completions/docker
```

# 安装 Docker compose

```bash
curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose \
&& chmod +x /usr/local/bin/docker-compose \
&& ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose \
&& docker-compose --version
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

# Git 命令速查

常用指令：

- git config：配置用户信息

```bash
# 配置用户名
git config --global user.name "yourname"

# 配置用户邮箱
git config --global user.email "youremail@xxx.com"

# 查看当前的配置信息
git config --global --list
```

- git clone: 克隆仓库

```bash
# 克隆远端仓库到本地
git clone <git url>

# 克隆远端仓库到本地，并同时切换到指定分支 branch1
git clone <git url> -b branch1

# 克隆远端仓库到本地并指定本地仓库的文件夹名称为 my-project
git clone <git url> my-project
```

- git add: 提交到暂存区

```bash
# 将所有修改的文件都提交到暂存区
git add .

# 将修改的文件中的指定的文件 a.js 和 b.js 提交到暂存区
git add ./a.js ./b.js

# 将 js 文件夹下修改的内容提交到暂存区
git add ./js
```

- git commit: 提交到本地仓库

```bash
# 将工作区内容提交到本地仓库，并添加提交信息 your commit message
git commit -m "your commit message"

# 将工作区内容提交到本地仓库，并对上一次 commit 记录进行覆盖
## 例如先执行 git commit -m "commit1" 提交了文件a，commit_sha为hash1；再执行 git commit -m "commit2" --amend 提交文件b，commit_sha为hash2。最终显示的是a，b文件的 commit 信息都是 "commit2"，commit_sha都是hash2
git commit -m "new message" --amend

# 将工作区内容提交到本地仓库，并跳过 commit 信息填写
## 例如先执行 git commit -m "commit1" 提交了文件a，commit_sha为hash1；再执行 git commit --amend --no-edit 提交文件b，commit_sha为hash2。最终显示的是a，b文件的 commit 信息都是 "commit1"，commit_sha都是hash1
git commit --amend --no-edit

# 跳过校验直接提交，很多项目配置 git hooks 验证代码是否符合 eslint、husky 等规则，校验不通过无法提交
## 通过 --no-verify 可以跳过校验（为了保证代码质量不建议此操作QwQ）
git commit --no-verify -m "commit message"

# 一次性从工作区提交到本地仓库，相当于 git add . + git commit -m
git commit -am
```

- git push: 提交到远程仓库

```bash
# 将当前本地分支 branch1 内容推送到远程分支 origin/branch1
git push

# 若当前本地分支 branch1，没有对应的远程分支 origin/branch1，需要为推送当前分支并建立与远程上游的跟踪
git push --set-upstream origin branch1

# 强制提交
## 例如用在代码回滚后内容
git push -f
```

- git pull: 拉取远程仓库并合并

```bash
# 若拉取并合并的远程分支和当前本地分支名称一致
## 例如当前本地分支为 branch1，要拉取并合并 origin/branch1，则直接执行：
git pull

# 若拉取并合并的远程分支和当前本地分支名称不一致
git pull <远程主机名> <分支名>
## 例如当前本地分支为 branch2，要拉取并合并 origin/branch1，则执行：
git pull git@github.com:zh-lx/git-practice.git branch1

# 使用 rebase 模式进行合并
git pull --rebase
```

其他指令：

```bash
git init                                                  # 初始化本地git仓库（创建新仓库）
git config --global user.name "xxx"                       # 配置用户名
git config --global user.email "xxx@xxx.com"              # 配置邮件
git config --global color.ui true                         # git status等命令自动着色
git config --global color.status auto
git config --global color.diff auto
git config --global color.branch auto
git config --global color.interactive auto
git config --global --unset http.proxy                    # remove  proxy configuration on git
git clone git+ssh://git@192.168.53.168/VT.git             # clone远程仓库
git status                                                # 查看当前版本状态（是否修改）
git add xyz                                               # 添加xyz文件至index
git add .                                                 # 增加当前子目录下所有更改过的文件至index
git commit -m 'xxx'                                       # 提交
git commit --amend -m 'xxx'                               # 合并上一次提交（用于反复修改）
git commit -am 'xxx'                                      # 将add和commit合为一步
git rm xxx                                                # 删除index中的文件
git rm -r *                                               # 递归删除
git log                                                   # 显示提交日志
git log -1                                                # 显示1行日志 -n为n行
git log -5
git log --stat                                            # 显示提交日志及相关变动文件
git log -p -m
git show dfb02e6e4f2f7b573337763e5c0013802e392818         # 显示某个提交的详细内容
git show dfb02                                            # 可只用commitid的前几位
git show HEAD                                             # 显示HEAD提交日志
git show HEAD^                                            # 显示HEAD的父（上一个版本）的提交日志 ^^为上两个版本 ^5为上5个版本
git tag                                                   # 显示已存在的tag
git tag -a v2.0 -m 'xxx'                                  # 增加v2.0的tag
git show v2.0                                             # 显示v2.0的日志及详细内容
git log v2.0                                              # 显示v2.0的日志
git diff                                                  # 显示所有未添加至index的变更
git diff --cached                                         # 显示所有已添加index但还未commit的变更
git diff HEAD^                                            # 比较与上一个版本的差异
git diff HEAD -- ./lib                                    # 比较与HEAD版本lib目录的差异
git diff origin/master..master                            # 比较远程分支master上有本地分支master上没有的
git diff origin/master..master --stat                     # 只显示差异的文件，不显示具体内容
git remote add origin git+ssh://git@192.168.53.168/VT.git # 增加远程定义（用于push/pull/fetch）
git branch                                                # 显示本地分支
git branch --contains 50089                               # 显示包含提交50089的分支
git branch -a                                             # 显示所有分支
git branch -r                                             # 显示所有原创分支
git branch --merged                                       # 显示所有已合并到当前分支的分支
git branch --no-merged                                    # 显示所有未合并到当前分支的分支
git branch -m master master_copy                          # 本地分支改名
git checkout -b master_copy                               # 从当前分支创建新分支master_copy并检出
git checkout -b master master_copy                        # 上面的完整版
git checkout features/performance                         # 检出已存在的features/performance分支
git checkout --track hotfixes/BJVEP933                    # 检出远程分支hotfixes/BJVEP933并创建本地跟踪分支
git checkout v2.0                                         # 检出版本v2.0
git checkout -b devel origin/develop                      # 从远程分支develop创建新本地分支devel并检出
git checkout -- README                                    # 检出head版本的README文件（可用于修改错误回退）
git merge origin/master                                   # 合并远程master分支至当前分支
git cherry-pick ff44785404a8e                             # 合并提交ff44785404a8e的修改
git push origin master                                    # 将当前分支push到远程master分支
git push origin :hotfixes/BJVEP933                        # 删除远程仓库的hotfixes/BJVEP933分支
git push --tags                                           # 把所有tag推送到远程仓库
git fetch                                                 # 获取所有远程分支（不更新本地分支，另需merge）
git fetch --prune                                         # 获取所有原创分支并清除服务器上已删掉的分支
git pull origin master                                    # 获取远程分支master并merge到当前分支
git mv README README2                                     # 重命名文件README为README2
git reset --hard HEAD                                     # 将当前版本重置为HEAD（通常用于merge失败回退）
git rebase
git branch -d hotfixes/BJVEP933                           # 删除分支hotfixes/BJVEP933（本分支修改已合并到其他分支）
git branch -D hotfixes/BJVEP933                           # 强制删除分支hotfixes/BJVEP933
git ls-files                                              # 列出git index包含的文件
git show-branch                                           # 图示当前分支历史
git show-branch --all                                     # 图示所有分支历史
git whatchanged                                           # 显示提交历史对应的文件修改
git revert dfb02e6e4f2f7b573337763e5c0013802e392818       # 撤销提交dfb02e6e4f2f7b573337763e5c0013802e392818
git ls-tree HEAD                                          # 内部命令：显示某个git对象
git rev-parse v2.0                                        # 内部命令：显示某个ref对于的SHA1 HASH
git reflog                                                # 显示所有提交，包括孤立节点
git show HEAD@{5}
git show master@{yesterday}                               # 显示master分支昨天的状态
git log --pretty=format:'%h %s' --graph                   # 图示提交日志
git show HEAD~3
git show -s --pretty=raw 2be7fcb476
git stash                                                 # 暂存当前修改，将所有至为HEAD状态
git stash list                                            # 查看所有暂存
git stash show -p stash@{0}                               # 参考第一次暂存
git stash apply stash@{0}                                 # 应用第一次暂存
git grep "delete from"                                    # 文件中搜索文本“delete from”
git grep -e '#define' --and -e SORT_DIRENT
```



---





































