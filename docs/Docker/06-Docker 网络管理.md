# 一、容器网络

## 1.1 容器的默认网络配置

每台主机安装完 docker 程序后，都会生成一个 `docker0` 网卡，默认的IP网段为 `172.17.0.1/16`，该网卡是容器的默认网卡，所有容器通过桥接该网卡与外界通讯，容器的 IP 都在该网段范围内。

注：如果想更改该默认网段，可以在 `daemon.json` 增加配置 `"bip": "192.168.100.1/24"`。并重启docker服务。

```bash
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:e6:1d:ab brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    inet 192.168.100.13/24 brd 192.168.100.255 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fee6:1dab/64 scope link 
       valid_lft forever preferred_lft forever
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 22:a0:95:7d:dc:c0 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::20a0:95ff:fe7d:dcc0/64 scope link 
       valid_lft forever preferred_lft forever
```

每当我们创建一个容器后，宿主机上会增加一个 `veth` 开头的网卡，`if2`表示容器内的2张号网卡。

> veth（Virtual Ethernet）是Linux内核中的一种虚拟网络设备，通常用于连接两个网络命名空间。veth 设备总是**成对出现**，当在一个网络命名空间中创建veth设备时，会同时创建两个端点。veth设备的两个端点可以被看作是一个虚拟的以太网电缆，任何发送到其中一个端点的数据包都会被立即从另一个端点传出。以下是veth设备的一些主要特性：
>
> 1. **命名空间间通信**：veth设备主要用于**连接不同的网络命名空间**，允许它们之间进行通信。这使得在一个隔离的环境中运行的进程可以与外部世界交互，而不会影响到其它网络命名空间。 
> 2. **成对出现**：veth设备总是成对创建的，形成一个虚拟的双向通道。当数据包发送到一个端点时，它会从另一个端点出来。因此，你可以把veth设备看作是一个虚拟的**以太网电缆**。
> 3. **灵活性**：veth设备的两个端点可以分别位于不同的网络命名空间中，甚至可以在同一命名空间中。 这为设置复杂的网络拓扑提供了很大的灵活性。
> 4. 和其他网络设备相互操作：veth设备可以和Linux的其他网络设备（如bridge、veth pair、 physical NIC等）一起使用，创建复杂的网络配置。 
>
> veth设备在一些网络虚拟化技术中被广泛使用，例如Docker容器。每一个Docker容器都有自己的网络命名空间，Docker使用veth设备连接容器的网络命名空间和主机的网络命名空间，使得容器可以和外部网络进行通信。

```bash
# ip a
30: veth66852fa@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default 
    link/ether aa:06:0c:bc:a8:49 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::a806:cff:febc:a849/64 scope link 
       valid_lft forever preferred_lft forever
```

容器内网卡信息，`if30`表示宿主机的30号网卡

```bash
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0@if30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 1a:62:fc:e7:35:d4 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
```

使用 `brctl show` 查看网卡的桥接状态。

```bash
# brctl show
bridge name		bridge id			STP enabled		interfaces
docker0			8000.22a0957ddcc0	no				veth66852fa
```

虚拟网卡 `veth66852fa` 通过桥接 `docker0` 。

## 1.2 容器间的通信

默认情况下，同一台宿主机的容器间可以互相通信。可以通过更改 `docker daemon` 的配置实现通信隔离。在Linux上，Docker创建`iptables`和`ip6tables`规则来实现网络隔离、端口发布和过滤。

```bash
--icc 为默认桥接网络启用容器间通信 (默认：true)
# 添加daemon启动参数：dockerd --icc=false 选项可以禁止同一个宿主机的不同容器间通信
```

```bash
# 两个容器之间，可以通过容器IP互相通信
docker run -itd --name centos01 centos:7.9
docker run -itd --name centos02 centos:7.9
```

centos01 容器：

```bash
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0@if31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 3a:05:cf:7a:60:67 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.3/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
# ping 172.17.0.4
PING 172.17.0.4 (172.17.0.4) 56(84) bytes of data.
64 bytes from 172.17.0.4: icmp_seq=1 ttl=64 time=0.747 ms
64 bytes from 172.17.0.4: icmp_seq=2 ttl=64 time=0.076 ms
64 bytes from 172.17.0.4: icmp_seq=3 ttl=64 time=0.095 ms
64 bytes from 172.17.0.4: icmp_seq=4 ttl=64 time=0.078 ms
^C
--- 172.17.0.4 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3050ms
rtt min/avg/max/mdev = 0.076/0.249/0.747/0.287 ms
```

centos02 容器：

```bash
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0@if32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether e6:f4:26:96:62:a1 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.4/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
# ping 172.17.0.3
PING 172.17.0.3 (172.17.0.3) 56(84) bytes of data.
64 bytes from 172.17.0.3: icmp_seq=1 ttl=64 time=0.043 ms
64 bytes from 172.17.0.3: icmp_seq=2 ttl=64 time=0.074 ms
64 bytes from 172.17.0.3: icmp_seq=3 ttl=64 time=0.078 ms
^C
--- 172.17.0.3 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2074ms
rtt min/avg/max/mdev = 0.043/0.065/0.078/0.015 ms
```

# 二、容器名称互联

同一台宿主上的容器，可以通过增加启动参数，实现容器间通过容器ID、容器名互联。通过这种方式，可以避免容器通信写死IP。

## 2.1 实现容器名称互联

通过 `docker run` 指令添加 `--link` 参数，引用容器名，实现容器互联。本质是在容器内 `/etc/hosts` 中添加对应的解析。

```bash
docker run --link <目标通信的容器ID或容器名称>
```

例如：

```bash
docker run -d -it --name centos01 centos:7.9
docker run -d -it --name centos02 --link centos01 centos:7.9
```

centos01 容器：

```bash
# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	47ef7e3b47b4
```

centos02 容器：

```bash
# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	centos01 47ef7e3b47b4
172.17.0.3	e00b6ed47c71
```

centos01 删除重启，IP变成 `172.17.0.4`

```bash
# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.4	21aceb3d1126
```

centos02 容器之前使用 `--link` 参数建立的链接关系已经失效。这是因为 `--link` 是基于容器名称和 ID 的静态链接，如果容器被删除并重新创建，其名称和 ID 可能会发生变化，导致链接失效。

## 2.2 自定义容器别名互联

也可以通过给容器取别名的方式，实现容器互联功能。

```bash
docker run --name <容器名称> --link <目标容器名称>:"<容器别名1>  <容器别名2> ..."
```

例如：

```bash
docker run -d -it --name centos01 centos:7.9
docker run -d -it --name centos02 --link centos01:server1 centos:7.9
```

centos02 容器：

```bash
# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	server1 7865d7af7a5a centos01
172.17.0.3	bb94173545d9
```

## 2.3 容器名称互联总结

`--link` 可以实现容器间基础的通信，但这是单向的，而且受容器生命周期影响。所以该方案已经过时，推荐使用 Docker 自定义网络来实现容器之间的通信。自定义网络更灵活，且不受容器删除和重启的影响。

# 三、网络连接模式

## 3.1 网络模式介绍

Docker 默认情况下存在几个驱动程序，并提供核心网络功能：

- **bridge**：**默认**的网络驱动程序。容器通过 Docker 的虚拟网桥 `docker0` 连接到宿主机网络。
- **host**：容器直接使用**宿主机**的网络栈，与宿主机共享 IP 和端口。性能较好，但端口冲突风险高。
- **none**：容器没有网络接口，只有 `lo` 回环接口。
- **overlay**：用于跨主机的容器通信，通常与 Docker Swarm 或 Kubernetes 结合使用。
- **macvlan**：为容器分配 MAC 地址，使其像物理设备一样接入网络。容器直接与物理网络通信，性能较好。适用于需要容器直接接入物理网络的场景。
- **ipvlan**：多个容器共享一个 MAC 地址，通过不同 IP 地址区分。节省 MAC 地址资源，适合 MAC 地址有限的网络。
- **自定义网络：**可以创建自定义网络，指定子网、网关等参数。灵活配置，支持多种驱动（如 `bridge`、`overlay`）。

使用命令查看Docker默认的网络模式：

```bash
# docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
60ab726d1777   bridge    bridge    local
7795f1590219   host      host      local
b40fff01bd6c   none      null      local
```

## 3.2 Bridge 网络模式

Bridge桥接模式是docker默认的一种网络模式，也是使用最多的一种模式。当启动一个容器后，该容器自动获得IP地址，并通过桥接docker0网卡通过宿主机对外通信。此模式宿主机需要启动`ip_forward`功能。

![image-20250315151059935](./06-Docker%20%E7%BD%91%E7%BB%9C%E7%AE%A1%E7%90%86/image-20250315151059935.png)

查看 bridge 网络信息

```bash
# docker network inspect bridge 
[
    {
        "Name": "bridge",
        "Id": "60ab726d1777e820899fc36a57af7ce65a816d37d6cf6d22dabcded9a692b275",
        "Created": "2025-03-14T02:42:59.304907628Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]
```

可以通过修改 `daemon.json` 配置文件来修改桥接万卡 `docker0` 的网络配置，

例如，修改IP网段和网关，子网的DHCP范围。

```json
{
  "bip": "10.0.0.1/24", 			// 分配docker0网卡的IP,24是容器IP的netmask
  "default-gateway": "10.0.0.254",  // 默认网关
  "dns": ["1.1.1.1","8.8.8.8"] 		// 容器使用的DNS
}
```

添加以上配置，并重启 docker 服务，查看 docker0 网卡配置

```bash
# ip a
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 22:a0:95:7d:dc:c0 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.1/24 brd 10.0.0.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::20a0:95ff:fe7d:dcc0/64 scope link 
       valid_lft forever preferred_lft forever
```

启动容器查看容器IP与dns地址

```bash
# docker run centos:7.9 hostname -i
10.0.0.3
# docker run centos:7.9 cat /etc/resolv.conf | grep -w nameserver
nameserver 1.1.1.1
nameserver 8.8.8.8
```

## 3.3 Host 网络模式

Host模式启动的容器，那么新创建的容器不会创建自己的虚拟网卡，而是直接使用宿主机的网卡和IP地址，因此在容器里面查看到的IP信息就是宿主机的信息，共享宿主机的网络空间。

此模式由于直接使用宿主机的网络无需转换，网络性能最高，但是各容器内使用的端口不能相同，适用于运行容器端口比较固定的业务。

![image-20250317133419745](./06-Docker%20%E7%BD%91%E7%BB%9C%E7%AE%A1%E7%90%86/image-20250317133419745.png)

查看 host 网络信息：

```bash
# docker network inspect host 
[
    {
        "Name": "host",
        "Id": "7795f15902194de95e1ca5bdc1dd757d8718f4a2e9e3ddd3f6dbfa223ae38725",
        "Created": "2025-03-13T14:07:31.823576158Z",
        "Scope": "local",
        "Driver": "host",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": null
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

启动容器查看容器网络信息

```bash
# docker run --network host centos:7.9 ifconfig
docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.0.1  netmask 255.255.255.0  broadcast 10.0.0.255
        inet6 fe80::20a0:95ff:fe7d:dcc0  prefixlen 64  scopeid 0x20<link>
        ether 22:a0:95:7d:dc:c0  txqueuelen 0  (Ethernet)
        RX packets 10439  bytes 430214 (420.1 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 13815  bytes 96220697 (91.7 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.100.13  netmask 255.255.255.0  broadcast 192.168.100.255
        inet6 fe80::20c:29ff:fee6:1dab  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:e6:1d:ab  txqueuelen 1000  (Ethernet)
        RX packets 778826  bytes 1119405058 (1.0 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 93231  bytes 6706280 (6.3 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 522  bytes 60265 (58.8 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 522  bytes 60265 (58.8 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

veth1df07c5: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::c6c:17ff:fe6c:7827  prefixlen 64  scopeid 0x20<link>
        ether 0e:6c:17:6c:78:27  txqueuelen 0  (Ethernet)
        RX packets 3  bytes 126 (126.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 39  bytes 2374 (2.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```



## 3.4 None 网络模式

在使用 none 模式后，Docker 容器不会进行任何网络配置，没有网卡、没有IP也没有路由，仅有本地lo回环网卡，因此默认无法与外界通信，需要手动添加网卡配置IP等，所以极少使用

```bash
# docker network inspect none 
[
    {
        "Name": "none",
        "Id": "b40fff01bd6cf5e4aef55f778280871a91c880c90dea2e65d6d3171c15531ea1",
        "Created": "2025-03-13T14:07:31.819027307Z",
        "Scope": "local",
        "Driver": "null",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": null
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

启动 none 模式的容器，查看网络信息

```bash
# docker run --network none centos:7.9 ifconfig
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

## 3.5 自定义网络

使用docker自定义网络可以自定义的网段地址，网关等信息。

使用 `docker network create` 创建自定义网络：

```bash
# docker network create 
docker: 'docker network create' requires 1 argument

Usage:  docker network create [OPTIONS] NETWORK

Run 'docker network create --help' for more information
root@ubuntu24:~# docker network create --help
Usage:  docker network create [OPTIONS] NETWORK

Create a network

Options:
  -d, --driver string        管理网络的驱动程序 (默认 "bridge")
      --gateway strings      IPv4 or IPv6 主子网的网关
      --subnet strings       表示网段的CIDR格式子网
```

例如：

```bash
docker network create --subnet 172.10.0.0/24 --gateway 172.10.0.1 network01
```

查看网卡列表，新增一个虚拟网卡

```bash
# ifconfig 
br-2c0661a197a8: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.10.0.1  netmask 255.255.255.0  broadcast 172.10.0.255
        inet6 fe80::8c6a:f6ff:fea9:539c  prefixlen 64  scopeid 0x20<link>
        ether 8e:6a:f6:a9:53:9c  txqueuelen 0  (Ethernet)
        RX packets 11  bytes 386 (386.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 9  bytes 922 (922.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

查看网络列表

```bash
# docker network ls
NETWORK ID     NAME        DRIVER    SCOPE
bfc4c0967814   bridge      bridge    local
7795f1590219   host        host      local
2c0661a197a8   network01   bridge    local
b40fff01bd6c   none        null      local
# docker network inspect network01
[
    {
        "Name": "network01",
        "Id": "2c0661a197a8007b3290e1534c2012cf9ad41e30c86342437c427b6701e72b2f",
        "Created": "2025-03-17T06:26:59.405219666Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv4": true,
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.10.0.0/24",
                    "Gateway": "172.10.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

使用自定义网络创建容器：

```bash
docker run -d -it --name server01 --network network01 centos:7.9
docker run -d -it --name server02 --network network01 centos:7.9
```

查看网桥设置，增加了两个虚拟接口

```bash
# brctl show
bridge name			bridge id			STP enabled		interfaces
br-2c0661a197a8		8000.8e6af6a9539c	no				veth5b54a72
														veth936b53e
docker0				8000.22a0957ddcc0	no		
```

查看路由信息

```bash
# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.100.2   0.0.0.0         UG    0      0        0 ens33
10.0.0.0        0.0.0.0         255.255.255.0   U     0      0        0 docker0
172.10.0.0      0.0.0.0         255.255.255.0   U     0      0        0 br-2c0661a197a8
192.168.100.0   0.0.0.0         255.255.255.0   U     0      0        0 ens33
```

查看容器网络信息

```bash
# docker exec server01 ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.10.0.2  netmask 255.255.255.0  broadcast 172.10.0.255
        ether ee:ed:f4:ec:07:90  txqueuelen 0  (Ethernet)
        RX packets 18  bytes 1448 (1.4 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3  bytes 126 (126.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        
# docker exec server02 ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.10.0.3  netmask 255.255.255.0  broadcast 172.10.0.255
        ether ba:e0:d0:65:7d:62  txqueuelen 0  (Ethernet)
        RX packets 11  bytes 866 (866.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3  bytes 126 (126.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

使用容器IP、容器名、容器ID也可以容器间通信：

```bash
# docker exec -it server02 bash 
# ping -c 3 172.10.0.2
PING 172.10.0.2 (172.10.0.2) 56(84) bytes of data.
64 bytes from 172.10.0.2: icmp_seq=1 ttl=64 time=0.095 ms
64 bytes from 172.10.0.2: icmp_seq=2 ttl=64 time=0.082 ms
64 bytes from 172.10.0.2: icmp_seq=3 ttl=64 time=0.086 ms

--- 172.10.0.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2064ms
rtt min/avg/max/mdev = 0.082/0.087/0.095/0.012 ms

# ping -c 3 server01
PING server01 (172.10.0.2) 56(84) bytes of data.
64 bytes from server01.network01 (172.10.0.2): icmp_seq=1 ttl=64 time=0.045 ms
64 bytes from server01.network01 (172.10.0.2): icmp_seq=2 ttl=64 time=0.085 ms
64 bytes from server01.network01 (172.10.0.2): icmp_seq=3 ttl=64 time=0.421 ms

--- server01 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2049ms
rtt min/avg/max/mdev = 0.045/0.183/0.421/0.169 ms

# ping -c 3 773f2514acf3
PING 773f2514acf3 (172.10.0.2) 56(84) bytes of data.
64 bytes from server01.network01 (172.10.0.2): icmp_seq=1 ttl=64 time=0.113 ms
64 bytes from server01.network01 (172.10.0.2): icmp_seq=2 ttl=64 time=0.078 ms
64 bytes from server01.network01 (172.10.0.2): icmp_seq=3 ttl=64 time=0.077 ms

--- 773f2514acf3 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2086ms
rtt min/avg/max/mdev = 0.077/0.089/0.113/0.018 ms
```

## 3.6 实现不同网络互联

默认情况下，不同网络的容器无法通信。如下：

![image-20250317195901887](./06-Docker%20%E7%BD%91%E7%BB%9C%E7%AE%A1%E7%90%86/image-20250317195901887.png)

```bash
# 新创建一个 network02 
docker network create --subnet 172.20.0.0/24 --gateway 172.20.0.1 network02
# 查看网络列表
# docker network ls
NETWORK ID     NAME        DRIVER    SCOPE
bfc4c0967814   bridge      bridge    local
7795f1590219   host        host      local
2c0661a197a8   network01   bridge    local
f51895b1b51b   network02   bridge    local
b40fff01bd6c   none        null      local
```

新创建一个容器，使用 `network02` 网络，发现无法 `ping` 通 `network01` 网络的容器。

```bash
docker run -d -it --name server03 --network network02 centos:7.9
```

```bash
# docker exec -it server03 bash
# ping -c server01
# ping -c 3 172.10.0.2
# ping -c 3 773f2514acf3
```

解决方案：**使用 `docker network connect` 将容器附加到对方网络**

```bash
docker network connect [OPTIONS] NETWORK CONTAINER
```

例如，将`server01`加入`network02`，`server03`加入`network01`

```bash
docker network connect network02 server01
docker network connect network01 server03
```

通过观察，可以发现在容器中多了一张对方网段的网卡和路由，这样可以实现双向通信

```bash
# docker exec server01 ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.10.0.2  netmask 255.255.255.0  broadcast 172.10.0.255
        ether 12:3e:3f:52:d2:5f  txqueuelen 0  (Ethernet)
        RX packets 25  bytes 1854 (1.8 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3  bytes 126 (126.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.20.0.3  netmask 255.255.255.0  broadcast 172.20.0.255
        ether f2:9a:20:ed:ba:c7  txqueuelen 0  (Ethernet)
        RX packets 9  bytes 726 (726.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3  bytes 126 (126.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
# docker exec server03 ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.20.0.2  netmask 255.255.255.0  broadcast 172.20.0.255
        ether ce:f1:70:51:a1:a6  txqueuelen 0  (Ethernet)
        RX packets 26  bytes 2128 (2.0 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 10  bytes 670 (670.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.10.0.4  netmask 255.255.255.0  broadcast 172.10.0.255
        ether 46:63:38:d4:a5:91  txqueuelen 0  (Ethernet)
        RX packets 10  bytes 796 (796.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 3  bytes 126 (126.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 4  bytes 426 (426.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4  bytes 426 (426.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

```bash
# docker exec server03 route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.10.0.1      0.0.0.0         UG    0      0        0 eth1
172.10.0.0      0.0.0.0         255.255.255.0   U     0      0        0 eth1
172.20.0.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0
# docker exec server01 route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.10.0.1      0.0.0.0         UG    0      0        0 eth0
172.10.0.0      0.0.0.0         255.255.255.0   U     0      0        0 eth0
172.20.0.0      0.0.0.0         255.255.255.0   U     0      0        0 eth1
```



# 四、跨宿主机容器间通信

docker单机版并没有提供跨宿主机容器通信的功能，但是可以通过安装网络插件来实现该功能。

> Flannel 是一种基于 overlay 网络的跨主机容器网络解决方案，也就是将 TCP 数据包封装在另一种网络包里面进行路由转发和通信，Flannel 是 CoreOS 开发，专门用于 Docker 多机互联的一个工具，让集群中的不同节点主机创建的容器都具有全集群唯一的虚拟 IP 地址，Flannel 使用 go 语言编写。
>

工作原理：
- Overlay 型网络，即覆盖型网络
- 通过 etcd 保存子网信息及网络分配信息
- 给每台 Docker Host 分配置一个网段
- 通过 UDP 协议传输数据包

![在这里插入图片描述](./06-Docker%20%E7%BD%91%E7%BB%9C%E7%AE%A1%E7%90%86/c69899c94e64139bac6550b8ad0f3115.png)

## 4.1 安装 flannel

| 主机  | IP             | 系统         | 软件          |
| ----- | -------------- | ------------ | ------------- |
| 主机A | 192.168.100.12 | Rocky 8.10   | etcd、flannel |
| 主机B | 192.168.100.13 | Ubuntu 24.04 | flannel       |

- **主机A**

```bash
yum -y install etcd flannel
```
etcd 配置
```bash
# /etc/etcd/etcd.conf 
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
ETCD_NAME="default"
ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"
```
启动 etcd 服务
```bash
systemctl start etcd && systemctl enable etcd
```

flannel 配置

```bash
# /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://192.168.100.12:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
```
在 etcd 中添加网段

```bash
etcdctl mk /atomic.io/network/config '{"Network":"172.20.0.0/16"}'
```
```bash
etcdctl get /atomic.io/network/config
```
启动 flannel 服务

```bash
systemctl start flanneld && systemctl enable flanneld
```

- **主机B**

```bash
apt -y install flannel 
```
flannel 配置

```bash
# /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://192.168.100.12:2379"
FLANNEL_ETCD_PREFIX="/atomic.io/network"
```
启动 flannel 服务

```bash
systemctl start flanneld && systemctl enable flanneld
```

## 4.2 使用 flannel 网络
查看 flannel 的 subnet 信息，每个 flannel 主机的 `FLANNEL_SUBNET` 不一样


```bash
# 192.168.100.12  cat /run/flannel/subnet.env
FLANNEL_NETWORK=172.20.0.0/16
FLANNEL_SUBNET=172.20.24.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=false
```
```bash
# 192.168.100.13  cat /run/flannel/subnet.env
FLANNEL_NETWORK=172.20.0.0/16
FLANNEL_SUBNET=172.20.32.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=false
```

编辑 docker 的配置文件

```json
# 192.168.100.12
{
  "bip": "172.20.24.1/24",
  "mtu": 1472
}
```

```json
# 192.168.100.13
{
  "bip": "172.20.32.1/24",
  "mtu": 1472
}
```
重启 docker

```bash
systemctl restart docker
```
查看 docker0 的 ip 地址

```bash
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.20.24.1  netmask 255.255.255.0  broadcast 172.20.24.255
        ether 02:42:4d:94:cf:f2  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

```bash
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.20.32.1  netmask 255.255.255.0  broadcast 172.20.32.255
        ether 02:42:01:9a:1b:46  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
## 测试容器网络互通

```bash
docker run -it -d --name test centos:latest
```

```bash
docker exec test ping 172.20.24.2
docker exec test ping 172.20.32.2
```

如果不通，则执行以下命令，修改 iptables 规则表
```bash
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
```