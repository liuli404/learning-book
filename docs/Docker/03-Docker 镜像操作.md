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
    "WorkDir": 
"/data/docker/overlay2/e831d05f5b3c32def3c0362e4a3028d30e579f24fddf6110427611b756c3dbe6/work"
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

