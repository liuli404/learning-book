# 一、系统下载

Rocky Linux 是继 CentOS 停止维护后的替代产品，维护者声称100%兼容CentOS系列，并与CentOS版本同步维护。

下载地址：https://rockylinux.org/zh-CN/download

Rocky Linux一共两个版本：9系列、8系列，分别对应 CentOS 的9系列与8系列，点击DVD ISO下载即可，本文下载 9 版本。

![image-20250304221607199](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304221607199.png)

# 二、系统安装

大部分与CentOS一致，由于是新版本，GUI界面更符合现代审美

![image-20250304220536028](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220536028.png)

第一行中文，选择“中文-简体中文（中国）”

![image-20250304220710916](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220710916.png)

带感叹号的为必须配置的选项。

![image-20250304220729436](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220729436.png)

选择系统安装的磁盘

![image-20250304220738859](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220738859.png)

选择存储配置-自定义

![image-20250304220751391](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220751391.png)

点击”点击这里自动创建它们“，创建默认磁盘分区

![image-20250304220802275](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220802275.png)

使用默认的磁盘分区，如有特殊的需求，可在这一步更改

![image-20250304220812290](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220812290.png)

选择”接受更改“，系统会格式化磁盘并自动分区。

![image-20250304220821267](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220821267.png)

选择最小安装版本

![image-20250304220834424](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220834424.png)

配置网卡，已经默认打开网卡连接，点击”配置"，配置网卡。

![image-20250304220851541](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220851541.png)

手动配置“IPv4 设置”，填入IP信息。

![image-20250304220930842](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304220930842.png)

设置 root 用户密码。并勾选“允许 root 用户使用密码进行 SSH 登录”。

![image-20250304221016482](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304221016482.png)

所有配置完毕，点击“开始安装”

![image-20250304221029269](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304221029269.png)

等待系统安装

![image-20250304221039114](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304221039114.png)

系统安装完毕，点击“重启系统”。

![image-20250304221618797](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304221618797.png)

输入 root 用户账号/密码（密码输入不显示），进入系统命令行终端。

![image-20250304222337205](./06-Rocky%20Linux%209.5%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304222337205.png)

# 三、系统配置

## 3.1 更换 dnf 源

系统默认的软件仓库源为国外网站，国内使用一般会切换到国内（阿里云）镜像站点：

```bash
# 更换阿里云提供的国内镜像地址
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/rocky-*.repo


# 安装epel源
dnf install -y epel-release
sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|g' \
    -i.bak \
    /etc/yum.repos.d/epel*.repo

# 刷新并生成缓存
dnf clean all && dnf makecache
```

无网络环境，也可以挂载ISO镜像，作为自己的本地软件仓库：

```bash
# 挂载ISO镜像到本地目录，需要查看镜像设备是否为 /dev/sr0
mkdir -p /media/cdrom/
mount /dev/sr0 /media/cdrom/

# 生成本地仓库文件
cat > Rocky-Media.repo << EOF
[media-baseos]
name=Rocky Linux $releasever - Media - BaseOS
baseurl=file:///media/cdrom/BaseOS
gpgcheck=0
enabled=1

[media-appstream]
name=Rocky Linux $releasever - Media - AppStream
baseurl=file:///media/cdrom/AppStream
gpgcheck=0
enabled=1
EOF

# 启用本地仓库源
dnf clean all && dnf makecache
```

## 3.2 系统调优

- 设置最大打开文件数

  软、硬限制值可根据系统配置自行调整

```bash
# 当前会话生效
ulimit -n 65535
# 永久生效
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
EOF
# 当前会话生效
sysctl -w fs.file-max=2097152
# 永久生效
cat >> /etc/sysctl.conf << EOF
fs.file-max = 2097152
EOF

# 保存后加载配置
sysctl -p
```
