# 一、数据卷管理

Docker镜像由多个**只读层叠加**而成，启动容器时，Docker会加载只读镜像层并在镜像栈顶部添加一个**读写层**。

如果运行中的容器修改了现有的一个已经存在的文件，那该文件将会从读写层下面的只读层复制到读写层，该文件的只读版本仍然存在，只是已经被读写层中该文件的副本所隐藏，此即“写时复制(COW copy  on write)"机制

容器的所有的活动数据都将存储在这一层，如果将容器删除，那么该层数据将随之删除（可以通过 commit 将容器保存成镜像后，该层也变为了镜像的只读层）

![img](./05-Docker%20%E6%95%B0%E6%8D%AE%E5%8D%B7%E7%AE%A1%E7%90%86/27101751_61c9224f465d149188.jpg)

虽然COW机制节约磁盘空间，但是会导致性能低下，如果容器需要持久保存数据，且并不影响性能的情况下，可以用数据卷技术实现。

如下图是将对根的数据写入到了容器的可写层，但是把`/data`中的数据写入到了一个另外的 `volume` 中用于数据持久化，该 `volume` 可以是宿主机文件系统上的一块高性能SSD存储设备。这样保证了容器数据读写的性能，数据也不会受容器生命周期的影响销毁。

![image-20250307205145807](./05-Docker%20%E6%95%B0%E6%8D%AE%E5%8D%B7%E7%AE%A1%E7%90%86/image-20250307205145807.png)

## 1.1 容器的数据管理介绍

### 1.1.1 容器的分层

通过 `docker inspect` 指令查看容器的详细信息：

- LowerDir：image 镜像层，即镜像本身，只读属性
- MergedDir：容器的文件系统，使用Union FS（联合文件系统）将lowerdir 和 upperdir 合并完成 后给容器使用，最终呈现给用户的统一视图
- UpperDir：容器的上层，可读写，容器变化的数据存放在此处
- WorkDir： 容器在宿主机的工作目录，挂载后内容会被清空，且在使用过程中其内容用户不可见

```json
"Data": {
    "ID": "fb4ddad76e7802ca57e9a26524f7bdaab342f2ef12c0bf19c20f2676d8ad51e5",
    "LowerDir": "/var/lib/docker/overlay2/6d387b867fc38be5e31b23bd39e3b2bfbd119877591721ff346e416220852222-init/diff:/var/lib/docker/overlay2/sp86zs0nk80esq0jh6dr80cd3/diff:/var/lib/docker/overlay2/8p6bh0kgzqab7wk8a6ro0fd65/diff:/var/lib/docker/overlay2/eda597f261676b35d4cea7ca7320dff2378b6711f62204c69d9d3a94daef4d6b/diff",
    "MergedDir": "/var/lib/docker/overlay2/6d387b867fc38be5e31b23bd39e3b2bfbd119877591721ff346e416220852222/merged",
    "UpperDir": "/var/lib/docker/overlay2/6d387b867fc38be5e31b23bd39e3b2bfbd119877591721ff346e416220852222/diff",
    "WorkDir": "/var/lib/docker/overlay2/6d387b867fc38be5e31b23bd39e3b2bfbd119877591721ff346e416220852222/work"
}
```



## 1.2 数据卷

## 1.3 数据卷容器