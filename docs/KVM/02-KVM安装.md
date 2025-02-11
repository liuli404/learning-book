# 一、环境准备

## 1.1 硬件虚拟化设置检查

由于KVM是硬件辅助类型的虚拟化，所以要先检查服务器是否开启了硬件虚拟化支持（VT-x），打开BIOS面板查看如下：

![image-20250210223139733](./02-KVM%E5%AE%89%E8%A3%85/image-20250210223139733.png)

## 1.2 操作系统及其配置

操作系统镜像：CentOS-7-x86_64-Everything-2207-02.iso

操作系统软件安装：Minimal Install 最小化安装；网络开启网卡。

- 服务器CPU：8个逻辑处理器

- 服务器内存：8192MB

- 服务器硬盘：20G系统盘+100G数据盘

操作系统安装完成后，使用命令查看当前CPU是否开启虚拟化功能，有 vmx 或者 svm 显示就是开启了。

```bash
[root@localhost ~]# cat /proc/cpuinfo | grep -E -o 'vmx|svm'
svm
svm
svm
svm
```

如果没有结果，查看BIOS是否开启了CPU硬件虚拟化VT-x功能，或者如果使用VMware虚拟化软件平台，是否勾选虚拟化引擎配置。

![image-20250210224905163](./02-KVM%E5%AE%89%E8%A3%85/image-20250210224905163.png)

# 二、KVM 安装

## 2.1 KVM虚拟化平台安装

```bash
yum -y groups install "Virtualization-hypervisor"
yum -y groups install "Virtualization-platform"
yum -y groups install "Virtualization-tools"
yum -y groups install "Virtualization-client"
```

无网络情况下可以使用本地光盘做YUM源

```bash
# vim /etc/yum.repos.d/CentOS-Media.repo 

[c7-media]
name=CentOS-$releasever - Media
baseurl=file:///media/cdrom/
gpgcheck=0
```

## 2.2 安装桌面

virt-manager是一个图形化界面的虚拟化管理工具，所以需要服务器有桌面功能。

```bash
yum -y groupinstall "gnome-desktop"
```

```bash
# 启动桌面
startx

# 设置成默认启动方式为桌面
systemctl set-default graphical.target
# 设置成命令模式
systemctl set-default multi-user.target

# 重启
reboot
```

命令行界面输入 `virt-manager` 调出工具的控制界面

![image-20250211102126559](./02-KVM%E5%AE%89%E8%A3%85/image-20250211102126559.png)

# 三、远程管理

实际工作中，无法直接坐在服务器前面使用桌面，所以需要远程管理的方式：

## 3.1 SSH

可以使用远程工具 xshell 等远程连接。

## 3.2 VNC

**VNC 服务端安装**

```bash
yum install -y tigervnc-server 
```

复制配置文件，并修改配置

```bash
# Quick HowTo:
# 1. Copy this file to /etc/systemd/system/vncserver@.service
# 2. Replace <USER> with the actual user name and edit vncserver
#    parameters in the wrapper script located in /usr/bin/vncserver_wrapper
# 3. Run `systemctl daemon-reload`
# 4. Run `systemctl enable vncserver@:<display>.service`


cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service
vim /etc/systemd/system/vncserver@.service
# 修改内容
# Replace <USER> with the actual user name and edit vncserver
ExecStart=/usr/bin/vncserver_wrapper root %i
```

设置密码：

```bash
# vncpasswd
Password:
Verify:
Would you like to enter a view-only password (y/n)? n
A view-only password is not used
```

启动服务

```bash
systemctl daemon-reload
systemctl enable vncserver@:1.service
systemctl start vncserver@:1.service
```

现在就可以用 IP 和端口号（例如 192.168.1.80:1 ，这里的端口不是服务器的端口，而是视 VNC 连接数的多少从1开始排序）来连接 VNC 服务器了。

**VNC 客户端安装**

客户端下载地址：[https://www.realvnc.com/en/connect/download/viewer/](https://www.realvnc.com/en/connect/download/viewer/)

![image-20250211103504673](./02-KVM%E5%AE%89%E8%A3%85/image-20250211103504673.png)

## 3.3 X-Windows

需要Windows提前安装Xming，或者Xshell配套的Xmanger软件，才可以打开Virt Manager的图形化界面。

Xming（开源）：[https://sourceforge.net/projects/xming/](https://sourceforge.net/projects/xming/)

安装后，xshell命令行界面直接输入 `virt-manager` 命令即可打开图形化界面

![image-20250211103755219](./02-KVM%E5%AE%89%E8%A3%85/image-20250211103755219.png)

