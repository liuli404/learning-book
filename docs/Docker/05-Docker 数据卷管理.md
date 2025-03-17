# 一、容器的存储介绍

## 1.1 容器的分层

Docker镜像由多个**只读层叠加**而成，启动容器时，Docker会加载只读镜像层并在镜像栈顶部添加一个**读写层**。

如果运行中的容器修改了现有的一个已经存在的文件，那该文件将会从读写层下面的只读层复制到读写层，该文件的只读版本仍然存在，只是已经被读写层中该文件的副本所隐藏，此即“写时复制(COW copy  on write)"机制

容器的所有的活动数据都将存储在这一层，如果将容器删除，那么该层数据将随之删除（可以通过 commit 将容器保存成镜像后，该层也变为了镜像的只读层）

![img](./05-Docker%20%E6%95%B0%E6%8D%AE%E5%8D%B7%E7%AE%A1%E7%90%86/27101751_61c9224f465d149188.jpg)

虽然COW机制节约磁盘空间，但是会导致性能低下，如果容器需要持久保存数据，且并不影响性能的情况下，可以用数据卷技术实现。

如下图是将对根的数据写入到了容器的可写层，但是把`/data`中的数据写入到了一个另外的 `volume` 中用于数据持久化，该 `volume` 可以是宿主机文件系统上的一块高性能SSD存储设备。这样保证了容器数据读写的性能，数据也不会受容器生命周期的影响销毁。

![image-20250307205145807](./05-Docker%20%E6%95%B0%E6%8D%AE%E5%8D%B7%E7%AE%A1%E7%90%86/image-20250307205145807.png)

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

## 1.2 容器存储的挂载

Docker支持以下类型的存储挂载，用于在容器外存储数据：

- **Volume mounts**

  这是 Docker 推荐的挂载方式。卷是完全由 **Docker 管理的文件目录**，可以在容器之间共享和重用。在创建卷时，Docker 创建了一个目录在宿主机上，然后将这个目录挂载到容器内。卷的主要优点是你可以使用 Docker CLI 或 Docker API 来备份、迁移或者恢复卷，而无需关心卷在宿主机上的具体位置。

- **Bind mounts**

  这种方式可以将**宿主机上的任意文件或目录**挂载到容器内。与卷不同，绑定挂载依赖于宿主机的文件系统结构。由于它们没有被Docker隔离，主机上的非Docker进程和容器进程都可以同时修改挂载的文件。当有容器和宿主机共同访问同一个文件时，可以使用Bind mounts。

- **tmpfs mounts**

  tmpfs 挂载不与宿主机上的任何文件或目录相关联，而是将一个**临时文件系统**挂载到容器的某个目录下。这种方式的主要优点是它提供了一个高速且安全的挂载方式，因为 tmpfs 挂载通常驻留在**宿主机的内存中**，且在容器停止后会被自动删除。 tmpfs 挂载是临时的，只存留在容器宿主机的内存中。当容器停止时，tmpfs 挂载文件路径将被删除，在那里写入的文件不会被持久化。

- **Named pipes**

​	命名管道可用于Docker主机和容器之间的通信。常见的用例是在容器内部运行第三方工具，并使用命名管道连接到Docker引擎API。

# 二、容器的存储操作

## 2.1 数据卷 

Volume mounts 是 docker 推荐的一种数据持久化方式，由Docker创建和管理，也常被称为管理卷。


Volume 分为 Named volumes（命名卷）和 Anonymous volumes（匿名卷）。

- Named volumes：命名卷就是有名字的卷，使用 `docker volume create <卷名>` 形式创建并命名的卷。在用过一次后，以后挂载容器的时候还可以使用，因为有名字可以指定。所以一般需要保存的数据使用命名卷保存。使用命名卷的好处是可以复用，其它容器可以通过这个命名数据卷的名字来指定挂载，共享其内容。
- Anonymous volumes：匿名卷就是没名字的卷，一般是 `docker run -v /data` 这种不指定卷名的时候所产生，或者 Dockerfile 里面的 `VOLUME` 指令定义直接使用的。匿名卷则是随着容器建立而建立，随着容器消亡而淹没于卷列表中（并不会销毁）。因此匿名卷只存放无关紧要的临时数据，随着容器消亡，这些数据将失去存在的意义。

数据卷最佳实践：容器运行中，不应该在存储层有数据写入操作，所有的新增数据写入应该在数据卷中。所以在制作镜像的时候，就应该使用 `VOLUME` 指令定义好未来会发生大量读写操作的目录。即使用户没有为该目录指定命名卷，docker 也会将该目录创建为匿名卷，将数据存放在容器外。

例如，使用 Dockerfile 中 `VOLUME /data` ，即使容器启动的时候用户忘记使用 `-v` 参数指定数据卷，docker 也会将容器中的 `/data` 目录作为匿名卷，挂载到宿主机中。这样向 `/data` 写入的操作不会写入到容器存储层，而是写入到了匿名卷中。

### 2.1.1 创建匿名卷

使用 `docker run -v <容器内路径> 镜像名` 创建容器并自动创建匿名卷。

```bash
# 匿名卷，只指定容器内路径，没有指定宿主机路径信息
# 如果初始容器中有旧数据，默认将被复制到宿主机数据卷/var/lib/docker/volumes/<卷ID>/_data目录
docker run -v /etc/nginx nginx:latest
```

使用 `docker volume` 可查看数据卷列表。

```bash
# docker volume ls
DRIVER    VOLUME NAME
local     c591b0ebf1feb37a12210375eff05aeaab3d3ad323659d792d4c07f14b58d61d
# docker volume inspect c591b0ebf1feb37a12210375eff05aeaab3d3ad323659d792d4c07f14b58d61d 
[
    {
        "CreatedAt": "2025-03-13T14:08:58Z",
        "Driver": "local",
        "Labels": {
            "com.docker.volume.anonymous": ""
        },
        "Mountpoint": "/var/lib/docker/volumes/c591b0ebf1feb37a12210375eff05aeaab3d3ad323659d792d4c07f14b58d61d/_data",
        "Name": "c591b0ebf1feb37a12210375eff05aeaab3d3ad323659d792d4c07f14b58d61d",
        "Options": null,
        "Scope": "local"
    }
]
```

删除容器后，查看匿名卷还存在，容器中的数据也存在目录中。

```bash
# docker volume ls
DRIVER    VOLUME NAME
local     c591b0ebf1feb37a12210375eff05aeaab3d3ad323659d792d4c07f14b58d61d
# ls /var/lib/docker/volumes/c591b0ebf1feb37a12210375eff05aeaab3d3ad323659d792d4c07f14b58d61d/_data/
conf.d  fastcgi_params  mime.types  modules  nginx.conf  scgi_params  uwsgi_params
```

使用 `docker rm -v 容器名` 参数，可以删除容器时，顺便删除容器的匿名卷。

### 2.1.2 创建命名卷

使用 `docker run -v <卷名>:<容器内路径> 镜像名` 创建容器并自动创建命名卷。

```bash
# 如果初始容器中有旧数据，将被复制到宿主机数据卷/var/lib/docker/volumes/<卷名>/_data目录
docker run -v nginx:/etc/nginx nginx:latest
```

查看数据卷

```bash
# docker volume ls 
DRIVER    VOLUME NAME
local     nginx
# docker volume inspect nginx 
[
    {
        "CreatedAt": "2025-03-13T14:15:34Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/nginx/_data",
        "Name": "nginx",
        "Options": null,
        "Scope": "local"
    }
]
```

删除容器后，查看命名卷还存在，容器中的数据也存在目录中。

```bash
# ls /var/lib/docker/volumes/nginx/_data/
conf.d/         fastcgi_params  mime.types      modules         nginx.conf      scgi_params     uwsgi_params
```

使用 `docker rm -v 容器名` 参数，删除容器时，并**不会删除**容器的命名卷，因为即使容器不在了，数据卷也有名字，后续仍可给其他容器使用。

也可以通过 `docker volume  create <卷名>` 提前创建命名卷，但一般不用这个命令。

### 2.1.3 删除数据卷

可以使用 `docker volume rm <卷名/卷ID>`  删除指定卷，或者使用 `docker volume prune`清除所有没容器使用的匿名卷，`-a` 参数清除所有没在使用的数据卷（包括命名卷）。

```bash
# docker volume rm nginx 
nginx

# docker volume prune 
WARNING! This will remove anonymous local volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
Deleted Volumes:
59ef52bd14951127eea592895fdc9820d7d2d204ffbd67ca77198e144e6e8812
0871eebc559caa3df3e2287352f4f6cfa3f365c9562e1ebc71f2efa9bb0cc230
5d934ff08a07643c7dc24262defe5293ac75f76ff28090ec365e298f6d1a9ab2

Total reclaimed space: 28.26kB


# docker volume prune -a
WARNING! This will remove all local volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
Deleted Volumes:
nginx

Total reclaimed space: 9.419kB
```



## 2.2 绑定挂载

通过在 `docker run` 指令后面可以带上 `-v` 或 `--volume` 参数创建数据卷和绑定挂载：

```bash
-v, --volume=[host-src:]container-dest[:<options>]

[host-src] 宿主机目录如果不存在,会自动创建
[<options>]
	ro 从容器内对此数据卷是只读，不写此项默认为可读可写
	rw 从容器内对此数据卷可读可写,此为默认值
```

### 2.2.1 创建绑定挂载

```bash
# 注意：如果初始容器中有旧数据，将被宿主机目录覆盖
# 注意：如果挂载文件，必须指定文件的相对或绝对路径，否则会将文件名当成命名卷
# 注意：如果你想挂载一个文件，确保目标路径也是一个文件；如果你想挂载一个目录，确保目标路径也是一个目录。
docker run -v /data/nginx:/etc/nginx nginx:latest
docker run -P -v /data/html/index.html:/usr/share/nginx/html/index.html nginx:latest
```

### 2.2.2 多个容器同时挂载

通过绑定挂载，可以将宿主机上的文件同时被多个容器使用，实现多个容器共享数据

```bash
docker run --name nginx01 -P -v /data/html/index.html:/usr/share/nginx/html/index.html nginx:latest
docker run --name nginx02 -P -v /data/html/index.html:/usr/share/nginx/html/index.html nginx:latest
```

### 2.2.3 使用只读绑定挂载

默认数据卷为可读可写，一般情况下，容器只需要读访问绑定挂载的目录文件，防止容器中的操作影响到docker宿主机上的文件。

```bash
docker run -v /data/html/index.html:/usr/share/nginx/html/index.html:ro nginx:latest
```

容器中写入测试

```bash
# cat 123456 > /usr/share/nginx/html/index.html
bash: /usr/share/nginx/html/index.html: Read-only file system
```

### 2.2.4 删除绑定卷

绑定挂载与数据卷挂载不同，绑定挂载到宿主机的卷不受docker管理，所以需要通过宿主机来管理。

```bash
rm -rf /data/nginx
rm -rf /data/html
```

### 2.2.5 数据卷与绑定挂载区别

绑定挂载可以理解为宿主机的文件目录挂载进容器里，将容器里被挂载的目录覆盖掉。

数据卷理解为将容器中的文件目录挂载出来，到宿主机上。

与数据卷相比，绑定挂载的功能有限。但是绑定挂载的性能非常好，可以将绑定挂载的目录放在类似SSD存储文件系统上。

# 三、数据卷容器

Data Volume Container 数据卷容器是一种特殊的 Docker 容器，它可以作为一个纯数据容器而不运行任何应用，只提供一个数据共享功能，可以将数据在多个容器间共享，如下图，Data Container 作为数据卷容器，Container1、2、3容器可以通过数据卷共享挂载Data Container中的数据卷。

![image-20250313232453386](./05-Docker%20%E6%95%B0%E6%8D%AE%E5%8D%B7%E7%AE%A1%E7%90%86/image-20250313232453386.png)

## 3.1 创建数据卷容器

`docker run` 命令的以下选项可以实现数据卷容器，格式如下: 

```bash
--volumes-from <数据卷容器>     从指定的容器装载卷
```

```bash
docker run --name volume-server -v /data/nginx:/data/nginx centos:latest
# 从volume-server复制挂载关系
docker run --name nginx01 --volumes-from volume-server nginx:latest
docker run --name nginx02 --volumes-from volume-server nginx:latest
```

这样 `nginx01` 与 `nignx02` 都可以访问 `volume-server` 中的数据卷 `/data/nginx`

## 3.2 使用数据卷容器做备份

可以通过数据卷容器轻松备份数据。

例如备份MySQL的数据目录：

1. 创建MySQL容器，容器默认使用了匿名卷

   ```bash
   docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=Abc123456 mysql:5.7.30
   ```

2. 运行一个 MySQL 客户端，向刚刚创建的MySQL中写入数据

   ```bash
   docker run mysql:5.7.30 mysql -h192.168.100.13 -uroot -pAbc123456 -e "CREATE DATABASE mydatabase;"
   ```

3. 查看数据库数据目录

   ```bash
   docker exec mysql ls /var/lib/mysql/
   ```

4. 创建数据卷容器并备份MySQL的数据目录，将数据备份到宿主机的 /data/backup 目录中

   ```bash
   docker run --rm --volumes-from mysql -v /data/backup:/backup busybox:latest tar -cvf /backup/backup.tar /var/lib/mysql
   ```

5. 查看备份的数据并模拟数据库还原

   ```bash
   # ls /data/backup/
   backup.tar
   ```

   ```bash
   # 新创建一个mysql容器
   docker run -d --name mysql02 -p 3307:3306 -e MYSQL_ROOT_PASSWORD=Abc123456 mysql:5.7.30
   # 利用数据容器还原备份数据
   docker run --rm --volumes-from mysql02 -v /data/backup:/backup busybox:latest tar -xvf /backup/backup.tar
   ```

6. 查看 `mysql02` 的数据库数据

   ```bash
   docker exec mysql02 mysql -h127.0.0.1 -uroot -pAbc123456 -e "SHOW DATABASES;"
   ```

通过数据卷容器，可以实现在不影响主程序容器运行的情况下，对容器的数据进行备份。
