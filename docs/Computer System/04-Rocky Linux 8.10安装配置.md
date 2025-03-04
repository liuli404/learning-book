# 一、系统下载

Rocky Linux 是继 CentOS 停止维护后的替代产品，维护者声称100%兼容CentOS系列，并与CentOS版本同步维护。

下载地址：https://rockylinux.org/zh-CN/download

Rocky Linux一共两个版本：9系列、8系列，选择适合的CPU架构，点击DVD ISO下载即可，本文下载8.10 版本。

![image-20250304142405020](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142405020.png)

# 二、系统安装

大部分与CentOS一直，由于是新版本，GUI界面更符合现代审美

![image-20250304142631063](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142631063.png)

- 语言选择“中文-简体中文（中国）”

![image-20250304142809163](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142809163.png)

- 选择：“安装目标位置”，进行磁盘分区

![image-20250304142826984](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142826984.png)

- 选择“存储配置-自定义”

![image-20250304142843553](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142843553.png)

- 点击“点击这里自动创建它们”

![image-20250304142915521](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142915521.png)

- 默认使用自动的分区，也可新增挂载点并分配磁盘。

![image-20250304142901022](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142901022.png)

- 点击“接受更改”，格式化磁盘并自动分区

![image-20250304142939072](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304142939072.png)

- 软件安装选择“最小安装”

![image-20250304143003852](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143003852.png)

- 日期时区选择 “亚洲-上海”

![image-20250304143025457](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143025457.png)

- 网络以太网卡选择， “打开”，获取网络信息，并点击“配置”

![image-20250304143041354](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143041354.png)

- 选择“IPv4 设置”，并手动键入刚刚获取的IP信息。

![image-20250304143104823](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143104823.png)

![image-20250304143114104](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143114104.png)

- 设置 root 用户密码，如果太短或简单，需要点两次“完成”强制设置。

![image-20250304143136891](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143136891.png)

- 所有项目配置完毕，点击“开始安装”

![image-20250304143146377](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143146377.png)

- 等待安装进度完毕。

![image-20250304143154589](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143154589.png)

- 安装完毕，点击“重启系统”

![image-20250304143839267](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143839267.png)

- 进入命令行界面，输入 root 用户/密码（密码输入界面不可见）进入系统。

![image-20250304143957889](./04-Rocky%20Linux%208.10%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304143957889.png)

# 三、系统配置

## 3.1 更换 dnf 源

系统默认的软件仓库源为国外网站，国内使用一般会切换到国内（阿里云）镜像站点：

```bash
# 更换阿里云提供的国内镜像地址
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/Rocky-*.repo


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
