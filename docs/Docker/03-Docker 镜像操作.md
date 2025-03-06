# 一、镜像的原理

镜像即创建容器的模版，含有启动容器所需要的文件系统及所需要的内容，因此镜像主要用于方便和快速的创建并启动容器。

![img](./03-Docker%20%E9%95%9C%E5%83%8F%E6%93%8D%E4%BD%9C/1062096-20210727182748435-2007656270.png)

镜像含里面是一层层的文件系统,叫做 Union FS（联合文件系统），可以将几层目录挂载到一起，形成一个虚拟文件系统。

镜像通过这些文件再加上宿主机的内核共同提供了一个 linux 的虚拟环 境，每一层文件系统叫做一层 layer。

联合文件系统可以对每一层文件系统设置三种权限，只读 （readonly）、读写（readwrite）和写出（whiteout-able），但是镜像中每一层文件系统都是只读的，构建镜像的时候，从一个最基本的操作系统开始，每个构建提交的操作都相当于做一层的修改，增加了 一层文件系统，一层层往上叠加，上层的修改会覆盖底层该位置的可见性，这也很容易理解，就像上层把底层遮住了一样，当使用镜像的时候，我们只会看到一个完全的整体，不知道里面有几层，实际上也不需要知道里面有几层。

使用 `docker inspect 镜像名`，可以看到镜像的分层：

```bash
"Data": {
    "MergedDir": "/data/docker/overlay2/e831d05f5b3c32def3c0362e4a3028d30e579f24fddf6110427611b756c3dbe6/merged",
    "UpperDir": "/data/docker/overlay2/e831d05f5b3c32def3c0362e4a3028d30e579f24fddf6110427611b756c3dbe6/diff",
    "WorkDir": "/data/docker/overlay2/e831d05f5b3c32def3c0362e4a3028d30e579f24fddf6110427611b756c3dbe6/work"
}
```

如下图所示：

![image-20250305162120836](./03-Docker%20%E9%95%9C%E5%83%8F%E6%93%8D%E4%BD%9C/image-20250305162120836.png)

# 二、镜像操作

## 2.1 搜索镜像

当我们需要下载一个镜像时，可以上官方网站进行镜像的搜索：https://hub.docker.com/

![image-20250305164101969](./03-Docker%20%E9%95%9C%E5%83%8F%E6%93%8D%E4%BD%9C/image-20250305164101969.png)

![image-20250305164115847](./03-Docker%20%E9%95%9C%E5%83%8F%E6%93%8D%E4%BD%9C/image-20250305164115847.png)

也可以使用命令搜索想要的镜像：

```bash
Usage:  docker search [OPTIONS] TERM
Options:
  -f, --filter filter   根据提供的条件过滤输出
      --format string   使用Go模板进行漂亮打印搜索
      --limit int       搜索结果的最大数量
      --no-trunc        不要截断输出
```

```bash
# 搜索点赞大于100的镜像
docker search --filter=stars=100 centos
```

## 2.2 下载镜像

从 docker 仓库将镜像下载到本地，命令格式如下:  

```bash
Usage:  docker pull [OPTIONS] NAME[:TAG|@DIGEST]
Options:
  -a, --all-tags                下载仓库中的所有tag标记的镜像
      --disable-content-trust   跳过镜像验证（默认为true）
      --platform string         如果服务器是多平台架构，则设置CPU平台
  -q, --quiet                   精简输出信息
  
NAME: 是镜像名
TAG: 版本号,如果不指定TAG,则下载最新版latest
```

例如，下载 22.04 版本的ubuntu系统镜像：

```bash
# docker pull ubuntu:22.04
22.04: Pulling from library/ubuntu
9cb31e2e37ea: Pull complete 
Digest: sha256:ed1544e454989078f5dec1bfdabd8c5cc9c48e0705d07b678ab6ae3fb61952d2
Status: Downloaded newer image for ubuntu:22.04
docker.io/library/ubuntu:22.04
```

例如，下载 ARM 架构的 nginx 应用镜像：

```bash
# docker pull --platform linux/arm/v5 nginx:stable-perl 
stable-perl: Pulling from library/nginx
d8a77b84d73c: Pull complete 
34fdf8550a1c: Pull complete 
f48188ecec55: Pull complete 
f3a65d25cd30: Pull complete 
4f58fb504f8d: Pull complete 
d7d573493d05: Pull complete 
4c76f78680c1: Pull complete 
e05186dd3103: Pull complete 
Digest: sha256:c2950a70e773cc9c7135930354dc8fe1b4a25ceeaa70b8ccb2e469ca31a8d0a7
Status: Downloaded newer image for nginx:stable-perl
docker.io/library/nginx:stable-perl
```

镜像下载保存的路径为docker的主目录 `overlay2` 中。

## 2.3 查看本地镜像

`docker images` 可以查看下载至本地的镜像：

```bash
Usage:  docker images [OPTIONS] [REPOSITORY[:TAG]]
Options:
  -a, --all             显示所有镜像 (默认隐藏中间层镜像)
      --digests         显示摘要
  -f, --filter filter   根据提供的条件过滤输出
      --format string   使用自定义模板格式化输出：
                        'table':            以带有列标题的表格格式打印输出（默认）
                        'table TEMPLATE':   使用给定的Go模板以表格格式打印输出
                        'json':             以JSON格式打印
                        'TEMPLATE':         使用给定的Go模板打印输出。
      --no-trunc        不截断输出
  -q, --quiet           仅显示镜像ID
      --tree            以树的形式列出多平台图像
```

`docker images --filter` 命令用于指定过滤条件，支持的筛选条件有：

- dangling （布尔值：true 或 false）
- label：筛选出对应的标签的镜像
- before：过滤在给定id或引用之前创建的镜像
- since：过滤自给定id或引用以后创建的镜像
- reference：筛选参考与指定模式匹配的镜像

```bash
# 刷选出dangling状态的镜像
docker images --filter "dangling=true"
# 筛选出 ngi* 名称开头的镜像
docker images --filter reference='ngi*'
```

`docker images --format` 命令用于指定在输出中显示镜像信息的格式。

格式字符串由多个占位符组成，每个占位符代表映像的特定属性。

```bash
# 常用的格式占位符：
{{.Repository}}：映像的仓库名称。
{{.Tag}}：映像的标签。
{{.ID}}：映像的ID。
{{.Digest}}：映像的摘要值。
{{.CreatedAt}}：映像的创建时间。
{{.Size}}：映像的大小。

# 示例
docker images --format "{{.Repository}}\t{{.Tag}}\t{{.Size}}"
docker images --format "{{.CreatedAt}}\t{{.Repository}}:{{.Tag}}" 
```

## 2.4 查看镜像的构建历史

使用 `docker history` 可以查看镜像的每层构建历史

```bash
Usage:  docker history [OPTIONS] IMAGE
Options:
      --format string   使用自定义模板格式化输出：
                        'table':            以带有列标题的表格格式打印输出（默认）
                        'table TEMPLATE':   使用给定的Go模板以表格格式打印输出
                        'json':             以JSON格式打印
                        'TEMPLATE':         使用给定的Go模板打印输出。
  -H, --human           以人类可读格式输出大小和日期 (默认)
      --no-trunc        不截断输出
      --platform string   显示给定平台的历史记录。 格式化为 "os[/arch[/variant]]" (e.g., "linux/amd64")
  -q, --quiet             仅显示图像ID
```

例如，查看 ubuntu 的构建历史

```bash
# docker history ubuntu:22.04 
IMAGE          CREATED       CREATED BY                                       SIZE      COMMENT
a24be041d957   5 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]             0B        
<missing>      5 weeks ago   /bin/sh -c #(nop) ADD file:1b6c8c9518be42fa2…   77.9MB    
<missing>      5 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B        
<missing>      5 weeks ago   /bin/sh -c #(nop)  LABEL org.opencontainers.…   0B        
<missing>      5 weeks ago   /bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH      0B        
<missing>      5 weeks ago   /bin/sh -c #(nop)  ARG RELEASE                   0B     
```

## 2.5 查看镜像的详细信息

使用 `docker inspect` 可以查看一个镜像的详细信息

`inspect` 指令还可查看其他的对象信息： `config|container|node|network|secret|service|volume|task|plugin`

使用 `inspect` 查看 `ubuntu:22.04` 的详细信息。

```bash
# docker inspect ubuntu:22.04 
[
    {
        "Id": "sha256:a24be041d9576937f62435f8564c2ca6e429d2760537b04c50ca50adb0c6d212",
        "RepoTags": [
            "ubuntu:22.04"
        ],
        "RepoDigests": [
            "ubuntu@sha256:ed1544e454989078f5dec1bfdabd8c5cc9c48e0705d07b678ab6ae3fb61952d2"
        ],
        "Parent": "",
        "Comment": "",
        "Created": "2025-01-26T05:31:11.215737135Z",
        "DockerVersion": "24.0.7",
        "Author": "",
        "Config": {
            "Hostname": "",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/bash"
            ],
            "Image": "sha256:6a77a0133da2aab8dda6b56b0f5b7fbe6303f43d50562a2ad48105cddb90179f",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "org.opencontainers.image.ref.name": "ubuntu",
                "org.opencontainers.image.version": "22.04"
            }
        },
        "Architecture": "amd64",
        "Os": "linux",
        "Size": 77863019,
        "GraphDriver": {
            "Data": {
                "MergedDir": "/data/docker/overlay2/c17f11527d3b51d4abc06822dba90c7fbb30b99fee2c21e8fba8318db68d469b/merged",
                "UpperDir": "/data/docker/overlay2/c17f11527d3b51d4abc06822dba90c7fbb30b99fee2c21e8fba8318db68d469b/diff",
                "WorkDir": "/data/docker/overlay2/c17f11527d3b51d4abc06822dba90c7fbb30b99fee2c21e8fba8318db68d469b/work"
            },
            "Name": "overlay2"
        },
        "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:270a1170e7e398434ff1b31e17e233f7d7b71aa99a40473615860068e86720af"
            ]
        },
        "Metadata": {
            "LastTagTime": "0001-01-01T00:00:00Z"
        }
    }
]
```

## 2.6 镜像导出

利用 docker save 命令可以将从本地镜像导出为一个打包 tar 文件，然后复制到其他服务器进行导入使用

```bash
# 导出单个镜像为tar格式
docker save alpine:latest > alpine.tar
# 导出多个镜像为tar格式
docker save nginx:latest redis:latest > middle.tar
# 导出镜像为压缩格式
docker save debian:latest | gzip > debian.tar.gz
# 根据镜像ID导出全部镜像并压缩
docker save $(docker images --format "{{.Repository}}:{{.Tag}}") | gzip > all.tar.gz
```

docker save 也可使用 IMAGE ID 导出，但是导入后的镜像没有 REPOSITORY 和 TAG，显示为 none

```bash
# docker save d4ccddb816ba > debian.tar
# docker load < debian.tar
# docker images 
REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
<none>       <none>    d4ccddb816ba   9 days ago    117MB
# docker rmi $(docker images --filter "dangling=true")
```

## 2.7 镜像导入

直接导入镜像的 tar 包到本地

```bash
docker load < debian.tar.gz
```

## 2.8 删除镜像

`docker rmi`  命令可以删除一个或多个本地镜像

```bash
Usage:  docker rmi [OPTIONS] IMAGE [IMAGE...]
Options:
  -f, --force      强制删除镜像
      --no-prune   不删除未标记的父级
```

删除 `alpine:latest` 镜像

```bash
docker rmi alpine:latest 
```

删除所有镜像

```bash
docker rmi $(docker images -q)
```

或者使用 `prune` 指令清除镜像

```bash
docker image prune -a -f
```

## 2.9 给镜像改名

使用 tag 指令给镜像改名称，常用于将本地镜像上传到私有仓库

```bash
docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]
```

将 `nginx:latest` 标签改为 `liuli/nginx:v1`

```bash
docker tag nginx:latest liuli/nginx:v1
```

## 2.10 代理工具拉取被墙镜像

有些镜像即使使用了镜像加速器在国内也无法下载，例如 k8s 的相关镜像。使用 `https://dockerproxy.link` 提供的工具可以将被墙的镜像改为可下载的镜像。

![image-20250305211636426](./03-Docker%20%E9%95%9C%E5%83%8F%E6%93%8D%E4%BD%9C/image-20250305211636426.png)

