# 离线二进制安装
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
## 创建守护进程文件
```bash
cat > /etc/systemd/system/docker.service << EOF
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
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
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

## 启动docker
```bash
systemctl enable docker.service
systemctl start docker.service
```
