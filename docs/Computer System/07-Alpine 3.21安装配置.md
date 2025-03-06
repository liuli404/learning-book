# 一、系统下载

Alpine 操作系统是一个面向安全的轻型 Linux 发行版。它不同于通常 Linux 发行版，Alpine 采用了  musl libc 和 busybox 以减小系统的体积和运行时资源消耗，但功能上比 busybox 又完善的多，因此得到开源社区越来越多的青睐。

下载地址：https://www.alpinelinux.org/downloads/

![image-20250305165324539](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305165324539.png)

# 二、系统安装

加载镜像光盘，等待自动安装。

![image-20250305165628146](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305165628146.png)

安装完毕，输入 root 用户名，直接进入系统。

![image-20250305165922764](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305165922764.png)

输入命令`setup-alpine`安装系统。设置语言和键盘布局：us、us

![image-20250305171508657](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305171508657.png)

设置系统主机名：任意

![image-20250305171535627](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305171535627.png)

设置网卡信息：

![image-20250305171719789](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305171719789.png)

填入以下网络配置：（与vi编辑器操作一致，使用wq保存）

```bash
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.100.5
    netmask 255.255.255.0
    gateway 192.168.100.2
```

![image-20250305172535294](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305172535294.png)

配置主机对外域名与DNS域名解析服务器

![image-20250305173457190](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305173457190.png)

设置 root 用户密码

![image-20250305172754970](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305172754970.png)

设置时区

![image-20250305172813982](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305172813982.png)

配置网络代理，可以不配

![image-20250305172913780](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305172913780.png)

选择NTP时间同步服务，这里推荐选择chrony

![image-20250305172950746](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305172950746.png)

配置APK镜像源，选择 e 编辑源：填入国内阿里源地址

```bash
https://mirrors.aliyun.com/alpine/v3.21/main
https://mirrors.aliyun.com/alpine/v3.21/community
```

![image-20250305191335545](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305191335545.png)

添加用户与ssh，不创建普通用户，允许root使用ssh远程登录

![image-20250305173758982](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305173758982.png)

选择安装的磁盘，默认sda

![image-20250305191417914](./07-Alpine%203.21%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250305191417914.png)

系统安装完毕，输入 `reboot` 重启系统

# 三、系统配置

## 3.1 更换APK源

安装时如果使用的社区源，可以替换成国内阿里云源，提高软件安装速度。

阿里云的镜像仓库：https://mirrors.aliyun.com/alpine/

找到对应的版本连接，添加到仓库文件中即可：

```bash
vi /etc/apk/repositories
# 阿里云源地址：
https://mirrors.aliyun.com/alpine/v3.21/main
https://mirrors.aliyun.com/alpine/v3.21/community
```

更新源

```bash
apk update
```

## 3.2 修改网卡信息

编辑网卡配置文件，修改相应信息

```bash
vim /etc/network/interfaces

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.100.15
    netmask 255.255.255.0
    gateway 192.168.100.2
```

使用命令重启网络

```bash
rc-service networking restart 
```

设置成开机自启

```bash
rc-update add networking boot
```

