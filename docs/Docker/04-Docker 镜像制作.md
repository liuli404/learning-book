# 一、镜像介绍

从镜像大小上面来说，一个比较小的镜像只有1MB多点或几MB，而内核文件需要几十MB， 因此镜像里面是没有内核的，镜像在被启动为容器后将直接使用宿主机的内核，而镜像本身则只提供相应的 rootfs，即系统正常运行所必须的用户空间的文件系统，比如：/dev/，/proc，/bin，/etc等目录，容器当中/boot目录是空的，而/boot当中保存的就是与内核相关的文件和目录。

由于容器启动和运行过程中是直接使用了宿主机的内核，不会直接调用物理硬件，所以也不会涉及到硬 件驱动，因此也无需容器内拥有自已的内核和驱动。

镜像的生命周期：

![image-20250306194825152](./04-Docker%20%E9%95%9C%E5%83%8F%E5%88%B6%E4%BD%9C/image-20250306194825152.png)

# 二、镜像制作方法

*tips：Docker容器如果希望启动后能持续运行，就必须有一个能前台持续运行的进程，如果在容器中启动传统的服务，如：httpd,php-fpm等均为后台进程模式运行，就导致 docker 在前台没有运行的应用，这样的容器启动后会立即退出。所以一般会将服务程序以前台方式运行，对于有一些可能不知道怎么实现前台运行的程序，只需要在你启动的该程序之后添加类似于 tail ，top 这种可以前台运行的程序即可。比较常用的方 法，如  tail  -f  /etc/hosts 。*

## 2.1 commit 指令

可以将一个运行或停止的容器保存成镜像，这样可以将一个修改后的容器保存成一个自定义镜像。

提交制作镜像的容器，不会包含卷中的数据。

制作镜像的流程，以 nginx 为例：

1. 运行一个系统镜像

   ```bash
   docker run -d -it --name centos8 centos:latest
   ```

   ```bash
   # docker images 
   REPOSITORY   TAG       IMAGE ID       CREATED       SIZE
   centos       latest    5d0da3dc9764   3 years ago   231MB
   # docker ps
   CONTAINER ID   IMAGE           COMMAND       CREATED         STATUS         PORTS     NAMES
   ca419c4cc4ec   centos:latest   "/bin/bash"   7 minutes ago   Up 7 minutes             centos8
   ```

2. 进入容器并自定义操作

   ```bash
   docker exec -it centos8 bash
   ```

   ```bash
   # 更换yum源
   mv /etc/yum.repos.d/* /tmp
   curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo
   yum clean all && yum makecache
   # 安装基本工具
   yum install -y wget openssl openssl-devel zlib zlib-devel pcre pcre-devel make gcc gcc-c++
   # 下载 nginx 源码包
   wget https://nginx.org/download/nginx-1.24.0.tar.gz
   # 编译安装 nginx
   tar zxvf nginx-1.24.0.tar.gz
   cd nginx-1.24.0 && ./configure --prefix=/nginx && make && make install 
   # 测试nginx
   /nginx/sbin/nginx -t
   ```

3. 保存容器为自定义镜像

   ```bash
   docker commit centos8 centos8:nginx
   ```

4. 启动自定义nginx镜像测试

   ```bash
   # docker images 
   REPOSITORY   TAG       IMAGE ID       CREATED          SIZE
   centos8      nginx     232e1e488d79   49 seconds ago   504MB
   centos       latest    5d0da3dc9764   3 years ago      231MB
   # docker run -d --name nginx -p 80:80 centos8:nginx bash -c '/nginx/sbin/nginx -g "daemon off;"'
   # docker ps
   CONTAINER ID   IMAGE           COMMAND                   CREATED          STATUS          PORTS                                 NAMES
   2299651f80a9   centos8:nginx   "bash -c '/nginx/sbi…"   14 seconds ago   Up 13 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp   nginx
   ```

可以看到仅安装了一个nginx，就需要这么多步骤，而且大部分是手动操作，略微繁琐，并不推荐使用该方式制作镜像。

## 2.2 Dockerfile 构建

Docker 可以通过读取 Dockerfile 中的指令来自动构建镜像，相比手动制作镜像的方式，DockerFile 更能直观的展示镜像是怎么产生的，有了DockerFile，当后期有额外的需求时，只要在之前的 Dockerfile 添加或者修改响应的命令即可重新生成新的Docker镜像。

```bash
Usage:  docker build [OPTIONS] PATH | URL | -
# 可以使是本地路径，也可以是URL路径。若设置为 - ，则从标准输入获取Dockerfile的内容

Options:     
-f, --file string	# Dockerfile文件名,默认为 PATH/Dockerfile
	--force-rm		# 总是删除中间层容器,创建镜像失败时，删除临时容器 
	--no-cache		# 不使用之前构建中创建的缓存
-t 	--tag list		# 设置注册名称、镜像名称、标签。格式为 <注册名称>/<镜像名称>:<标签>（标签默认为latest）
-q  --quiet=false	# 不显示Dockerfile的RUN运行的输出结果
	--rm=true		# 创建镜像成功时，删除临时容器
```

## 2.3 Dockerfile 指令

Dockerfile 是一个文本，包含以下构建镜像的所有指令：

```dockerfile
FROM			从基础镜像创建新的构建阶段
MAINTAINER		指定镜像的作者
LABEL			向镜像添加元数据
ARG				使用构建时变量
ENV				设置环境变量
SHELL			设置镜像的默认shell
COPY			指定默认命令
ADD				添加本地或远程文件和目录
USER			设置用户和组ID
WORKDIR			更改工作目录
RUN				执行构建命令
EXPOSE			描述您的应用程序正在监听哪些端口
VOLUME			创建匿名卷
HEALTHCHECK		启动时检查容器的健康状况
STOPSIGNAL		指定退出容器的系统调用信号
ONBUILD			指定何时在生成中使用镜像的说明
CMD				指定默认命令
ENTRYPOINT		指定默认可执行文件
```

编写规范：

1. 指令不区分大小写，惯例是将它们大写，以便更容易将它们与参数区分开来。
2. Docker按顺序运行Dockerfile中的指令，Dockerfile必须以FROM指令开头（FROM之前只允许有一个或多个ARG）。
3.  `#` 开头的行会被视为注释。
4. 每一行只支持一条指令，每条指令可以携带多个参数

### 2.3.1 FROM

定制镜像，需要先有一个基础镜像，在这个基础镜像上进行定制。

FROM 就是指定基础镜像，此指令通常必需放在Dockerfile文件第一个非注释行。后续的指令都是运行于此基准镜像所提供的运行环境。

基础镜像可以是任何可用镜像文件，默认情况下，docker build会在docker主机上查找指定的镜像文件，在其不存在时，则会从Docker Hub Registry上拉取所需的镜像文件。如果找不到指定的镜像文件，docker build会返回一个错误信息。

```dockerfile
FROM [--platform=<platform>] <image> [AS <name>]
FROM [--platform=<platform>] <image>[:<tag>] [AS <name>]
FROM [--platform=<platform>] <image>[@<digest>] [AS <name>]

# --platform 指定镜像的平台，比如: linux/amd64, linux/arm64, or windows/amd64
# tag 和 digest是可选项，如果不指定，默认为latest
# 通过将AS name添加到FROM指令来为新的构建阶段赋予名称。
```

例如，拉取不同类型的镜像

```dockerfile
FROM centos:centos7.9.2009
FROM ubuntu:latest
FROM --platform=linux/amd64 alpine:3.21.3
```



### 2.3.2 MAINTAINER

该指令可以设置镜像作者

```dockerfile
MAINTAINER <name>
```

该指令已经弃用了，使用 LABEL 指令替代。

```dockerfile
LABEL org.opencontainers.image.authors="SvenDowideit@home.org.au"
```



### 2.3.3 LABEL

可以指定镜像元数据，如:  镜像作者等。

```dockerfile
LABEL <key>=<value> <key>=<value> <key>=<value> ...
```

一个镜像可以有多个label，还可以写在一行中，即多标签写法，可以减少镜像的的大小。

```bash
LABEL multi.label1="value1" multi.label2="value2" other="value3"
```

### 2.3.4 ENV

ENV 可以定义环境变量和值，会被后续指令（如：ENV，ADD，COPY，RUN等）通过$KEY或${KEY}进行引用，并在容器运行时保持。

```dockerfile
# 变量赋值格式1
 ENV <key> <value>   
# 此格式只能对一个key赋值,<key>之后的所有内容均会被视作其<value>的组成部分

# 变量赋值格式2
 ENV <key1>=<value1> <key2>=<value2> \  #此格式可以支持多个key赋值,定义多个变量建议使用，减少镜像层
     <key3>=<value3> ... #如果<value>中包含空格，可以以反斜线\进行转义，也可通过对<value>加引号进行标识;另外，反斜线也可用于续行

# 只使用一次变量
RUN <key>=<value> <command>
# 引用变量
RUN $key .....
```

### 2.3.5 ARG

ARG 指令在build 阶段指定变量，和 ENV 不同的是，容器运行时并不存在 ARG 定义的环境变量，而 ENV 环境变量值可以被 docker run -e 参数替换。

```dockerfile
ARG <name>[=<default value>] [<name>[=<default value>]...]
```

如果和ENV同名，则ENV覆盖ARG变量

可以用  docker build --build-arg <参数名>=<值>  来覆盖

ARG指令支持放在第一个FROM之前声明

### 2.3.6 SHELL

SHELL 指令允许覆盖用于shell形式命令的默认shell。

```bash
SHELL ["executable", "parameters"]
```

SHELL指令在Windows上特别有用，因为Windows有两个常用且完全不同的本机SHELL：`cmd`和`powershell`，以及包括`sh`在内的备用SHELL。

可以使用 SHELL 指令更改默认shell。例如：

```dockerfile
FROM microsoft/windowsservercore

# Executed as cmd /S /C echo default
RUN echo default

# Executed as cmd /S /C powershell -command Write-Host default
RUN powershell -command Write-Host default

# Executed as powershell -command Write-Host hello
SHELL ["powershell", "-command"]
RUN Write-Host hello

# Executed as cmd /S /C echo hello
SHELL ["cmd", "/S", "/C"]
RUN echo hello
```



### 2.3.7 COPY

复制本地宿主机的文件到容器中

```dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"] # 路径中有空白字符时，建议使用此格式
```

- 可以是多个，可以使用通配符，通配符规则满足Go的 filepath.Match 规则
- 必须是build上下文中的路径(为 Dockerfile 所在目录的相对路径），不能是其父目录中的文件
- 如果是目录，则其内部文件或子目录会被递归复制，但目录自身不会被复制
- 如果指定了多个, 或在中使用了通配符，则必须是一个目 录，且必须以 / 结尾
- 可以是绝对路径或者是 WORKDIR 指定的相对路径
- 使用 COPY 指令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等
- 如果事先不存在，它将会被自动创建，这包括其父目录路径,即递归创建目录

例如，将本地的 nginx 安装包 copy 到容器中的 /nginx 目录

```dockerfile
COPY nginx-1.24.0.tar.gz /nginx/
```



### 2.3.8 ADD

复制和解包文件，该命令可认为是增强版的COPY，不仅支持COPY，还支持自动解压缩。

```dockerfile
ADD [--chown=<user>:<group>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"] 
```

- 可以是Dockerfile所在目录的一个相对路径；也可是一个 URL；还可是一个 tar 文件（自动解压）
- 可以是绝对路径或者是 WORKDIR 指定的相对路径
- 如果是目录，只复制目录中的内容，而非目录本身
- 如果是一个 URL ，下载后的文件权限自动设置为 600

例如，将网络上的 nginx 安装包 add 到容器中的 /nginx 目录

```dockerfile
# 不会自动解压
ADD https://nginx.org/download/nginx-1.24.0.tar.gz /nginx/
```

例如，将本地的 nginx 安装包 add 到容器中的 /nginx 目录

```dockerfile
# 会自动解压
ADD nginx-1.24.0.tar.gz /nginx/
```



### 2.3.9 USER

指定当前用户，指定运行容器的用户名或 UID，在后续dockerfile中的 RUN ，CMD和ENTRYPOINT指令时使用此用户

当服务不需要管理员权限时，可以通过该命令指定运行用户

这个用户必须是**事先建立**好的，否则无法切换，如果没有指定 USER，默认是 root 身份执行

```dockerfile
USER <user>[:<group>] 
USER <UID>[:<GID>]
```



### 2.3.10 WORKDIR

指定工作目录，为后续的 RUN、CMD、ENTRYPOINT 指令配置工作目录，当容器运行后，进入容器内WORKDIR指定的默认目录

WORKDIR 指定工作目录（或称当前目录），以后各层的当前目录就被改为指定的目录，如该目录不存在，WORKDIR 会自行创建

### 2.3.11 RUN

RUN 指令用来在构建镜像阶段需要执行 FROM 指定镜像所支持的Shell命令。

通常各种基础镜像一般都支持丰富的shell命令。

每个RUN都是独立运行的和前一个RUN无关。

```dockerfile
#shell 格式: 相当于 /bin/sh -c  <命令>  此种形式支持环境变量
RUN <命令> 
#exec 格式: 此种形式不支持环境变量,注意:是双引号,不能是单引号
RUN ["executable","param1","param2"...] 
#exec 格式可以指定其它shell
RUN ["/bin/bash","-c","echo hello wang"]
```

例如：使用RUN执行系统换源配置

```dockerfile
RUN echo "https://mirrors.aliyun.com/alpine/v3.21/main" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.21/community" >> /etc/apk/repositories
RUN apk update
```



### 2.3.12 EXPOSE

暴露端口，指定服务端的容器需要对外暴露(监听)的端口号，以实现容器与外部通信。

EXPOSE 仅仅是声明容器打算使用什么端口而已，并不会真正暴露端口，即不会自动在宿主进行端口映射。

因此，在启动容器时需要通过 -P 或 -p 映射，Docker 主机才会真正分配一个端口转发到指定暴露的端口才可使用

注意：即使 Dockerfile 没有 EXPOSE 端口指令，也可以通过docker run -p  临时暴露容器内程序真正监听的端口，所以EXPOSE 相当于指定默认的暴露端口，可以通过docker run -P 进行真正暴露。

```dockerfile
EXPOSE <port>[/ <protocol>] [<port>[/ <protocol>] ..]
# 说明
# <protocol> 用于指定传输层协议，可为tcp或udp二者之一，默认为TCP协议
```



### 2.3.13 VOLUME

在容器中创建一个可以从本地主机或其他容器挂载的**挂载点**，一般用来存放数据库和需要保持的数据等，默认会将宿主机上的目录挂载至VOLUME 指令指定的容器目录。即使容器后期被删除，此宿主机的目录仍会保留，从而实现容器数据的**持久保存**。

```dockerfile
VOLUME <容器内路径>
VOLUME ["<容器内路径1>", "<容器内路径2>"...]
# 注意: 
# <容器内路径>如果在容器内不存在,在创建容器时会自动创建
# <容器内路径>如果是存在的,同时目录内有内容,将会把此目录的内容复制到宿主机的实际目录
```

- Dockerfile中的VOLUME实现的是匿名数据卷,无法指定宿主机路径和容器目录的挂载关系
- 通过docker rm -fv <容器ID> 可以删除容器的同时删除VOLUME指定的卷

### 2.3.14 HEALTHCHECK

HEALTHCHECK 指令告诉Docker如何测试容器以检查它是否仍在工作。

```dockerfile
# 使用方法：
HEALTHCHECK [选项] CMD <命令>	# 设置检查容器健康状况的命令,如果命令执行失败,则返回1,即unhealthy
HEALTHCHECK NONE			# 如果基础镜像有健康检查指令，使用这行可以屏蔽掉其健康检查指令

# HEALTHCHECK 支持下列选项:  
	--interval=<间隔>				# 两次健康检查的间隔，默认为 30 秒
	--timeout=<时长>				# 健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认 30 秒
	--retries=<次数>				# 当连续失败指定次数后，则将容器状态视为 unhealthy，默认3次
	--start-period=<FDURATION>		# 容器启动后多久进行健康性检查，default: 0s
 
 # 检查结果返回值:
 0  # success    容器是健康的，可以使用了
 1  # unhealthy   容器工作不正常
 2  # reserved   不要使用此退出代码
```

例如，要每隔五分钟左右检查一次web服务器是否能够为站点提供服务，超时时间在三秒钟内：

```dockerfile
HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost/ || exit 1
```

### 2.3.15 STOPSIGNAL

```docker
STOPSIGNAL signal
```

STOPSIGNAL 指令设置将发送到容器退出的系统调用信号。

该信号可以是格式为SIG \<name> 的信号名，例如：SIGKILL，也可以是与内核syscall表中的位置相匹配的无符号数字，例如9。

如果未定义，默认值为 SIGTERM。

### 2.3.16 ONBUILD

子镜像引用父镜像的指令，可以用来配置当构建当前镜像的子镜像时，会自动触发执行的指令，但在当前镜像构建时，**并不会执行**，即延迟到子镜像构建时才执行。

```dockerfile
ONBUILD [INSTRUCTION]
```

```dockerfile
FROM alpine AS baseimage
```

例如，Dockerfile 使用如下的内容创建了镜像 image-A。 

```dockerfile
ONBUILD ADD http://nginx.org/download/nginx-1.24.0.tar.gz /nginx/
ONBUILD RUN rm -rf /* 
ONBUILD COPY --from=build /usr/bin/app /app
```

如果基于 image-A 创建新的镜像 image-B时，新的Dockerfile中使用 FROM image-A 指定基础镜像时，会自动执行ONBUILD 指令内容，等价于在后面添加了两条指令。

```dockerfile
FROM image-A 
#Automatically run the following 
ADD http://nginx.org/download/nginx-1.24.0.tar.gz /nginx/
RUN rm -rf /* 
COPY --from=build /usr/bin/app /app
```

说明：

- 尽管任何指令都可注册成为触发器指令，但ONBUILD不能自我嵌套，且不会触发FROM和 MAINTAINER指令
- 使用 ONBUILD 指令的镜像，推荐在标签中注明，例如  ruby:1.9-onbuild

### 2.3.17 CMD

容器启动命令，一个容器中需要持续运行的进程一般只有一个，CMD 用来指定启动容器时默认执行的一个命令，且其运行结束后，容器也会停止，所以一般CMD 指定的命令为持续运行且为前台命令。

```dockerfile
# 使用 exec 执行，推荐方式，第一个参数必须是命令的全路径,此种形式不支持环境变量,注意:是双引号,不能是单引号
CMD ["executable","param1","param2"] 
# 在 /bin/sh 中执行，提供给需要交互的应用；此种形式支持环境变量
CMD command param1 param2 
# 提供给 ENTRYPOINT 命令的默认参数
CMD ["param1","param2"]
```

- 如果docker run没有指定任何的执行命令或者dockerfile里面也没有ENTRYPOINT命令，那么run容器时就会使用执行CMD指定的命令
- 每个 Dockerfile 只能有一条 CMD 命令。如指定了多条，只有最后一条被执行
- 如果用户启动容器时用 docker run command指定运行的命令，则会覆盖 CMD 指定的命令

例如，要指定nginx程序前台运行

```dockerfile
CMD ["/nginx/sbin/nginx", "-g", "daemon off;"]
```

### 2.3.18 ENTRYPOINT

功能类似于CMD，配置容器启动后执行的命令及参数

```dockerfile
# 使用 exec 执行,注意:是双引号,不能是单引号
ENTRYPOINT ["executable", "param1", "param2"...]
 # shell中执行
ENTRYPOINT command param1 param2
 #在脚本中结常使用变量的高级赋值格式
${key:-word}
${key:+word}
```

-  ENTRYPOINT 不能被 docker run 提供的参数覆盖，而是追加,即如果docker run 命令有参数，那么参数全部都会作为ENTRYPOINT的参数
- 如果docker run 后面没有额外参数，但是dockerfile中有CMD命令，即Dockerfile中即有CMD也有ENTRYPOINT,那么CMD的全部内容会作为ENTRYPOINT的参数
- 如果docker run 后面有额外参数，同时Dockerfile中即有CMD也有ENTRYPOINT,那么docker run 后面的参数覆盖掉CMD参数内容,最终作为ENTRYPOINT的参数
- 可以通过docker run --entrypoint string 参数在运行时替换
- 使用CMD要在运行时重新写命令本身,然后在后面才能追加运行参数，ENTRYPOINT则可以运行时 无需重写命令就可以直接接受新参数
- 每个 Dockerfile 中只能有一个 ENTRYPOINT，当指定多个时，只有最后一个生效
- 通常ENTRYPOINT指令配合脚本，主要用于为CMD指令提供环境配置

例如，与CMD指令组合成nginx启动命令：

```dockerfile
CMD ["-g", "daemon off;"]
ENTRYPOINT ["/nginx/sbin/nginx"]
```

下表显示了针对 `ENTRYPOINT/CMD` 组合执行的命令：

|                                | No ENTRYPOINT              | ENTRYPOINT exec_entry p1_entry | ENTRYPOINT ["exec_entry", "p1_entry"]          |
| :----------------------------- | :------------------------- | :----------------------------- | ---------------------------------------------- |
| **No CMD**                     | error, not allowed         | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry                            |
| **CMD ["exec_cmd", "p1_cmd"]** | exec_cmd p1_cmd            | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry exec_cmd p1_cmd            |
| **CMD exec_cmd p1_cmd**        | /bin/sh -c exec_cmd p1_cmd | /bin/sh -c exec_entry p1_entry | exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd |

# 三、构建优化

## 3.1 减少镜像层数

Dockerfile 中的每条指令都会创建一个新的镜像层，层数过多会增加镜像体积。

![image-20250306211219945](./04-Docker%20%E9%95%9C%E5%83%8F%E5%88%B6%E4%BD%9C/image-20250306211219945.png)

```dockerfile
RUN apt-get update
RUN apt-get install -y git curl
RUN rm -rf /var/lib/apt/lists/*
# 替换成
RUN apt-get update && \
    apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*
```



## 3.2 清除无用文件

在安装依赖后，及时清理缓存和临时文件以减少镜像体积：

```dockerfile
RUN apt-get update && \
    apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*
```



## 3.3 利用构建缓存

制作镜像一般可能需要反复多次，每次执行dockfile都按顺序执行，从头开始，已经执行过的指令已经缓存，不需要再执行，如果后续有一行新的指令没执行过，其往后的指令将会重新执行，所以为加速镜像制作，将最常变化的内容放下dockerfile的文件的后面。

将变化频率低的指令放在前面，变化频率高的指令（如复制代码）放在后面：

```dockerfile
# 安装依赖（变化频率低）
RUN apt-get update && apt-get install -y python3

# 复制代码（变化频率高）
COPY . /app
```



## 3.4 使用精简镜像

选择更小的基础镜像（如 alpine 版本）以减少镜像体积。

```dockerfile
FROM alpine:3.21  # 使用 Alpine Linux 作为基础镜像
```

如果应用需要完整的操作系统功能，可以选择 `slim` 版本的基础镜像

```dockerfile
FROM python:slim
```

**关于scratch 镜像：**

```dockerfile
FROM scratch
```

该镜像是一个空的镜像，可以用于构建busybox等超小镜像，可以说是真正的从零开始构建属于自己的镜像。

该镜像在构建基础镜像（例如debian和busybox）或超最小镜像（仅包含一个二进制文件及其所需内容，例如：hello-world）的上下文中最有用。

## 3.5 使用.dockerignore文件

类似于 .gitignore，.dockerignore 可以排除不需要的文件，避免它们被复制到镜像中。

```dockerfile
node_modules
.git
*.log
```



## 3.6 使用多阶段构建

多阶段构建可以显著减少镜像体积，尤其是在构建需要编译的应用时。

```dockerfile
# 第一阶段：构建应用
FROM golang:1.19 AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp .

# 第二阶段：运行应用
FROM alpine:3.14
WORKDIR /app
COPY --from=builder /app/myapp .
CMD ["./myapp"]
```



## 3.7 使用环境变量

使用 `ARG` 和 `ENV` 来管理配置，避免硬编码：

```dockerfile
ARG APP_VERSION=1.0
ENV APP_HOME=/app

WORKDIR $APP_HOME
COPY . $APP_HOME
```



## 3.8 优化 CMD 和 ENTRYPOINT

使用 `exec` 格式而不是 `shell` 格式，以减少不必要的 shell 进程：

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

而不是

```dockerfile
CMD nginx -g "daemon off;"
```

# 四、Dockerfile 案例

使用 `scratch` 镜像加上多阶段构建可以构建出非常小的镜像。

由于 `scratch` 仅仅是一个空的镜像，所以在二阶段运行的时候需要将软件运行所需要的**依赖库**（可以使用 ldd 命令查看）都一同 copy 到 `scratch` 中，这是非常麻烦的，所以推荐类似于编译后的二进制go程序（无需系统依赖库），使用该镜像。

## 4.1 构建 Nginx 镜像

```bash
# 第一阶段：构建阶段
FROM alpine:3.21 AS builder

# 安装构建工具和依赖
RUN echo "https://mirrors.aliyun.com/alpine/v3.21/main" > /etc/apk/repositories && \
	echo "https://mirrors.aliyun.com/alpine/v3.21/community" >> /etc/apk/repositories  && \
	apk add --no-cache build-base linux-headers pcre-dev zlib-dev openssl-dev wget tar

# 下载并解压 Nginx 源码
ARG NGINX_VERSION=1.25.2
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz

# 编译 Nginx
WORKDIR /nginx-${NGINX_VERSION}
RUN ./configure \
    --prefix=/usr/local/nginx \
    --with-http_ssl_module \
    --with-http_gzip_static_module \
    --with-http_v2_module \
    --with-threads \
    --with-file-aio \
    --with-http_realip_module && \
    make && \
    make install

# 第二阶段：运行阶段
FROM alpine:3.21

# 从构建阶段复制编译好的 Nginx
COPY --from=builder /usr/local/nginx /usr/local/nginx

# 安装运行依赖
RUN echo "https://mirrors.aliyun.com/alpine/v3.21/main" > /etc/apk/repositories && \
	echo "https://mirrors.aliyun.com/alpine/v3.21/community" >> /etc/apk/repositories  && \
	apk add --no-cache pcre zlib openssl && \
	ln -sf /dev/stdout /usr/local/nginx/logs/access.log && \
	ln -sf /dev/stderr /usr/local/nginx/logs/error.log

# 复制自定义配置文件（可选）
#COPY nginx.conf /usr/local/nginx/conf/nginx.conf

# 暴露端口
EXPOSE 80 443

# 启动 Nginx
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
```

## 4.2 构建 Go 应用镜像

```dockerfile
FROM golang:bullseye AS builder
WORKDIR /
RUN cat <<EOF > hello.go
package main
 import (
 "fmt"
 "time"
 )
 func main() {
 for {
      fmt.Println("hello,world!")
      time.Sleep(time.Second)
   }
 }
EOF
RUN go build hello.go

FROM scratch
COPY --from=builder /hello /
CMD ["/hello"]
```

## 4.3 构建 Vue 项目

测试项目：https://gitee.com/lbtooth/myblog_admin/blob/master/Dockerfile

```bash
FROM node:14.17.6 AS build
COPY . /opt/vue
WORKDIR /opt/vue
RUN sed -i 's/config.headers/\/\/&/' src/api/request.js
RUN npm install --registry https://registry.npm.taobao.org && npm run build

FROM nginx:1.20.1
COPY --from=build /opt/vue/dist /opt/vue/dist
COPY nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g","daemon off;"]
```

