# 一、容器介绍

容器的生命周期示意图：

![image-20250306101919432](./02-Docker%20%E5%AE%B9%E5%99%A8%E6%93%8D%E4%BD%9C/image-20250306101919432.png)

# 二、容器启动操作

## 2.1 启动容器

`docker run` 可以启动容器，进入到容器，并随机生成容器ID和名称。

容器启动需要镜像，如果本地没有，则会自动联网下载镜像后启动。

```bash
Usage:  docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

运行一个 nginx 容器

```bash
# docker run nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/03/06 02:37:25 [notice] 1#1: using the "epoll" event method
2025/03/06 02:37:25 [notice] 1#1: nginx/1.27.4
2025/03/06 02:37:25 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/03/06 02:37:25 [notice] 1#1: OS: Linux 5.14.0-503.14.1.el9_5.x86_64
2025/03/06 02:37:25 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1073741816:1073741816
2025/03/06 02:37:25 [notice] 1#1: start worker processes
2025/03/06 02:37:25 [notice] 1#1: start worker process 28
2025/03/06 02:37:25 [notice] 1#1: start worker process 29
```

按组合键 ctrl + c 退出运行的容器，查看已经停止的容器

```bash
# docker ps -a 
CONTAINER ID   IMAGE     COMMAND                   CREATED         STATUS                     PORTS     NAMES
3583649920bc   nginx     "/docker-entrypoint.…"   3 minutes ago   Exited (0) 3 minutes ago             condescending_joliot
```

## 2.2 一次性使用容器

某些场景下，我想使用容器中提供的工具或命令完成某些需求，通常用于执行特定任务后退出。

例如，使用mysql dump做周期性的数据备份。

```bash
docker run --rm mysql mysqldump -h <host> -u <user> -p<password> <database> > backup.sql
```

例如，使用 python 容器运行py脚本

```bash
docker run --rm python:3.9 python test.py
```

例如，使用 gcc 或 maven 编辑源码

```bash
docker run --rm -v $(pwd):/app -w /app maven:3.8.4 mvn clean install
```

- **`--rm` 选项**：容器退出后自动删除，避免占用资源。
- **`-v` 选项**：挂载本地目录到容器内，方便文件操作。
- **`-w` 选项**：指定容器内的工作目录。

## 2.3 后台运行容器

大部分的容器为应用容器，例如web、mysql这种需要持续守护运行的，如果在终端持续运行会占用一个前台终端，所以在容器启动时，需要添加参数 `-d` 让容器后台运行。

```bash
-d, --detach 	在后台运行容器并输出容器ID
```

例如，运行一个redis/nginx/hello-world容器，`--name` 指定容器的名称

```bash
docker run --name redis -d redis:latest
docker run --name nginx -d nginx:latest
docker run --name hello -d hello-world:latest
```

查看容器列表

```bash
# docker ps -a
CONTAINER ID   IMAGE                COMMAND                   CREATED              STATUS                      PORTS      NAMES
b520a183abe7   hello-world:latest   "/hello"                  13 seconds ago       Exited (0) 12 seconds ago              hello
4bbd2005b5a8   nginx:latest         "/docker-entrypoint.…"   About a minute ago   Up About a minute           80/tcp     nginx
f7d92b67ab36   redis:latest         "docker-entrypoint.s…"   2 minutes ago        Up 2 minutes                6379/tcp   redis
```

这里看到redis、nginx容器已经在后台运行了，而hello即使加了 `-d` 参数，也退出了。这是因为这两个容器的 COMMAND 为可持续运行的进程，而hello容器的 `/hello` 脚本为一次性运行，运行结束，则该容器没有持续性进程了。

所以想要后台运行，也需要容器内有可持续运行的进程存在才可以，可以在 COMMAND 处添加一个命令。

```bash
docker run -d --name centos centos:latest bash -c "while true; do echo '1'; sleep 3; done"
```

查看运行中的容器，`-l` 参数显示最新创建的容器：

```bash
# docker ps -l
CONTAINER ID   IMAGE           COMMAND                   CREATED          STATUS          PORTS     NAMES
f2315976bdae   centos:latest   "bash -c 'while true…"   39 seconds ago   Up 38 seconds             centos
```

## 2.4 给容器分配终端

如果想后台持续运行一个容器，但是该容器没有可持续运行的进程，我们可以给它分配一个可交互的终端，让它带着这个终端在后台运行即可。

```bash
-i, --interactive		即使未连接，也保持STDIN打开
-t, --tty               分配伪TTY
```

一般这两个选项会写在一起：`-it`

```bash
docker run -d -it --name centos centos:latest
```

查看运行中的容器

```bash
# docker ps 
CONTAINER ID   IMAGE           COMMAND       CREATED          STATUS          PORTS     NAMES
a8b1b5ce4414   centos:latest   "/bin/bash"   45 seconds ago   Up 45 seconds             centos
```

如果不加 `-d` 选项，则在当前终端分配伪终端，`-h` 参数可以为容器设置主机名：

```bash
[root@localhost ~]# docker run -it -h centos01 --name centos centos:latest bash
[root@centos01 /]# hostname
centos01
[root@centos01 /]# cat /etc/hosts 
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::	ip6-localnet
ff00::	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.2	centos01
[root@centos01 /]# exit
exit
```

终端退出，容器也就退出了

```bash
# docker ps -a
CONTAINER ID   IMAGE           COMMAND   CREATED         STATUS                      PORTS     NAMES
a52ff2759a5a   centos:latest   "bash"    2 minutes ago   Exited (0) 34 seconds ago             centos
```

想要不退出，可以使用 `ctrl + p q` 组合键。

## 2.5 容器自动重启

使用`--restart`选项可以指定容器的重启策略。此功能可以保证容器开机自启，并在异常退出后可以自动重启恢复。

```bash
--restart string	容器退出时应用的重新启动策略 (默认 "no")
```

重启策略控制Docker守护进程在退出后是否重启容器。Docker支持以下重启策略：

-  no：不要自动重启容器。（默认）
- on-failure[:max-retries]：如果容器因错误而退出，则重新启动容器，该错误表现为非零退出代码。或者，使用：`max-retries`选项限制Docker守护进程尝试重启容器的次数。只有当容器失败退出时，on-failure策略才会提示重新启动。如果守护进程重新启动，它不会重新启动容器。
- always：如果容器停止，则会自动重启。如果容器被手动停止，它只有在Docker守护进程重启或容器本身被手动重启时才会重启。
- unless-stopped：类似于always，除了当容器停止时（手动或其他方式），即使在Docker守护进程重新启动后，它也不会重新启动。

例如，设置redis容器总是自动重启

```bash
docker run -d --restart=always redis
```

例如，设置redis容器异常退出重启，最大重试次数10次

```bash
docker run -d --restart=on-failure:10 redis
```

## 2.6 特权容器

默认启动的容器里拥有root用户，但是该root用户并不是真正的root权限，无法使用类似system的高权限指令。

如果想要容器内提权，需要运行容器时添加`--privileged`参数，提供以下功能：

- 启用所有Linux内核功能
- 禁用默认的seccomp配置文件
- 禁用默认AppArmor配置文件
- 禁用SELinux进程标签
- 授予对所有主机设备的访问权限
- Makes/sys读写
- 使cgroups挂载读写

通过添加 `--privileged`参数，容器可以做几乎所有主机可以做的事情。比如在Docker中再运行Docker（Docker in Docker）。

```bash
docker run -d -it --privileged --name centos centos:latest
```

## 2.7 暴露容器端口

容器启动后，默认处于预定义的NAT网络中，所以外部网络的主机无法直接访问容器中网络服务。

```bash
-p, --publish list 		将容器的端口映射到主机
-P, --publish-all 		将所有公开的端口发布到随机端口
```

使用 `-P` 参数可以将事先容器预定义的所有端口映射宿主机的网卡的随机端口。

默认从32768开始使用随机端口时，当停止容器后再启动可能会导致端口发生变化。

例如，暴露 nginx 容器的所有端口：

```bash
docker run -d -P --name nginx nginx:latest
```

使用 `docker port` 命令查看映射的端口关系：

```bash
# docker port nginx 
80/tcp -> 0.0.0.0:32768
80/tcp -> [::]:32768
```

使用 `-p` 参数可以指定主机的端口映射到容器端口。

例如，暴露 docker 文档容器的4000端口：

```bash
docker run -d -p 4000:4000 docs/docker.github.io:latest
```

例如，将 1000-1010范围的端口全部映射：

```bash
docker run -d -it --name centos -p 1000-1010:1000-1010 centos:latest
```

查看映射的端口

```bash
# docker ps -l
CONTAINER ID   IMAGE           COMMAND       CREATED          STATUS          PORTS                                                             NAMES
fc2252cc14fc   centos:latest   "/bin/bash"   11 seconds ago   Up 11 seconds   0.0.0.0:1000-1010->1000-1010/tcp, [::]:1000-1010->1000-1010/tcp   centos
# docker port centos 
1000/tcp -> 0.0.0.0:1000
1000/tcp -> [::]:1000
1001/tcp -> 0.0.0.0:1001
1001/tcp -> [::]:1001
1002/tcp -> 0.0.0.0:1002
1002/tcp -> [::]:1002
1003/tcp -> 0.0.0.0:1003
1003/tcp -> [::]:1003
1004/tcp -> 0.0.0.0:1004
1004/tcp -> [::]:1004
1005/tcp -> 0.0.0.0:1005
1005/tcp -> [::]:1005
1006/tcp -> 0.0.0.0:1006
1006/tcp -> [::]:1006
1007/tcp -> 0.0.0.0:1007
1007/tcp -> [::]:1007
1008/tcp -> 0.0.0.0:1008
1008/tcp -> [::]:1008
1009/tcp -> 0.0.0.0:1009
1009/tcp -> [::]:1009
1010/tcp -> 0.0.0.0:1010
1010/tcp -> [::]:1010
```

## 2.8 传递环境变量

有些容器运行时，需要传递变量，可以使用 `-e <参数>` 或 `--env-file <参数文件>` 实现：

```bash
-e, --env list 			设置环境变量
	--env-file list 	读入环境变量文件
```

例如，启动一个MySQL容器，使用环境变量设置密码与创建数据库：

```bash
docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=123456Aa. -e MYSQL_DATABASE=docker mysql:latest 
```

## 2.9 指定容器DNS

容器的dns服务器，默认采用宿主机的dns地址，可以用`--dns`方式指定它的DNS地址：

```bash
--dns list 		设置自定义DNS服务器
```

例如，设置容器的DNS地址，查看对比结果
```bash
[root@localhost ~]# docker run --rm centos bash -c "cat /etc/resolv.conf"
nameserver 114.114.114.114

[root@localhost ~]# docker run --rm --dns 1.1.1.1 --dns 8.8.8.8  centos bash -c "cat /etc/resolv.conf"
nameserver 1.1.1.1
nameserver 8.8.8.8
```

# 三、查看容器信息

## 3.1 查看容器列表

使用 `docker ps` 指令可查看容器列表：

```bash
Usage:  docker ps [OPTIONS]
Options:
  -a, --all             显示所有容器 (默认仅显示运行中的)
  -f, --filter filter   根据提供的条件过滤输出
      --format string   使用自定义模板设置输出格式:
                        'table':            以带有列标题的表格格式打印输出 (默认)
                        'table TEMPLATE':   使用给定的Go模板以表格格式打印输出
                        'json':             以JSON格式打印
                        'TEMPLATE':         使用给定的Go模板打印输出。
  -n, --last int        显示n个上次创建的容器
  -l, --latest          显示最近创建的容器
      --no-trunc        不要截断输出
  -q, --quiet           仅显示容器ID
  -s, --size            显示总文件大小
```

```bash
# 以下是一些format常用的占位符：
{{.ID}}：容器的ID。
{{.Image}}：容器使用的映像名称。
{{.Command}}：容器的启动命令。
{{.CreatedAt}}：容器的创建时间。
{{.RunningFor}}：容器运行的时间。
{{.Ports}}：容器的端口映射信息。
{{.Status}}：容器的状态。
{{.Size}}：容器的大小。
{{.Names}}：容器的名称。
{{.Label}}：容器的标签。
```

例如，查看所有状态的容器

```bash
docker ps -a
```

例如，按照占位符输出格式

```bash
docker ps --format "{{.ID}}\t{{.Image}}\t{{.Status}}"
```

例如，筛选出退出状态的容器

```bash
docker ps -f 'status=exited'
```

例如，使用组合命令删除退出状态的容器

```bash
docker rm $(docker ps -q -f 'status=exited')
```

## 3.2 查看容器内的进程

使用 `docker top` 指令可以查看容器内的进程

```bash
docker top nginx
```

## 3.3 查看容器资源使用

使用 `docker stat` 指令可以持续查看容器的资源使用情况

```bash
Usage:  docker stats [OPTIONS] [CONTAINER...]
Options:
  -a, --all             显示所有容器 (默认仅显示运行中的)
      --format string   使用自定义模板设置输出格式:
                        'table':            以带有列标题的表格格式打印输出 (默认)
                        'table TEMPLATE':   使用给定的Go模板以表格格式打印输出
                        'json':             以JSON格式打印
                        'TEMPLATE':         使用给定的Go模板打印输出。
      --no-stream       禁用流统计数据并仅提取第一个结果
      --no-trunc        不截断输出
```

查看容器的资源使用情况

```bash
# docker stats --no-stream cranky_newton 
CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT     MEM %     NET I/O         BLOCK I/O     PIDS
40a7d90e4bf9   cranky_newton   0.39%     21.62MiB / 3.541GiB   0.60%     1.58kB / 126B   28.1MB / 0B   6
```

## 3.4 查看容器的详细信息

使用 `docker inspect` 指令可以查看容器的详细信息：

```bash
Usage:  docker inspect [OPTIONS] NAME|ID [NAME|ID...]
Options:
  -f, --format string   使用自定义模板设置输出格式:
                        'json':             以JSON格式打印
                        'TEMPLATE':         使用给定的Go模板打印输出。
  -s, --size            如果类型为容器，则显示总文件大小
      --type string     返回指定类型的JSON

```

例如，查看某个容器的详细信息：

```bash
# docker inspect cranky_newton
[
    {
        "Id": "40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735",
        "Created": "2025-03-06T08:59:20.385707161Z",
        "Path": "docker-entrypoint.sh",
        "Args": [
            "redis-server"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 2571,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2025-03-06T08:59:20.424815174Z",
            "FinishedAt": "0001-01-01T00:00:00Z"
        },
        "Image": "sha256:43724892d6db0fd681c7309bd458ce636c637a027f2d203a4932668ba8ffd97c",
        "ResolvConfPath": "/data/docker/containers/40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735/resolv.conf",
        "HostnamePath": "/data/docker/containers/40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735/hostname",
        "HostsPath": "/data/docker/containers/40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735/hosts",
        "LogPath": "/data/docker/containers/40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735/40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735-json.log",
        "Name": "/cranky_newton",
        "RestartCount": 0,
        "Driver": "overlay2",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": null,
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "json-file",
                "Config": {
                    "max-file": "3",
                    "max-size": "30m"
                }
            },
            "NetworkMode": "bridge",
            "PortBindings": {},
            "RestartPolicy": {
                "Name": "no",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "ConsoleSize": [
                47,
                187
            ],
            "CapAdd": null,
            "CapDrop": null,
            "CgroupnsMode": "private",
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": [],
            "BlkioDeviceWriteBps": [],
            "BlkioDeviceReadIOps": [],
            "BlkioDeviceWriteIOps": [],
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": null,
            "PidsLimit": null,
            "Ulimits": [],
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware",
                "/sys/devices/virtual/powercap"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": {
                "ID": "40a7d90e4bf95a37b9d1240fb131c5978f040fca06bc5b86b17c7052ca883735",
                "LowerDir": "/data/docker/overlay2/8b6cbfb22d990e009c02849d1e1d40182cbef3f9dc2d082ef761a2e945e98856-init/diff:/data/docker/overlay2/1472a6b760ca9d0dc313f4c2d5e5375996926873d96b899b4874c33f952ce054/diff:/data/docker/overlay2/d9a05201c4261616827d1b655f12cb741dd847b72245e02570d9a4455834bc2b/diff:/data/docker/overlay2/48ff0e56dab444b3a0b4db0c065ba411ededee4e55ffa194efebf8a1ff690e05/diff:/data/docker/overlay2/1b89021d53edabc76852e63718f1a22bc2a88fefe21b558dbab33d6e00cc7211/diff:/data/docker/overlay2/833edfaa4cbcbcc58345f28cfa15e19776818d9ef6c6bd39ece81f8f235c18ea/diff:/data/docker/overlay2/c410c846ccaf8af9a500f3d3446fa0dada326f757092fe3a45d20db996b7f12d/diff:/data/docker/overlay2/7638fd950f2e36150e327410f83eff678ed973366ebe868a071ea7fa7327dc58/diff:/data/docker/overlay2/b1b2e8898bdd8864ade30bd1dd5ce27f7eefc54adb216c13d4f54c7065a69195/diff",
                "MergedDir": "/data/docker/overlay2/8b6cbfb22d990e009c02849d1e1d40182cbef3f9dc2d082ef761a2e945e98856/merged",
                "UpperDir": "/data/docker/overlay2/8b6cbfb22d990e009c02849d1e1d40182cbef3f9dc2d082ef761a2e945e98856/diff",
                "WorkDir": "/data/docker/overlay2/8b6cbfb22d990e009c02849d1e1d40182cbef3f9dc2d082ef761a2e945e98856/work"
            },
            "Name": "overlay2"
        },
        "Mounts": [
            {
                "Type": "volume",
                "Name": "c9aae372f9187edfcbdd81f3addb0c5da8ff7efb48ab230989411eb5e5573909",
                "Source": "/data/docker/volumes/c9aae372f9187edfcbdd81f3addb0c5da8ff7efb48ab230989411eb5e5573909/_data",
                "Destination": "/data",
                "Driver": "local",
                "Mode": "",
                "RW": true,
                "Propagation": ""
            }
        ],
        "Config": {
            "Hostname": "40a7d90e4bf9",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "6379/tcp": {}
            },
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "GOSU_VERSION=1.17",
                "REDIS_VERSION=7.4.2",
                "REDIS_DOWNLOAD_URL=http://download.redis.io/releases/redis-7.4.2.tar.gz",
                "REDIS_DOWNLOAD_SHA=4ddebbf09061cbb589011786febdb34f29767dd7f89dbe712d2b68e808af6a1f"
            ],
            "Cmd": [
                "redis-server"
            ],
            "Image": "redis:latest",
            "Volumes": {
                "/data": {}
            },
            "WorkingDir": "/data",
            "Entrypoint": [
                "docker-entrypoint.sh"
            ],
            "OnBuild": null,
            "Labels": {}
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "8402bdadcfecc24666e013da8eec80056269fe93aeb344c180bf6377634931ce",
            "SandboxKey": "/var/run/docker/netns/8402bdadcfec",
            "Ports": {
                "6379/tcp": null
            },
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "0b162e9cacc3a4b0d47cd1dced8dfcaae1cf46676b7408162f1a948777c7798f",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "9e:0a:c4:2c:86:50",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "MacAddress": "9e:0a:c4:2c:86:50",
                    "DriverOpts": null,
                    "GwPriority": 0,
                    "NetworkID": "cecdcfa4678447d0e196a7f73ebf91abcfefacc5b08e5152c443658f68a3f1d2",
                    "EndpointID": "0b162e9cacc3a4b0d47cd1dced8dfcaae1cf46676b7408162f1a948777c7798f",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "DNSNames": null
                }
            }
        }
    }
]
```

输入内容有些多，可以用 `--format` 格式过滤

```bash
# 查看运行状态
docker inspect -f "{{.State.Status}}" cranky_newton
# 查看容器IP
docker inspect -f "{{.NetworkSettings.IPAddress}}" cranky_newton
```

## 3.5 查看容器日志

使用`docker logs` 指令可以查看容器中运行的进程在控制台的标准输出和标准错误，一般对应是日志信息

```bash
Usage:  docker logs [OPTIONS] CONTAINER
Options:
      --details        显示提供给日志的额外详细信息
  -f, --follow         跟踪日志输出
      --since string   显示时间戳后的日志 (e.g. "2013-01-02T13:23:37Z") 或相对的 (e.g. "42m" for 42 minutes)
  -n, --tail string    从日志末尾开始显示的行数 (默认 "all")
  -t, --timestamps     显示时间戳
      --until string   显示时间戳前的日志 (e.g. "2013-01-02T13:23:37Z") 或相对的 (e.g. "42m" for 42 minutes)
```

例如，持续输出容器的日志：

```bash
docker logs -f cranky_newton
```

# 四、容器其他操作

## 4.1 容器的启停

容器操作指令

```bash
docker start|stop|restart|pause|unpause 容器名
```

例如，批量启停全部容器：
```bash
docker start $(docker ps -a -q)  
docker stop $(docker ps -a -q) 
```

## 4.2 进入容器

使用 `attach | exec` 指令，可以进入运行的容器，注意：容器只有正在运行状态时，才能进入。

- attach 指令类似与服务器的VNC，操作会在同一个容器的多个会话界面同步显示，所有使用此方式进入容器的操作都是同步显示的，且使用exit退出后容器自动关闭，不推荐使用。

  ```bash
  Usage:  docker attach [OPTIONS] CONTAINER
  Options:
        --detach-keys string   覆盖用于分离容器的键序列
        --no-stdin             不要附加STDIN
        --sig-proxy            将所有接收到的信号代理到进程 (默认 true)
  ```

  例如：进入centos容器

  ```bash
  docker attach centos
  ```

- exec 指令不光可以进入容器，也可以单次执行命令

  ```bash
  Usage:  docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
  
  Options:
    -d, --detach               分离模式: 在后台运行命令
        --detach-keys string   覆盖用于分离容器的键序列
    -e, --env list             设置环境变量
        --env-file list        读入环境变量文件
    -i, --interactive          即使未连接，也保持STDIN打开
        --privileged           授予命令扩展权限
    -t, --tty                  分配伪TTY
    -u, --user string          用户名或UID (格式: "<name|uid>[:<group|gid>]")
    -w, --workdir string       容器内的工作目录
  ```

  例如，使用bash进入centos容器：

  ```bash
  docker exec -it centos bash
  ```

  例如，使用centos容器执行命令：

  ```bash
  docker exec centos bash -c "cat /etc/os-release"
  ```

## 4.3 删除容器

使用 `docker rm` 指令可以删除容器

```bash
Usage:  docker rm [OPTIONS] CONTAINER [CONTAINER...]
Options:
  -f, --force     强制移除正在运行的容器
  -l, --link      删除指定的链接
  -v, --volumes   删除与容器关联的匿名卷
```

例如，强制删除运行中的容器：

```bash
docker rm -f jovial_ishizaka
```

例如，使用组合指令删除退出状态的容器：

```bash
docker rm $(docker ps -q -f 'status=exited')
```

例如，强制删除本机上的所有容器（危险指令）

```bash
docker rm -f $(docker ps -aq)
```



## 4.4 与容器文件互传

使用 `docker cp` 指令可以在宿主机与容器间互传文件。不论容器的状态是否运行，复制都可以实现。

```bash
Usage:  docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-
		docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH
Options:
  -a, --archive       存档模式 (复制所有的 uid/gid 信息)
  -L, --follow-link   始终遵循源文件的符号链接
  -q, --quiet         在复制过程中不打印进度。
```

例如，复制 centos 容器中的文件到宿主机当前目录：

```bash
docker cp centos:/etc/resolv.conf ./
```

例如，复制宿主机的 YUM 源文件到 centos 容器中：

```bash
docker cp /etc/yum.repos.d/rocky.repo centos:/etc/yum.repos.d
```

## 4.5 导出容器

`docker export`  和 `docker save` 都可以用于将 Docker 的容器/镜像导出到本地文件系统，但是它们用途和效果是不同的：

**docker export**：此命令是用于将一个运行的或者停止的**容器**的文件系统导出为一个 tar 归档文件。需要注意的是，docker export 不会包含该容器的历史（也就是每个层的变更），并且也不会包含容器的环境变量、元数据和其他相关的配置信息。这意味着如果你导入一个用  docker export 导出的 tar 文件并运行，你得到的将是一个新的、干净的容器，没有之前容器的运行历史和配置。

**docker save**：此命令用于将一个或多个**镜像**导出为一个 tar 归档文件。与  docker export 不同， docker save 会完整地保存镜像的所有内容，包括每一层的变更、所有的元数据、所有的标签等。这意味着如果你导入一个用 docker save 导出的 tar 文件并运行，你得到的将是一个与原镜像完全一样的新镜像，包括所有的历史和配置。

例如，导出 nginx 容器的文件系统：

```bash
docker export nginx -o nginx.tar
```

将tar包导入docker生成镜像文件

```bash
docker import nginx.tar nginx:test
```

## 4.6 清理容器

使用 `docker container prue` 指令可以对容器进行整体清除，默认清楚停止的容器：

```bash
Usage:  docker container prune [OPTIONS]
Options:
      --filter filter   提供筛选条件 (e.g. "until=<timestamp>")
  -f, --force           不提示确认
```

例如，删除停止的容器：

```bash
# docker container prune -f
Deleted Containers:
3edeb64e84f44628f0b94e0ffa61222147c96da3e6ad41839605856a34b46d22

Total reclaimed space: 3.417kB
```

# 五、查看容器的启动参数

如果接手了一台服务器，发现服务器上有几个运行了很久的容器，这时如何查看已经启动运行中的容器启动参数呢？

开源工具 runlike 可以实现该功能，可以分析出容器的启动参数：

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike -p 容器名
```

启动一个 mysql 容器：

```bash
docker run -d \
--name mysql \
-e MYSQL_ROOT_PASSWORD=123456Aa. \
-e MYSQL_DATABASE=docker \
-v /data/mysql:/var/lib/mysql \
-p 3306:3306 \
--restart=always \
mysql:latest 
```

使用 runlike 工具分析：

```bash
# docker run --rm -v /var/run/docker.sock:/var/run/docker.sock assaflavie/runlike -p mysql
docker run --name=mysql \
	--hostname=c40e48fdd221 \
	--mac-address=0a:8c:6c:20:09:36 \
	--volume /data/mysql:/var/lib/mysql \
	--env=MYSQL_ROOT_PASSWORD=123456Aa. \
	--env=MYSQL_DATABASE=docker \
	--network=bridge \
	--workdir=/ \
	-p 3306:3306 \
	--expose=33060 \
	--restart=always \
	--log-opt max-size=30m \
	--log-opt max-file=3 \
	--runtime=runc \
	--detach=true \
	mysql:latest \
	mysqld
```





