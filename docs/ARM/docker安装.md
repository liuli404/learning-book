# 离线二进制安装
```bash
# cat /etc/redhat-release
CentOS Linux release 7.6.1810 (AltArch)
```

## 下载二进制安装包
软件包：https://download.docker.com/linux/static/stable/aarch64/
下载：docker-27.3.0.tgz

## 解压二进制包
```bash
# tar xzvf docker-27.3.0.tgz
docker/
docker/containerd-shim-runc-v2
docker/dockerd
docker/runc
docker/containerd
docker/docker-proxy
docker/docker-init
docker/ctr
docker/docker
```
```bash
cp docker/* /usr/bin/
```
## 启动 dockerd
```bash
dockerd &
```
## 查看 docker info
```bash
# docker info
Client:
 Version:    27.3.0
 Context:    default
 Debug Mode: false

Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 27.3.0
 Storage Driver: overlay2
  Backing Filesystem: xfs
  Supports d_type: true
  Using metacopy: false
  Native Overlay Diff: true
  userxattr: false
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 1
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
 Swarm: inactive
 Runtimes: io.containerd.runc.v2 runc
 Default Runtime: runc
 Init Binary: docker-init
 containerd version: 7f7fdf5fed64eb6a7caf99b3e12efcf9d60e311c
 runc version: v1.1.14-0-g2c9f560
 init version: de40ad0
 Security Options:
  seccomp
   Profile: builtin
 Kernel Version: 4.14.0-115.el7a.0.1.aarch64
 Operating System: CentOS Linux 7 (AltArch)
 OSType: linux
 Architecture: aarch64
 CPUs: 4
 Total Memory: 7.397GiB
 Name: ecs-yumserver.novalocal
 ID: 2c313c5d-ed55-481e-93c4-1519299888ea
 Docker Root Dir: /var/lib/docker
 Debug Mode: false
 Experimental: false
 Insecure Registries:
  127.0.0.0/8
 Live Restore Enabled: false
 Product License: Community Engine
```

# 后续优化

## WARNING: bridge-nf-call-iptables is disabled

```bash
vim /etc/sysctl.conf
#添加以下内容
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

# 最后再执行
modprobe br_netfilter
sysctl -p

# 最后重启 dockerd
```


## 创建 systemd 守护进程文件
```bash
cat > /etc/systemd/system/docker.service << 'EOF'
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
```
```bash
cat > /etc/systemd/system/docker.socket << 'EOF'
[Unit]
Description=Docker Socket for the API

[Socket]
# If /var/run is not implemented as a symlink to /run, you may need to
# specify ListenStream=/var/run/docker.sock instead.
ListenStream=/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=root

[Install]
WantedBy=sockets.target
EOF

启动docker
```bash
systemctl daemon-reload
systemctl enable docker.service
systemctl start docker.service
```

## 创建配置文件(可选)
```bash
mkdir -p /etc/docker/
cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/data/docker"
}
EOF
```




