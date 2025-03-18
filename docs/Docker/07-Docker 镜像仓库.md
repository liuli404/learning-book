# 一、镜像仓库介绍

为了方便的管理和使用docker镜像，可以将镜像集中保存至Docker仓库中，将制作好的镜像`push`到仓库集中保存，在需要镜像时，从仓库中`pull`镜像即可。

```bash
# 如果没有指定 Server，则默认登录Docker Hub官方仓库
docker login [OPTIONS] [SERVER] 
Options:
  -p, --password string   密码或个人访问令牌(PAT)
      --password-stdin    从stdin获取密码或个人访问令牌(PAT)
  -u, --username string   用户名
```

```bash
# 如果没有指定 Server，则默认登出Docker Hub官方仓库
docker logout [SERVER]
```

```bash
# 在Docker Hub中搜索镜像
docker search [OPTIONS] TERM
Options:
  -f, --filter filter   # 根据提供的条件过滤输出
      --format string   # 使用Go模板进行漂亮打印搜索
      --limit int       # 限制搜索结果的最大数量
      --no-trunc        # 不截断输出
```



# 二、官方仓库

docker hub 官方仓库：https://hub.docker.com/。需要注册一个账号，不然未登录用户拉取镜像会有流控限制。

目前官方仓库已经被墙，需要科技上网才能访问。

- 登录docker hub

![image-20250318175121380](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318175121380.png)

- 创建自己的仓库

![image-20250318175927784](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318175927784.png)

- 创建仓库，权限设置为私有

![image-20250318180055149](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318180055149.png)

![image-20250318180255331](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318180255331.png)

- 登录仓库（这一步需要服务器可以访问 docker.io）

```bash
# docker login -u liuli1996 -p liuli@123 docker.io
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

- 上传本地镜像到仓库

```bash
# 上传本地镜像前需要先打标签
# 格式为 docker tag 源镜像名:标签 仓库命名空间/目标镜像名:标签
docker tag nginx:latest liuli1996/nginx:latest
# 上传命令
docker push liuli1996/nginx:latest
```

# 三、阿里云仓库

阿里云镜像仓库是阿里公有云服务提供的一项服务，注册阿里云账号后登入：https://cr.console.aliyun.com/cn-hangzhou/instances。

![image-20250318185503012](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185503012.png)

- 创建个人版实例

![image-20250318185622435](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185622435.png)

![image-20250318185637813](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185637813.png)

![image-20250318185657425](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185657425.png)

- 创建命名空间

![image-20250318185723983](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185723983.png)

- 创建镜像仓库

![image-20250318185756421](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185756421.png)

![image-20250318185824262](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318185824262.png)

- 登录仓库

```bash
# docker login --username=xxxxd crpi-7ghfblqdw42rm8mw.cn-hangzhou.personal.cr.aliyuncs.com
Password: 

WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
```

- 上传镜像到仓库

```bash
# 格式为 docker tag 源镜像名:标签 仓库地址/命名空间/目标镜像名:标签
docker tag nginx:latest crpi-7ghfblqdw42rm8mw.cn-hangzhou.personal.cr.aliyuncs.com/liuli1996/liuli:latest
# 上传镜像
docker push crpi-7ghfblqdw42rm8mw.cn-hangzhou.personal.cr.aliyuncs.com/liuli1996/liuli:latest
```

- 查看仓库内镜像

![image-20250318190352942](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318190352942.png)

# 四、单机仓库 Docker Registry

Docker Registry 作为Docker的核心组件之一，负责单主机的镜像内容的存储与分发，客户端的`docker  pull`以及`push`命令都将直接与registry进行交互，最初版本的 registry 由Python实现，由于设计初期在安全性，性能以及API的设计上有着诸多的缺陷，该版本在0.9之后停止了开发，由新项目distribution（新的docker register被称为Distribution）来重新设计并开发下一代registry。

新的项目由go语言开发，所有的API，底层存储方式，系统架构都进行了全面的重新设计已解决上一代registry中存在的问题，2016 年4月份registry 2.0正式发布，docker 1.6版本开始支持registry 2.0，而八月份随着docker 1.8 发布， docker hub正式启用2.1版本registry全面替代之前版本 registry。

新版registry对镜像存储格式进行了重新设计并和旧版不兼容，docker 1.5和之前的版本无法读取2.0的镜像，另外，Registry 2.4版本之后支持了回收站机制，也就是可以删除镜像了，在2.4版本之前是无法支持删除镜像的，所以如果你要使用最好是大于Registry 2.4版本的

distribution文档地址：https://distribution.github.io/distribution/

## 4.1 部署 Registry

启动 registry server 容器

```bash
docker run -d \
-p 5000:5000 \
--restart=always \
--name registry \
registry:2
```

## 4.2 推送验证

由于本地搭建的仓库没有SSL认证，所以需要在 `daemon.json` 配置文件中添加仓库的可信配置：

```bash
vim /etc/docker/daemon.json

{
	"insecure-registries": ["192.168.100.13:5000"]
}
```

```bash
systemctl restart docker
```

推送测试

```bash
docker push 192.168.100.13:5000/my-nginx:latest
```

查看仓库中的镜像列表

```bash
curl 192.168.100.13:5000/v2/_catalog
{"repositories":["my-nginx"]}
```

# 五、分布式仓库 Harbor

Harbor 是一个企业级的分布式镜像仓库，基于开源的 Distribution 拓展了安全、标识和web管理等功能。

官方地址：https://goharbor.io/

安装包下载地址：https://github.com/goharbor/harbor/releases


建议下载 offline 离线安装包，将下载的安装包解压到 `/opt` 目录

```bash
tar -zxvf harbor-offline-installer-v2.5.3.tgz -C /opt/
```

## 5.1 配置 HTTPS

- 公网生产环境可以购买服务商提供的 SSL 证书

- 内网环境可以用工具生成自签 SSL 证书

```shell
# 确保 harbor 域名已经解析到该服务器，没有的话需要在 dnsmasq 添加对应域名解析
ping proxy.localharbor.com
```

创建存放证书目录

```bash
mkdir /opt/ca/ && cd /opt/ca/
```

## 5.2 生成证书颁发机构证书

生成 CA 证书私钥

```shell
openssl genrsa -out ca.key 4096
```

生成 CA crt 证书，修改 `CN` 为自己的域名

```shell
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=proxy.localharbor.com" \
 -key ca.key \
 -out ca.crt
```

## 5.3 生成服务端证书

生成 CA 证书私钥

```bash
openssl genrsa -out proxy.localharbor.com.key 4096
```

生成证书签名请求（CSR），修改 `CN` 为自己的域名

```shell
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=example/OU=Personal/CN=proxy.localharbor.com" \
    -key proxy.localharbor.com.key \
    -out proxy.localharbor.com.csr
```

生成 x509 v3 扩展文件，`DNS.1` 写解析的域名，`DNS.2` 写当前主机名

```shell
cat > v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=proxy.localharbor.com
DNS.2=ubunt24
EOF
```

```shell
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in proxy.localharbor.com.csr \
    -out proxy.localharbor.com.crt
```

## 5.4 提供证书给 Harbor 和 Docker

- Docker

将 crt 转换成 cert，供 docker 使用

```bash
openssl x509 -inform PEM -in proxy.localharbor.com.crt -out proxy.localharbor.com.cert
```

将证书放入 docker 证书目录

```bash
mkdir -p  /etc/docker/certs.d/proxy.localharbor.com
cp ca.crt /etc/docker/certs.d/proxy.localharbor.com/
cp proxy.localharbor.com.cert /etc/docker/certs.d/proxy.localharbor.com/
cp proxy.localharbor.com.key /etc/docker/certs.d/proxy.localharbor.com/
```

重启 docker

```bash
systemctl restart docker
```

- Harbor

修改配置文件

```bash
cd /opt/harbor/
cp harbor.yml.tmpl harbor.yml
vim harbor.yml
```

修改内容如下，其他默认即可

```yaml
# 解析到该主机的域名
hostname: proxy.localharbor.com

# http 访问端口，如果默认 80 被其他程序占用，则需要修改，如果没有则忽略
http:
  port: 8080

# 配置 https 证书
https:
  port: 443
  certificate: /opt/ca/proxy.localharbor.com.crt
  private_key: /opt/ca/proxy.localharbor.com.key

# 默认的数据卷位置，改到大一点的数据盘中
data_volume: /data/harbor
```

## 5.5 启动 harbor

使用脚本直接安装启动 harbor 服务

```bash
# 默认安装，无额外需求选择默认
./install.sh

# 附带其他功能安装
./install.sh --with-notary
./install.sh --with-trivy
./install.sh --with-chartmuseum
```

查看是否全部启动

```bash
$ docker-compose ps
NAME                COMMAND                  SERVICE             STATUS              PORTS
harbor-core         "/harbor/entrypoint.…"   core                running (healthy)   
harbor-db           "/docker-entrypoint.…"   postgresql          running (healthy)   
harbor-jobservice   "/harbor/entrypoint.…"   jobservice          running (healthy)   
harbor-log          "/bin/sh -c /usr/loc…"   log                 running (healthy)   127.0.0.1:1514->10514/tcp
harbor-portal       "nginx -g 'daemon of…"   portal              running (healthy)   
nginx               "nginx -g 'daemon of…"   proxy               running (healthy)   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:443->8443/tcp, :::443->8443/tcp
redis               "redis-server /etc/r…"   redis               running (healthy)   
registry            "/home/harbor/entryp…"   registry            running (healthy)   
registryctl         "/home/harbor/start.…"   registryctl         running (healthy)
```

## 5.6 浏览器登陆

可以通过域名 `https://proxy.localharbor.com/` 登陆 harbor，默认账号：`admin/Harbor12345`。（windows 需提前配置域名解析）

![image-20250318202054404](./07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93/image-20250318202054404.png)

## 5.7 docker 登陆

```bash
$ docker login https://proxy.localharbor.com
Username: admin
Password: 

WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded
```

## 5.8 conrainerd 配置

```toml
      [plugins."io.containerd.grpc.v1.cri".registry.auths]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."proxy.localharbor.com".auth]
          username = "admin"
          password = "Harbor12345"
          
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."proxy.localharbor.com".tls]
          insecure_skip_verify = true

      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."proxy.localharbor.com"]
         endpoint = ["https://proxy.localharbor.com"]

    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = "/etc/containerd/cert/proxy.localharbor.com.cert"
      tls_key_file = "/etc/containerd/cert/proxy.localharbor.com.key"
```



## 5.9 管理 Harbor 服务

- 停止 Harbor

```bash
docker-compose stop
```

- 重启 Harbor

```bash
docker-compose start
```

- 重新配置

```bash
docker-compose down -v
vim harbor.yml
prepare --with-notary --with-trivy --with-chartmuseum
docker-compose up -d
```

- 卸载 harbor

```bash
docker-compose down -v
rm -r /data/harbor
```

# 六、利用阿里云镜像服务同步海外镜像

日常使用中经常会遇到一些海外镜像仓库 `k8s.gcr.io` ，国内无法访问下载，导致软件无法正常安装使用。一些常用的镜像国内有开源镜像库可以使用，但是遇到一些新版本、自定义镜像，很难找到国内开源镜像库，这时候就需要自建一个仓库来同步海外镜像。

以下使用阿里云 `容器镜像服务` 同步海外镜像流程图：

![image-20220710151644064](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710151644064.png)

## 6.1 dockerfile 创建

构建镜像需要 dockerfile，我们将 dockerfile 放在 github 上托管，内容只需一个 from 指令即可，将需要构建的海外镜像写入（我这里构建 ingress）

```dockerfile
from registry.k8s.io/ingress-nginx/controller:v1.2.1@sha256:5516d103a9c2ecc4f026efbd4b40662ce22dc1f824fb129ed121460aaa5c47f8
```

```dockerfile
from registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1@sha256:64d8c73dca984af206adf9d6d7e46aa550362b1d7a01f3a0a91b20cc67868660
```

dockerfile 文件路径，路径可以自己规划的，只要后面构建时能找到即可

![image-20220710160724656](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710160724656.png)

![image-20220710161609401](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710161609401.png)

## 6.2 容器镜像服务配置

1. 创建命名空间

![image-20220710161011932](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710161011932.png)

2. 创建镜像仓库

   第一步：这里一个仓库名称就是一个镜像名

   ![image-20220710161934782](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710161934782.png)

   第二步：连接自己的 github 仓库，勾选使用海外机器构建、不使用缓存

![image-20220710161858463](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710161858463.png)

3. 构建→添加规则→确定

   构建上下文路径一直写到 Dockerfile 所在目录

   ![image-20220710163234295](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710163234295.png)

4. 立即构建

![image-20220710163325360](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710163325360.png)

## 6.3 harbor 同步配置

1. 新建目标仓库，系统管理 → 仓库管理 → 新建目标

- 提供者：Alibaba ACR
- 目标名：自定义一个标识
- 目标 URL：下拉选择镜像仓库所在区
- 访问 ID：阿里云 RAM 的 AccessKey ID
- 访问密码：阿里云 RAM 的 AccessKey Secret
- 验证远程证书：如果是自签或者非信任的证书不要勾选

![image-20220710170103181](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710170103181.png)

![image-20220710170132639](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710170132639.png)

2. 新建复制规则，系统管理 → 复制管理 → 新建规则

- 名称：自定义一个名称即可
- 复制模式：Pull-based 就是将阿里云上的镜像拉到 Harbor，Push则相反
- 源仓库：下拉选择刚才新建的目标
- 资源过滤器：全量同步的规则可以为空
- 目标：指定目标名称空间，不填则放到和源端相同的名称空间下
- 触发模式：定时，Cron 表达式根据需求编写
- 带宽：-1 表示不限制
- 覆盖：相同名称则覆盖

![image-20220710171435742](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710171435742.png)

![image-20220710171503582](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710171503582.png)

3. 手动复制

![image-20220710171615278](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710171615278.png)

![image-20220710171717674](07-Docker%20%E9%95%9C%E5%83%8F%E4%BB%93%E5%BA%93\image-20220710171717674.png)

# 七、镜像迁移

安装 image-syncer 

```shell
wget https://github.com/AliyunContainerService/image-syncer/releases/download/v1.3.1/image-syncer-v1.3.1-linux-amd64.tar.gz
tar -zxvf image-syncer-v1.3.1-linux-amd64.tar.gz
mv image-syncer /usr/local/bin/
```

`auth.json` 包含了所有镜像仓库的认证信息

```json
{
    "harbor.test.digitalchina.com": {    
        "username": "harboradmin",               
        "password": "P@ssw0rd",
        "insecure": true                 
    },
    "proxy.localharbor.com": {
		"username": "admin",
        "password": "Harbor12345",
        "insecure": true  
    }
}
```

`images.json` 镜像同步清单

```json
{
    "harbor.test.digitalchina.com/test2/nfs-client-provisioner": "proxy.localharbor.com/repo/nfs-client-provisioner",
    "harbor.test.digitalchina.com/test2/anhx/nginx": "proxy.localharbor.com/repo/nginx"
}
```

同步命令

```shell
# --proc       并发数，进行镜像同步的并发goroutine数量，默认为5
# --retries    失败同步任务的重试次数，默认为 2，重试会在所有任务都被执行一遍之后开始，并且也会重新尝试对应次数生成失败任务的生成。一些偶尔出现的网络错误比如io timeout、TLS handshake timeout，都可以通过设置重试次数来减少失败的任务数量
# 

image-syncer --auth=./auth.json --images=./images.json --retries=3 --proc=6
```