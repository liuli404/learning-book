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

## 1.2 Docker 核心技术

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



# 二、Docker 安装

## 2.1 Rocky 系统安装

## 2.2 Ubuntu 系统安装

## 2.3 二进制离线安装