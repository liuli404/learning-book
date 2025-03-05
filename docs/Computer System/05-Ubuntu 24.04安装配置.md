# 一、系统下载

Ubuntu属于Debian系列，属于 Debian系统的一个分支，Ubuntu 主要有 Desktop 桌面版与 Server 服务器版

桌面版更适合个人用户，拥有丰富的应用软件；服务器版被工程设计作为互联网的骨干系统。

服务器版本下载地址：https://ubuntu.com/download/server

其中带 LTS后缀的表示 Long Term Support （长期支持版本）

![image-20250304161702649](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304161702649.png)

# 二、系统安装

第一个选项，安装 Ubuntu Server版本。

![image-20250304155420712](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304155420712.png)

选择语言“English”

![image-20250304155602553](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304155602553.png)

设置英文键盘

![image-20250304155632618](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304155632618.png)

选择安装的类型：Ubuntu Server

![image-20250304155935189](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304155935189.png)

设置网卡，tab键选择，空格键选中。

![image-20250304155953947](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304155953947.png)

选择编辑 IPv4 

![image-20250304160010422](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160010422.png)

配置好IP信息

- Subnet：子网信息
- Address：IP地址
- Gateway：网关地址
- Name Servers：DNS服务器地址
- Search domains：补全域名，可以为空，

![image-20250304160102117](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160102117.png)

IP配置完成，选择Done下一步

![image-20250304160125886](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160125886.png)

mirror镜像站地址，可以为空，并跳过

![image-20250304160335424](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160335424.png)

选择安装系统的磁盘

![image-20250304160352373](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160352373-1741075433083-1.png)

磁盘分区，使用系统默认分区

![image-20250304160509825](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160509825.png)

选择 Continue 下一步

![image-20250304160527812](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160527812.png)

设置普通用户的账号、密码

![image-20250304160738372](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160738372-1741075659444-3.png)

激活 pro版本，选择跳过

![image-20250304160811229](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160811229.png)

选择安装 OpenSSH server，方便后期使用ssh远程连接服务器

![image-20250304160851498](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160851498.png)

其他软件包，按需选择，我这里不安装。

![image-20250304160901247](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160901247.png)

安装程序进行中，等待安装完毕

![image-20250304160911694](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304160911694.png)

安装完毕，选择“Reboot Now”，重启服务器。

![image-20250304161908956](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304161908956.png)

重启完毕，进入命令行界面，输入之前创建的用户/密码（输入界面不显示）登入系统。

![image-20250304162318886](./05-Ubuntu%2024.04%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AE/image-20250304162318886.png)

# 三、系统配置

## 3.1 开启 root 用户

由于安装是系统没有让设置 root 用户密码，所以如果需要 root 登录，要使用普通用户重置下 root 密码。

```bash
liuli@ubuntu24:~$ sudo su - root
[sudo] password for liuli: 
root@ubuntu24:~# passwd root 
New password: 
Retype new password: 
passwd: password updated successfully
```

修改 sshd 配置文件 将 `PermitRootLogin prohibit-password` 改为 `PermitRootLogin yes`

- prohibit-password：此值表示允许 root 用户登录，但禁止使用密码认证。root 用户只能通过公钥认证（即使用 SSH 密钥）登录。
- yes：允许 root 用户使用密码或密钥登录。
- no：完全禁止 root 用户通过 SSH 登录。
- without-password：与 `prohibit-password` 相同，允许密钥登录，禁止密码登录。
- forced-commands-only：仅允许 root 用户执行特定的命令，通常用于自动化任务。

```bash
# 修改配置
vi /etc/ssh/sshd_config
# 重启 ssh 服务
systemctl restart ssh
```

## 3.2 修改 apt 源

系统自带的 apt 源为国外站点，为了提高软件包安装速度，需要修改为国内站点。

```bash
# 备份旧文件
mv /etc/apt/sources.list.d/ubuntu.sources /tmp

# 生成阿里云源文件
cat > /etc/apt/sources.list.d/ubuntu.sources << EOF
Types: deb
URIs: http://mirrors.aliyun.com/ubuntu/
Suites: noble noble-updates noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

# 刷新apt 源
apt update
```

## 3.3 修改IP

编辑网卡配置文件

```bash
vi /etc/netplan/50-cloud-init.yaml
```

修改配置内容

```bash
network:
  version: 2
  ethernets:
    ens33:
      addresses:
      - "192.168.100.13/24"
      nameservers:
        addresses:
        - 114.114.114.114
        search: []
      routes:
      - to: "default"
        via: "192.168.100.2"
```

应用网卡配置

```bash
netplan apply
```

