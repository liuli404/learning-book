# 一、NTP 时间同步

网络时间协议（Network Time Protocol，NTP），用于同步网络中各个计算机的时间的协议。其用途是将计算机的时钟同步到世界协调时 UTC。

其架构为 C/S 架构，使用端口号：123。所以一般会在局域网主机中安装一台 NTP 服务端，用来与公网同步时间。局域网内的其他主机与该主机进行时间同步。

NTP通信协议原理：

1. 首先主机启动 NTP
2. 客户端会向 NTP 服务器发送调整时间的 message
3. 然后 NTP server 会送出当前的标准时间给 client
4. client 接受来自 server 的时间后，会根据这个信息来调整自己的时间，这样就实现了网络对时

常用的公网 NTP 服务器池：http://www.ntp.org.cn/pool

CentOS 中常用的两个时间同步软件为 `chronyd`、`ntpd`

# 二、chronyd（推荐）

`chronyd` 在 CentOS 7.9 版本中是预装并开启的软件，是用来取代 `ntpd` 的新一代时间同步软件。

## 2.1 安装

```shell
yum install -y chrony
```

## 2.2 配置

- 服务端配置，默认配置文件为 `/etc/chrony.conf`

```shell
# 使用公网 ntp 服务来同步时间，国内的服务器一般使用 cn.ntp.org.cn
server cn.ntp.org.cn iburst

# 根据实际时间计算修正值，并将补偿参数记录在该指令指定的文件里
driftfile /var/lib/chrony/drift

# 根据需要通过加速或减慢时钟来逐渐校正任何时间偏移
makestep 1.0 3

# 启用内核时间与 RTC 时间同步 (自动写回硬件)。
rtcsync

# 允许哪个网段的客户端连接，一般设置自己局域网网段
allow 0.0.0.0/0

# 日志文件的路径
logdir /var/log/chrony
```

- 客户端配置，默认配置文件为 `/etc/chrony.conf`

```shell
# 使用集群内的 ntp 服务器来同步时间
server 10.10.0.10 iburst

# 根据实际时间计算修正值，并将补偿参数记录在该指令指定的文件里
driftfile /var/lib/chrony/drift

# 根据需要通过加速或减慢时钟来逐渐校正任何时间偏移
makestep 1.0 3

# 启用内核时间与 RTC 时间同步 (自动写回硬件)。
rtcsync

# 日志文件的路径
logdir /var/log/chrony
```

## 2.3 启动

启动并设置为开机自启

```shell
systemctl restart chronyd && systemctl enable chronyd && systemctl status chronyd
```
## 2.4 常用命令

```shell
# 查看时间同步源
chronyc sources -v

# 查看时间同步源状态
chronyc sourcestats -v

# 校准时间服务器
chronyc tracking
```

# 三、ntpd

`ntpd` 是一个老牌的时间同步软件，架构与用法和 `chronyd` 类似，但是如果系统中已经启动了 `chronyd` 需要提前关掉，避免冲突。

## 3.1 安装

```shell
yum install -y ntp
```

## 3.2 配置

- 服务端配置，默认配置文件 `/etc/ntp.conf`

```shell
# 根据实际时间计算修正值，并将补偿参数记录在该指令指定的文件里
driftfile /var/lib/ntp/drift

# 允许与我们的时间源同步，但不允许允许源代码查询或修改此系统上的服务
restrict default nomodify notrap nopeer noquery

# 允许本地连接
restrict 127.0.0.1 
restrict ::1

# 允许连接的局域网络段
restrict 10.10.0.0 mask 255.255.255.0 nomodify notrap
restrict 10.10.10.0 mask 255.255.255.0 nomodify notrap
restrict 10.10.20.0 mask 255.255.255.0 nomodify notrap

# 使用公网 ntp 服务来同步时间，国内的服务器一般使用 cn.ntp.org.cn
server cn.ntp.org.cn iburst

# 如果无法与上层ntp server通信以本地时间为标准时间
server   127.127.1.0    # local clock
fudge    127.127.1.0 stratum 10

includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
```

- 客户端配置，默认配置文件 `/etc/ntp.conf`

```shell
# 根据实际时间计算修正值，并将补偿参数记录在该指令指定的文件里
driftfile /var/lib/ntp/drift

# 允许与我们的时间源同步，但不允许允许源代码查询或修改此系统上的服务
restrict default nomodify notrap nopeer noquery

# 允许本地连接
restrict 127.0.0.1 
restrict ::1

# 使用公网 ntp 服务来同步时间，国内的服务器一般使用 cn.ntp.org.cn
server 10.10.0.10 iburst

# 如果无法与上层ntp server通信以本地时间为标准时间
server   127.127.1.0    # local clock
fudge    127.127.1.0 stratum 10

includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
disable monitor
```

## 3.3 启动

```shell
systemctl start ntpd && systemctl enable ntpd && systemctl status ntpd
```

## 3.4 常用命令

```shell
# 查看时间同步源
ntpq -p

# 查看 ntp 服务状态
ntpstat

# 手动向服务端同步命令
ntpdate 10.10.0.10
```

