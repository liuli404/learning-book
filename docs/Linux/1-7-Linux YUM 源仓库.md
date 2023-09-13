# 一、YUM 仓库介绍

## 1.1 YUM 源作用

在使用 CentOS/RHEL 系统的过程中，一般安装软件都会使用 yum 工具，使用 yum 可以简化安装的过程。但 yum 都要有一个仓库源，我们使用 yum 安装的软件都是从该仓库下载安装的。

![image-20200405144405069](./media/image-20200405144405069.png)

而且系统默认的 yum 仓库为网络源，并且是国外的。这样导致有些网络不好或者没有外网环境的用户使用 yum 工具非常麻烦，所以一般企业用户都会采用以下两种方案：

- 服务器可联网：配置国内 yum 源
- 服务器无法上网：使用本地 yum 仓库

## 1.2 YUM 源分类

- 本地 yum 源
  - yum 仓库在本地（系统光盘/镜像文件） =>  不需要互联网

- 网络 yum 源（aliyun 源，163 源，sohu 源，知名大学开源镜像等）
  - 阿里源：<https://developer.aliyun.com/mirror/>
  - 网易源：<http://mirrors.163.com/>
  - 腾讯源：<https://mirrors.cloud.tencent.com/>
  - 清华源：<https://mirrors.tuna.tsinghua.edu.cn/>

# 二、配置本地 YUM 源

## 2.1 挂载镜像光盘

一般会使用系统镜像光盘已光驱的方式挂载到服务器上，作为镜像源。

```bash
# lsblk 
NAME           MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda              8:0    0   40G  0 disk 
├─sda1           8:1    0    2M  0 part 
├─sda2           8:2    0    8G  0 part 
│ └─Linux-swap 253:0    0    8G  0 lvm  [SWAP]
└─sda3           8:3    0   32G  0 part /
sdb              8:16   0  100G  0 disk 
sr0             11:0    1  9.5G  0 rom  
```

> 这里的 sr0 设备就是系统光盘的光驱

```bash
# 把光盘挂载到某个目录下
mount -o ro /dev/sr0 /mnt
```

选项说明：

- -o：挂载方式
  - ro 代表以 readonly     => 只读的方式进行挂载
  - rw 代表以 read/write  => 读写的方式进行挂载

## 2.2 编写本地 YUM 仓库文件

创建一个以 `*.repo` 结尾的文件，名称任意

```bash
cat >> /etc/yum.repos.d/local.repo << "EOF"
[local]
name=local yum
baseurl=file:///mnt
gpgcheck=0
enabled=1
EOF
```

> [仓库标识名称]，名称任意，在一个文件中可以拥有多个标识
>
> name=仓库名称
>
> baseurl=仓库的路径，支持多种格式，file://本地路径，ftp://，http://或https://
>
> gpgcheck=gpg密钥，值可以是0（代表不检测），1（代表检测，如果是1，下方还要定义一个gpgkey=密钥连接）
>
> enabled=是否启动当前仓库，值可以 0，也可以是 1，默认为 1，代表启动仓库

刷新 YUM 仓库缓存

```bash
yum clean all && yum makecache
```

查看当前的 YUM 仓库列表

```bash
# yum repolist all
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
repo id								repo name								status
local								local yum								enabled: 10,072
repolist: 10,072
```

# 三、配置网络 YUM 源

## 3.1 配置阿里 YUM 源

```bash
mv /etc/yum.repos.d/* /tmp && \
curl -o /etc/yum.repos.d/Centos-7.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
curl -o /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo && \
yum clean all && yum makecache
```
查看可用的源

```bash
[root@localhost ~]# yum repolist
源标识						源名称														状态
base/7/x86_64			  CentOS-7 - Base - mirrors.aliyun.com						10,072
epel/x86_64				  Extra Packages for Enterprise Linux 7 - x86_64			13,757
extras/7/x86_64			  CentOS-7 - Extras - mirrors.aliyun.com					512
updates/7/x86_64		  CentOS-7 - Updates - mirrors.aliyun.com					4,050
repolist: 28,391
```

## 3.2 配置 EPEL 扩展源

EPEL 是对官网源的一个扩展，包含基本源没有的软件包，一般会与官网基本源（CentOS-Base.repo）一起安装了，如果没有安装，可使用以下命令安装

```bash
yum install -y epel-release
# 或者
curl -o /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo
```

## 3.3 特定软件的 YUM 源配置

一般的软件在 base、epel 中可以安装了，但是还有很多例如：nginx、docker、zabbix 等三方软件，这两个源都不包含，这就需要去软件官网查找特定软件的源来安装。

找到官方文档，把 YUM 源配置，写入到 repo 文件中，例如 nginx：

```bash
cat >> /etc/yum.repos.d/nginx.repo << "EOF"
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
```

清理缓存：

```bash
yum clean all && yum makecache
```

# 四、缓存下载软件包

## 4.1 缓存介绍

什么时候需要缓存软件？

- 下次还需要安装相同版本的软件包
- 由于网络原因导致网络安装非常慢，将软件包缓存下来，配置本地仓库

## 4.2 缓存软件包

更改 yum 配置文件

```bash
# vim /etc/yum.conf 
[main]
cachedir=/var/cache/yum/$basearch/$releasever	# 定义软件包的缓存路径
keepcache=1			# 1 开启缓存；0 关闭
debuglevel=2
logfile=/var/log/yum.log
```

## 4.3 查看缓存文件

```bash
# 随便安装一个软件，查看缓存目录的软件包
yum install -y lrzsz
```

```bash
# ll /var/cache/yum/x86_64/7/base/packages/
total 136
-rw-r--r--. 1 root root 79376 Jul  4  2014 lrzsz-0.12.20-36.el7.x86_64.rpm
```

## 4.4 指定位置下载但不安装

有些场景需要软件包以及其依赖包，但是不用安装，这时可以使用 yum 下载这些包

```bash
--downloadonly        # 不安装仅下载
--downloaddir=DLDIR   # 指定一个路径存储软件包
```

下载 samba 软件及其到 data 目录

```bash
yum install --downloadonly --downloaddir=/data samba
```

查看软件包

```bash
[root@centos opt]# ll /data/
total 16876
-rw-r--r--. 1 root root  367616 Oct 15  2020 cups-libs-1.6.3-51.el7.x86_64.rpm
-rw-r--r--. 1 root root  152496 Apr  9  2021 libldb-1.5.4-2.el7.x86_64.rpm
-rw-r--r--. 1 root root   33544 Apr  4  2020 libtalloc-2.1.16-1.el7.x86_64.rpm
-rw-r--r--. 1 root root   50368 Apr  4  2020 libtdb-1.3.18-1.el7.x86_64.rpm
-rw-r--r--. 1 root root   41676 Apr  4  2020 libtevent-0.9.39-1.el7.x86_64.rpm
-rw-r--r--. 1 root root  119544 Mar  8  2023 libwbclient-4.10.16-24.el7_9.x86_64.rpm
-rw-r--r--. 1 root root   50156 Apr  9  2021 pyldb-1.5.4-2.el7.x86_64.rpm
-rw-r--r--. 1 root root   17972 Apr  4  2020 pytalloc-2.1.16-1.el7.x86_64.rpm
-rw-r--r--. 1 root root   19992 Apr  4  2020 python-tdb-1.3.18-1.el7.x86_64.rpm
-rw-r--r--. 1 root root  737644 Mar  8  2023 samba-4.10.16-24.el7_9.x86_64.rpm
-rw-r--r--. 1 root root 5244864 Mar  8  2023 samba-client-libs-4.10.16-24.el7_9.x86_64.rpm
-rw-r--r--. 1 root root  224140 Mar  8  2023 samba-common-4.10.16-24.el7_9.noarch.rpm
-rw-r--r--. 1 root root  187232 Mar  8  2023 samba-common-libs-4.10.16-24.el7_9.x86_64.rpm
-rw-r--r--. 1 root root  478956 Mar  8  2023 samba-common-tools-4.10.16-24.el7_9.x86_64.rpm
-rw-r--r--. 1 root root  278196 Mar  8  2023 samba-libs-4.10.16-24.el7_9.x86_64.rpm
```

# 五、自建 YUM 源服务器

某些情况下，我们需要在纯内网的服务器集群里搭建一个 YUM 源仓库，用来给内网服务器集群提供 yum 安装服务。

## 5.1 安装仓库工具

安装 httpd 服务和 createrepo、reposync 工具

- httpd: 用来搭建简单的 http 服务，访问仓库软件
- createrepo：将软件列表生成 yum 元数据，类似于软件目录索引
- reposync：yum 仓库同步工具，本次用来将阿里的仓库同步到本地

```bash
yum install -y createrepo yum-utils httpd
```
先创建好软件包目录用来存储软件包

```bash
mkdir -p /data/{base,epel,extras,updates}
```
软连接到 httpd 根目录

```shell
ln -s /data/base /var/www/html/base
ln -s /data/epel /var/www/html/epel
ln -s /data/extras /var/www/html/extras
ln -s /data/updates /var/www/html/updates
```

启动 httpd 服务

```shell
systemctl start httpd && systemctl enable httpd
```

防火墙开放 80 端口

```shell
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
```

关闭 selinux

```shell
setenforce 0 && sed -i 's/enforcing/disabled/g' /etc/selinux/config
```

## 5.2 reposync 同步镜像源

使用 reposync 同步这四个源，这些源软件很多，非必要不全部同步，可根据需求下载指定源

```bash
nohup reposync -n \
--repoid=base \
--repoid=epel \
--repoid=extras \
--repoid=updates \
-p /data/ >> /tmp/reposync.log 2>&1 &
```

可将该命令写入定时任务，每周同步一次

```shell
echo '00 22 * * 7 nohup reposync -n --repoid=base --repoid=epel --repoid=extras --repoid=updates -p /data/ >> /tmp/reposync.log 2>&1 &'  >> /var/spool/cron/root
```

## 5.3 生成元数据

使用 createrepo 命令，生成元数据，将该目录制作成 yum 仓库

```bash
createrepo /data/base/Packages
createrepo /data/epel/Packages
createrepo /data/extras/Packages
createrepo /data/updates/Packages
```
```shell
echo '30 23 * * 7 nohup createrepo --update /data/base/Packages >> /tmp/createrepo.log 2>&1 &'  >> /var/spool/cron/root
echo '30 23 * * 7 nohup createrepo --update /data/epel/Packages >> /tmp/createrepo.log 2>&1 &'  >> /var/spool/cron/root
echo '30 23 * * 7 nohup createrepo --update /data/extras/Packages >> /tmp/createrepo.log 2>&1 &'  >> /var/spool/cron/root
echo '30 23 * * 7 nohup createrepo --update /data/updates/Packages >> /tmp/createrepo.log 2>&1 &'  >> /var/spool/cron/root
```

## 5.4 客户端配置文件

其他服务器配置该 yum 地址

```bash
# 清空本身的 repo 文件
mv /etc/yum.repos.d/* /tmp
# 创建自建 yum 源文件
vi /etc/yum.repos.d/local.repo
```

```bash
# 也可将 IP 换成域名，确保已经配置域名解析
[base]
name=CentOS-Base
baseurl=http://10.11.141.10/base/Packages/
enabled=1
gpgcheck=0
 
[epel]
name=CentOS-Epel
baseurl=http://10.11.141.10/epel/Packages/
enabled=1
gpgcheck=0
 
[extras]
name=CentOS-Extras
baseurl=http://10.11.141.10/extras/Packages/
enabled=1
gpgcheck=0

[updates]
name=CentOS-Updates
baseurl=http://10.11.141.10/updates/Packages/
enabled=1
gpgcheck=0
```
生成缓存
```bash
yum clean all && yum makecache 
```

# 六、搭建定制化仓库

本地 YUM 仓库搭建完毕后，由于同步的是阿里的 YUM 源仓库，一般的常用软件，例如：`vim`、`net-tools`、`wget` 都可以使用本地仓库安装使用了，但是有些第三方的软件例如：`docker`、`zabbix`、`MongoDB` ，这些不在 `base` 与`epel` 源中，所以这时就需要定制第三方仓库了，本次实验制定一个 `docker` 源仓库。

## 6.1 安装第三方软件的源

```shell
curl -o /etc/yum.repos.d/docker-ce.repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 6.2 下载至本地 YUM 仓库

创建软件目录

```shell
mkdir -p /data/docker-ce
```

软连接到 httpd 根目录

```shell
ln -s /data/docker-ce /var/www/html/docker-ce
```

将所需要的 rpm 包下载至该目录

```shell
yum install docker-ce --downloadonly --downloaddir=/data/docker-ce
```
```shell
--downloadonly：仅下载，不安装
--downloaddir：将所有的依赖包下载至指定目录
```

## 6.3 生成元数据

使用 createrepo 生成 yum 元数据，后续每自建一个定制化仓库，都要重新使用 `createrepo --update /path/` 命令更新元数据

```shell
createrepo /data/docker-ce
```
查看是否生成 repodata 目录，有则成功
```bash
ls /data/docker-ce
```

## 6.4 客户端配置文件

```shell
# 创建自建 yum 源文件
cat > /etc/yum.repos.d/docker-ce.repo << EOF
[docker-ce]
name=docker-ce
baseurl=http://10.11.141.10/docker-ce/
enabled=1
gpgcheck=0
EOF
```

重新生成缓存

```shell
yum clean all && yum makecache
```

查看是否有自建的源，有则成功，后续安装 docker 会优先从本地 yum 源安装

```shell
yum repolist
```

再次安装 `docker-ce` 会发现安装速度特别快了

```shell
yum install -y docker-ce
```

# 七、搭建内核升级仓库

## 7.1 安装内核升级源

```bash
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```

## 7.2 安装包下载到本地

创建软件目录

```bash
mkdir -p /data/elrepo
```

软连接到 httpd 根目录

```bash
ln -s /data/elrepo /var/www/html/elrepo
```

将所需要的 rpm 包下载至该目录

```bash
yum --enablerepo=elrepo-kernel install kernel-ml --downloadonly --downloaddir=/data/elrepo/
```

## 7.3 生成元数据

```bash
createrepo /data/elrepo/
```

## 7.4 客户端配置文件

```bash
# 创建自建 yum 源文件
cat > /etc/yum.repos.d/elrepo.repo << EOF
[elrepo]
name=elrepo
baseurl=http://10.11.141.10/elrepo/
enabled=1
gpgcheck=0
EOF
```

重新生成缓存

```bash
yum clean all && yum makecache
```

查看是否有自建的源，有则成功

```bash
yum repolist
```

```bash
yum install -y kernel-ml
```
