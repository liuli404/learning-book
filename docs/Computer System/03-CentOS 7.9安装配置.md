# 一、系统下载

由于CentOS 7系列官方已经结束支持了，所以生产环境并**不推荐**使用该系统。

国内阿里云镜像下载列表：https://mirrors.aliyun.com/centos/7/isos/x86_64/

文件后缀名称解释：

- CentOS-7-x86_64：表示CentOS 7 版本 x86_64 位架构CPU
- DVD：标准版本（推荐）
- Everything：对标准版本的补充，集成了所有软件包（离线环境推荐）
- Minimal：最小安装版本，没有集成额外软件（学习环境推荐）
- NetInstall：网络安装版本，需要联网安装系统
- 2009/2207-2：2020年09月发布/2022年07月发布
- iso：标准镜像文件
- torrent：BT种子文件，需通过BT工具下载

![image-20250304122829595](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304122829595.png)

# 二、系统安装

CentOS 7 系列作为经典操作系统，自带GUI系统安装界面，操作简单，小白也能配置。

1. 选择 “Install CentOS 7”安装系统。

![90a0ff04d4e7441eda35624a27acac5](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/90a0ff04d4e7441eda35624a27acac5.png)

2. 系统语言设置，默认英语，拉到最下面选择“中文-简体中文（中国）”，这一步看个人爱好，如果公司生产环境要求使用英文就选英文。

![bf07208e25c0c4bf331b986a5721497](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/bf07208e25c0c4bf331b986a5721497.png)

![70f6eb3ae719d551fad283bb59b87eb](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/34ab4e44164a57e1b8ffc0d4548a513.png)

3. 给系统盘分区，点击“安装位置”。

![d563c36a4569f9d30fc7bccfff5b3c2](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/d563c36a4569f9d30fc7bccfff5b3c2.png)

4. 进来之后分区默认勾选的是：“自动配置分区”。

![ecf6a94cf0902fd75119313a8acbd44](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/ecf6a94cf0902fd75119313a8acbd44.png)

5. 勾选“我要配置分区”

![9971470c2d746211b81a1e887aedf6e](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/9971470c2d746211b81a1e887aedf6e.png)

6. 点击：“点这里自动创建他们”

![14771c687dcfb6838f389c6e3380633](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/14771c687dcfb6838f389c6e3380633.png)

7. 默认使用自动创建出来的分区规则。如果有其他需求，可以创建其他挂载点，例如 /data，并分配一些磁盘容量。
   - boot：系统启动分区，推荐最小1GB
   - /：根分区，所有目录共享该分区的容量
   - swap：交换分区，只有当系统内存不够用时，才使用该分区，用磁盘拓展内存

![f7de47dd8331de7e75766b598693447](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/f7de47dd8331de7e75766b598693447.png)

8. 格式化磁盘并分区，选择“接受更改”。

![28c2568ed7a422c1ee8f0012a7c264d](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/28c2568ed7a422c1ee8f0012a7c264d.png)

9. 网络和主机名配置：勾选“以太网”后面的开关，保持“打开”状态，获取到网络IP信息后，然后点击“配置”。

![8afde664f6e205d45653e4ae1df03f8](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/8afde664f6e205d45653e4ae1df03f8.png)

10. 选择“IPv4配置”，并改为“手动“，键入刚刚获取到的地址信息。如果有提前规划IP，也可以写入规划值。

![a13373132ba0c1d376bb01822213928](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/a13373132ba0c1d376bb01822213928.png)

11. 软件安装，我这里用的时Everything版本镜像，所有有很多软件包，如果时Minimal版本，就只有”最小安装“选项。我这里选择”最小安装“，如有其他软件包需求，可以勾上。

![66642a7b2aac9c3d2f2d1625524b170](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/66642a7b2aac9c3d2f2d1625524b170.png)

12. 所有配置完毕，点击”开始安装“。

![80c9d6468a96567bf5a37f64244f3fb](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/80c9d6468a96567bf5a37f64244f3fb.png)

13. 这里需要配置root用户密码，如果密码设置的太短或者检测到弱密码，可以点击两次”完成“强制使用。

![a25d0fd22530988c142111783cb839a](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/a25d0fd22530988c142111783cb839a.png)

14. 等待安装结束。

![a8490e2a732a0e766021fbad3c564d3](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/a8490e2a732a0e766021fbad3c564d3.png)

15. 系统安装完毕，点击”重启“。

![c196628f5c56832002d49857f523207](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/c196628f5c56832002d49857f523207.png)

16. 重启完毕后，出现系统的命令行界面，输入刚刚设置的 root 用户/密码（密码输入界面不会显示），进入系统。

![image-20250304130025314](./03-CentOS%207.9%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304130025314.png)

# 三、系统配置

## 3.1 更换YUM源

系统默认的软件仓库源为国外网站，国内使用一般会切换到国内（阿里云）镜像站点：

```bash
# 将系统自带的repos文件删除，下载阿里云提供的国内文件
mv /etc/yum.repos.d/CentOS-* /tmp/ && \
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && \
yum clean all && yum makecache 

# 查看当前使用的yum源
# yum repolist
已加载插件：fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * extras: mirrors.aliyun.com
 * updates: mirrors.aliyun.com
源标识                           源名称                                                        状态
base/7/x86_64                   CentOS-7 - Base - mirrors.aliyun.com                         10,072
epel/x86_64                     Extra Packages for Enterprise Linux 7 - x86_64               13,791
extras/7/x86_64                 CentOS-7 - Extras - mirrors.aliyun.com                          526
updates/7/x86_64                CentOS-7 - Updates - mirrors.aliyun.com                       6,173
repolist: 30,562
```

无网络环境，也可以挂载ISO镜像，作为自己的本地软件仓库：

```bash
# 挂载ISO镜像到本地目录，需要查看镜像设备是否为 /dev/sr0
mkdir -p /media/cdrom/
mount /dev/sr0 /media/cdrom/

# 生成本地YUM源仓库
cat > CentOS-Media.repo << EOF
[c7-media]
name=CentOS-Media
baseurl=file:///media/cdrom/
gpgcheck=0
enabled=1
EOF

# 启用本地仓库源
yum clean all && yum makecache
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

- 修改 SSH 的DNS解析

  当 `UseDNS yes` 时，SSH 服务器会尝试通过 DNS 反向解析客户端的 IP 地址，以获取客户端的主机名。

  如果解析失败或不匹配，可能会导致 SSH 连接延迟

```bash
# 找到 SSHD 的配置文件 UseDNS yes 行，将值改为 UseDNS no
UseDNS no

# 重启生效
systemctl restart sshd
```

## 3.3 修改IP

编辑网卡配置文件，网卡名是啥 `ifcfg-` 后面跟的就是啥

```bash
vi /etc/sysconfig/network-scripts/ifcfg-ens33
```

配置文件内容

```bash
TYPE="Ethernet"
BOOTPROTO="static"
DEFROUTE="yes"
NAME="ens33"
UUID="bb8b4b4c-7924-4ad2-b1c0-7cd9a0c84ffa"
DEVICE="ens33"
ONBOOT="yes"
IPADDR="192.168.100.11"
PREFIX="24"
GATEWAY="192.168.100.2"
DNS1="114.114.114.114"
```

重启生效

```bash
systemctl restart network
```

