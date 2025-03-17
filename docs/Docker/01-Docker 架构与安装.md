# 一、Docker 介绍

## 1.1 Docker 软件架构

Docker 软件使用C/S架构，即客户端/服务端架构。Docker客户端与Docker守护进程通信，后者负责构建、运行和分发Docker容器的繁重工作。客户端与服务端可以在同一台主机上，也可以在不同主机上通过REST API、UNIX套接字或网络接口进行通信。

![Docker Architecture diagram](./01-Docker%20%E6%9E%B6%E6%9E%84%E4%B8%8E%E5%AE%89%E8%A3%85/docker-architecture.webp)

Docker 客户端(Client)：客户端使用 docker 命令或其他工具调用docker API

Docker 主机(Docker Host)：一个物理机或虚拟机，用于运行Docker服务进程和容器，也称为宿主机、Node节点

Docker 服务端(Docker daemon)：Docker服务端守护进程，监听Docker API请求，管理容器、镜像、网络、数据卷功能。

Docker 容器(Container)：容器是从镜像生成对外提供服务的一个或一组服务，其本质就是将镜像中的程序启动后生成的进程

Docker 仓库(Registry)：保存镜像的仓库，官方仓库:  https://hub.docker.com/，也可以搭建私有仓库 harbor

Docker 镜像(Images):  镜像可以理解为创建实例使用的模板，本质上就是一些程序文件的集合

## 1.2 Docker 底层技术

Docker 是用Go语言编写的，利用Linux内核的几个特性来提供其功能。Docker使用一种名为名称空间的技术来提供容器的隔离工作，

每个容器拥有独立的命名空间及其权限；并使用Cgroup技术实现资源的分配，为每个容器分配资源。

- Namespace

  ![image-20250303223514711](./01-Docker%20%E6%9E%B6%E6%9E%84%E4%B8%8E%E5%AE%89%E8%A3%85/image-20250303223513271.png)

  名称空间，[Linux 内核](https://man7.org/linux/man-pages/man7/namespaces.7.html)中的一项技术。由于Docker 容器共享宿主机内核，为了各个容器之间隔离，需要使用Namespace技术为每个容器创建独自的命名空间，做到类似于虚拟机的隔离功能。

  | 隔离类型       | 功能                           | 解释                                                         | 内核版本 |
  | -------------- | ------------------------------ | ------------------------------------------------------------ | -------- |
  | MNT Namespace  | 磁盘挂载点和文件系统的隔离能力 | 允许不同namespace 的进程看到的文件结构不同，这样每个namespace 中的进 程所看到的文件目录就被隔离开了 | 2.4.19   |
  | IPC Namespace  | 提供进程间通信的隔离能力       | Container 中进程交互还是采用 linux 常见的进程间交互方法，包括常见的信号量、消息队列和共享内存。 | 2.6.19   |
  | UTS Namespace  | 提供内核、主机名、域名隔离能力 | 允许每个container 拥有独立的hostname 和 domain name, 使其在网络上可以被视作一个独立的节点而非Host 上的一个进程。 | 2.6.19   |
  | PID Namespace  | 进程隔离                       | 不同用户的进程就是通过Pid Namespaceamespace 隔离开的，且不同namespace 中可以有相同Pid。 | 2.6.24   |
  | Net Namespace  | 提供网络隔离能力               | 每个net namespace 有独立的network devices, IP  addresses, IP routing tables, /proc/net 目录。 | 2.6.29   |
  | User Namespace | 提供用户/用户组隔离能力        | 每个container 可以有不同的user 和group id, 也就是说可以在container 内部用container 内部的 用户执行程序而非Host 上的用户。 | 3.8      |

- CGroup

  CGroup的全程为 Linux Control Group，也是内核中的一个功能，在内核层默认已经开启。CGroup最主要的一个功能就是可以限制一个进程使用的资源上限，包括CPU、内存、磁盘、网络带宽等。

  使用CGroup就可以限制容器的资源上限，防止因容器内部程序异常将宿主机资源占完。

## 1.3 Docker 与 Podman

Podman即Pod Manager tool，是一个为 Kubernetes 而生的开源的容器管理工具，原来是 CRI-O（即容器运行时接口CRI 和开放容器计划OCI）项目的一部分，后来被分离成一个单独的项目叫 libpod。其可在大多数Linux平台 上使用，它是一种**无守护程序**的容器引擎，用于在Linux系统上开发，管理和运行任何符合Open  Container Initiative（OCI）标准的容器和容器镜像。

Podman 提供了一个与 Docker 兼容的命令行前端，Podman 里面87%的指令都和Docker CLI 相同，因 此可以简单地为Docker CLI别名。

 Podman 和docker不同之处：

- docker 需要在系统上运行一个守护进程(docker daemon)，这会产生一定的开销；而 podman 不 需要。

- 启动容器的方式不同: docker cli 命令通过API跟 docker Engine 才会调用 Docker Engine(引擎) 交互告诉它我想创建一个container，然后 container 的 process(进程)不会是 OCI container runtime(runc) 来启动一个container。这代表 Docker CLI 的 child process(子进程)，而是 Engine 的 child process 。

  Podman 是直接给 OCI containner runtime(runc) 进行交互来创建container的，所以 container process 直接是podman的child process 。

- 因为docke有docker daemon，所以docker启动的容器支持--restart 策略，但是podman不支持

- docker需要使用root用户来创建容器。 这可能会产生安全风险，尤其是当用户知道docker run命令的--privileged选项时。podman既可以由root用户运行，也可以由非特权用户运行。

## 1.4 容器相关技术

为了保证容器生态的标准性和健康可持续发展，包括Linux 基金会、Docker、微软、红帽、谷歌和IBM 等公司在2015年6月共同成立了一个叫Open Container Initiative（OCI）的组织，其目的就是制定开放的标准的容器规范。

目前OCI一共发布了两个规范，分别是 **runtime spec** 和 **image format spec**，有了这两个规范，不同的容器公司开发的容器只要兼容这两个规范，就可以保证容器的可移植性和相互可操作性。

- Container Runtime 容器运行时

  runtime 是真正运行容器的地方，因此为了运行不同的容器runtime需要和操作系统内核紧密合作相互在支持，以便为容器提供相应的运行环境，对于容器运行时主要有两个级别：Low Level(使用接近内核层) 和 High Level(使用接近用户层)目前，市面上常用的容器引擎有很多，主要有下图的那几种：

  ![img](./01-Docker%20%E6%9E%B6%E6%9E%84%E4%B8%8E%E5%AE%89%E8%A3%85/06fde9d32b8e2215efc709e2107ae4ae9da313.png)

  **runc**：早期libcontainer是Docker公司控制的一个开源项目，OCI的成立后，Docker把libcontainer 项目移交给了OCI组织，runc就是在libcontainer的基础上进化而来，是目前Docker默认的runtime，runc遵守OCI规范。

  **lxc**：linux上早期的runtime，在 2013 年 Docker 刚发布的时候，就是采用lxc作为runtime, Docker 把 LXC 复杂的容器创建与使用方式简化为 Docker 自己的一套命令体系。随着Docker的发展，原有的LXC不能满足Docker的需求，比如跨平台功能。

  **rkt**:  是CoreOS开发的容器runtime，也符合OCI规范，所以使用rkt runtime也可以运行Docker容 器



## 1.5 Docker 的运行机制

![image-20250304200242880](./01-Docker%20%E6%9E%B6%E6%9E%84%E4%B8%8E%E5%AE%89%E8%A3%85/image-20250304200242880.png)



# 二、Docker 安装

## 2.1 Rocky 系统安装

Rocky 8.10/9.5 安装docker 命令：

```bash
# 将阿里云仓库添加到YUM源:
curl https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
# 更新yum源
dnf clean all && dnf makecache
```

安装 docker-ce 最新版

```bash
# 安装最新版docker
dnf install -y docker-ce
# 启用dockerd服务
systemctl enable --now docker
```

安装 docker-ce 指定版本

```bash
# 列出可用版本
dnf list docker-ce --showduplicates | sort -r
# 选择所需版本并安装：
VERSION_STRING=26.1.2-1.el8
dnf install -y docker-ce-$VERSION_STRING docker-ce-cli-$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
# 启用dockerd服务
systemctl enable --now docker
```

卸载旧版本

```bash
# 卸载Docker Engine、CLI、containerd和Docker Compose软件包：
dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
# 删除主机上的镜像、容器、卷或自定义配置文件：
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
```

## 2.2 Ubuntu 系统安装

Ubuntu 20.04/22.04/24.04 安装docker 命令：

```bash
# 添加Docker的官方GPG密钥:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 将阿里云仓库添加到Apt源:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新Apt源
sudo apt-get update
```

安装 docker-ce 最新版

```bash
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

安装 docker-ce 指定版本

```bash
# 列出可用版本：
apt-cache madison docker-ce | awk '{ print $3 }'
# 选择所需版本并安装：
VERSION_STRING=5:28.0.1-1~ubuntu.24.04~noble
sudo apt-get -y install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
```

卸载旧版本

```bash
# 卸载Docker Engine、CLI、containerd和Docker Compose软件包：
sudo apt-get -y purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
# 删除主机上的镜像、容器、卷或自定义配置文件：
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
# 删除apt源文件和密钥
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.asc
```

## 2.3 CentOS 系统安装

CentOS 7.9 安装docker 命令：

```bash
# 将阿里云仓库添加到YUM源:
curl https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
# 更新yum源
yum clean all && yum makecache
```

安装 docker-ce 最新版

```bash
# 安装最新版docker
yum install -y docker-ce
# 启用dockerd服务
systemctl enable --now docker
```

安装 docker-ce 指定版本

```bash
# 列出可用版本
yum list docker-ce --showduplicates | sort -r
# 选择所需版本并安装：
VERSION_STRING=20.10.21-3.el7
yum install -y docker-ce-$VERSION_STRING docker-ce-cli-$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
# 启用dockerd服务
systemctl enable --now docker
```

卸载旧版本

```bash
# 卸载Docker Engine、CLI、containerd和Docker Compose软件包：
yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
# 删除主机上的镜像、容器、卷或自定义配置文件：
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
```

## 2.4 二进制离线安装

使用编译后的二进制可执行程序安装，适用于无法上网或无法通过包安装方式安装的主机上安装docker。

官方地址：https://download.docker.com/linux/static/stable/

阿里云地址：https://mirrors.aliyun.com/docker-ce/linux/static/stable/x86_64/

```bash
# 将 tgz 包下载到主机上
wget https://mirrors.aliyun.com/docker-ce/linux/static/stable/x86_64/docker-28.0.1.tgz
# 解压包
tar -xvf docker-28.0.1.tgz
# 将二进制程序放到bin目录
cp docker/* /usr/bin/

# 编写 systemd 守护进程文件
cat > /lib/systemd/system/docker.service << EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd -H unix://var/run/docker.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutStartSec=0
RestartSec=2
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

# 载入配置
systemctl daemon-reload
# 启动docker
systemctl enable --now docker
```

# 三、Docker 基本配置

Docker 的配置又两种方式，一种是在 dockerd 启动程序后面追加启动参数，另一种是指定配置文件。Docker 的配置文件默认路径 `/etc/docker/daemon.json`，需要自己创建。完整配置文件内容如下：

```json
{
  "authorization-plugins": [],
  "bip": "",
  "bip6": "",
  "bridge": "",
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "10GB",
      "policy": [
        { "keepStorage": "10GB", "filter": ["unused-for=2200h"] },
        { "keepStorage": "50GB", "filter": ["unused-for=3300h"] },
        { "keepStorage": "100GB", "all": true }
      ]
    }
  },
  "cgroup-parent": "",
  "containerd": "/run/containerd/containerd.sock",
  "containerd-namespace": "docker",
  "containerd-plugins-namespace": "docker-plugins",
  "data-root": "",
  "debug": true,
  "default-address-pools": [
    {
      "base": "172.30.0.0/16",
      "size": 24
    },
    {
      "base": "172.31.0.0/16",
      "size": 24
    }
  ],
  "default-cgroupns-mode": "private",
  "default-gateway": "",
  "default-gateway-v6": "",
  "default-network-opts": {},
  "default-runtime": "runc",
  "default-shm-size": "64M",
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  },
  "dns": [],
  "dns-opts": [],
  "dns-search": [],
  "exec-opts": [],
  "exec-root": "",
  "experimental": false,
  "features": {
    "cdi": true,
    "containerd-snapshotter": true
  },
  "fixed-cidr": "",
  "fixed-cidr-v6": "",
  "group": "",
  "host-gateway-ip": "",
  "hosts": [],
  "proxies": {
    "http-proxy": "http://proxy.example.com:80",
    "https-proxy": "https://proxy.example.com:443",
    "no-proxy": "*.test.example.com,.example.org"
  },
  "icc": false,
  "init": false,
  "init-path": "/usr/libexec/docker-init",
  "insecure-registries": [],
  "ip": "0.0.0.0",
  "ip-forward": false,
  "ip-masq": false,
  "iptables": false,
  "ip6tables": false,
  "ipv6": false,
  "labels": [],
  "live-restore": true,
  "log-driver": "json-file",
  "log-format": "text",
  "log-level": "",
  "log-opts": {
    "cache-disabled": "false",
    "cache-max-file": "5",
    "cache-max-size": "20m",
    "cache-compress": "true",
    "env": "os,customer",
    "labels": "somelabel",
    "max-file": "5",
    "max-size": "10m"
  },
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 5,
  "max-download-attempts": 5,
  "mtu": 0,
  "no-new-privileges": false,
  "node-generic-resources": [
    "NVIDIA-GPU=UUID1",
    "NVIDIA-GPU=UUID2"
  ],
  "pidfile": "",
  "raw-logs": false,
  "registry-mirrors": [],
  "runtimes": {
    "cc-runtime": {
      "path": "/usr/bin/cc-runtime"
    },
    "custom": {
      "path": "/usr/local/bin/my-runc-replacement",
      "runtimeArgs": [
        "--debug"
      ]
    }
  },
  "seccomp-profile": "",
  "selinux-enabled": false,
  "shutdown-timeout": 15,
  "storage-driver": "",
  "storage-opts": [],
  "swarm-default-advertise-addr": "",
  "tls": true,
  "tlscacert": "",
  "tlscert": "",
  "tlskey": "",
  "tlsverify": true,
  "userland-proxy": false,
  "userland-proxy-path": "/usr/libexec/docker-proxy",
  "userns-remap": ""
}
```

## 3.1 配置镜像加速器

新安装的 docker 拉取镜像默认使用的镜像仓库是官方：https://registry-1.docker.io/v2/。

国内环境已经无法访问该地址了，会报错误：`docker: Error response from daemon: Get "https://registry-1.docker.io/v2/": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)`。

为了能够正常拉取镜像，需要配置一些国内的镜像加速器，配置文件添加以下配置，加速器地址可以配置多个（目前网上免费的加速网址越来越少了，我这里用的是华为云提供的）：

```json
{
    "registry-mirrors": [
        "https://bcfc90e243c74121b46a3bb4a05d160a.mirror.swr.myhuaweicloud.com"
    ]
}
```

重启 docker 服务器

```bash
systemctl restart docker
```

使用 `docker info` 命令可以查看配置的镜像加速器地址：

```bash
 Registry Mirrors:
  https://bcfc90e243c74121b46a3bb4a05d160a.mirror.swr.myhuaweicloud.com
```

## 3.2 开启 daemon 远程监听

如果docker cli 客户端与daemon服务端不在同一主机，可以开启daemon的监听功能，客户端与服务端远程通信。

```bash
# 编辑docker.service文件，ExecStart追加 -H tcp://127.0.0.1:2375
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2375

# 或者daemon.json文件添加
{
  "hosts": ["unix://var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
```

重启 docker 服务器

```bash
systemctl daemon-reload
systemctl restart docker
```

远程客户端连接命令：

```bash
docker -H 192.168.100.14 images
```

该方法无法做认证，任何客户端都可以从监听的地址和端口连上服务端，并不安全。

## 3.3 添加可信的私有仓库

**insecure-registries** 允许用户指定一个或多个不安全的镜像仓库地址。这些仓库不使用HTTPS进行通信，因此不需要SSL证书验证。

```json
{
    "insecure-registries": ["harbor.domain.io"]
}
```

重启 docker 服务器

```bash
systemctl restart docker
```

## 3.4 修改 docker 的数据目录

docker 的默认目录为 : `/var/lib/docker`，如果想修改到指定目录，则添加以下配置：

```json
{
    "data-root": "/data/docker"
}
```

如果有数据，可以将原docker目录移到新位置。

重启 docker 服务器

```bash
systemctl restart docker
```

## 3.5 容器日志配置

通过修改配置可以控制每个容器的输出日志大小，防止撑爆磁盘：

- json-file：日志被格式化为JSON。也是Docker的默认日志记录驱动程序。其他driver类型见[官网](https://docs.docker.com/engine/logging/configure/#supported-logging-drivers)

- max-size：指定容器日志文件的最大值
- max-file：指定容器日志文件的个数，循环写入日志文件

```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "30m",
        "max-file": "3"
    }
}
```

重启 docker 服务器

```bash
systemctl restart docker
```

## 3.6 daemon重启不影响容器

默认情况下，当Docker守护进程终止时，它会关闭所有正在运行的容器。

可以配置守护进程，以便在守护进程不可用时容器保持运行。此功能称为 Live restore。

Live restore功能有助于减少由于守护进程崩溃、计划停机或升级而导致的容器停机时间。

```json
{
  "live-restore": true
}
```

重启 docker 服务器

```bash
systemctl restart docker
```

## 3.7  配置代理

通过配置网络代理，同样可以拉取国内无法访问的镜像。（前提是得有一个代理提供商 :D）

```json
{
    "proxies": {
        "default": {
            "httpProxy": "http://proxy.example.com:3128",
            "httpsProxy": "https://proxy.example.com:3129",
            "noProxy": "*.test.example.com,.example.org,127.0.0.0/8"
        },
        "tcp://docker-daemon1.example.com": {
            "noProxy": "*.internal.example.net"
        }
    }
}
```

重启 docker 服务器

```bash
systemctl restart docker
```
