# 一、Docker Compose 介绍安装

当在宿主机启动较多的容器时候，如果都是手动操作会觉得比较麻烦而且容易出错，此时推荐使用 docker 单机编排工具 `docker-compose`。

- 官网地址：https://docs.docker.com/compose/
- github地址：https://github.com/docker/compose

![1742218443372](./08-Docker%20Compose%E7%BC%96%E6%8E%92/1742218443372.jpg)

`docker compose` 将所管理的容器分为三层，分别是工程（project），服务（service）以及容器（container），通过合理的编排`compose.yaml`文件，可以解决多个容器之间的依赖关系，且可以替代docker命令对容器进行创建、启动和停止等手工的操作。

`docker compose`有很多种安装方式，可以直接使用在线包安装，例如`apt install docker-compose`、`dnf install docker-compose`，基本上每个系统都有对应的在线安装方式。

不过还有另一种比较常用的离线包安装方式，直接使用二进制程序：https://github.com/docker/compose/releases

```bash
# 将下载的二进制文件改名放到 /usr/bin 目录
curl -L https://github.com/docker/compose/releases/download/v2.33.1/docker-compose-linux-x86_64 -o /usr/bin/docker-compose
# 添加可执行权限
chmod +x /usr/bin/docker-compose
```

查看`docker compose`版本

```bash
# docker compose version
Docker Compose version v2.33.1
```

`docker compose` 主要按照 `compose.yaml` 文件作为配置文件进行对容器的编排，该文件名可以是 `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, `compose.yaml`。

# 二、Compose 文件详解

compose文件是一个yaml格式的文件，所以注意行首的缩进很严格。Compose 文件一共有 6 大顶级元素。

## 2.1 Version 和 Name

`version` 字段已经过时了，所以后续的compose文件可以不指定版本。

`name` 字段指定该项目工程的名称，如果不写，则使用默认。

在 compose 中可以使用`COMPOSE_PROJECT_NAME` 变量，获取 name 指定的值。

```yaml
name: myapp

services:
  foo:
    image: busybox
    command: echo "I'm running ${COMPOSE_PROJECT_NAME}"
```

输出

```bash
# docker compose up 
[+] Running 1/1
 ✔ Container myapp-foo-1  Created                                                                                                                                 0.0s 
Attaching to foo-1
foo-1  | I'm running myapp
foo-1 exited with code 0
```

## 2.2 Service

`services` 字段定义了一个或一组容器以及它们所需的镜像、环境变量、映射的端口。

如下 services 定义了三个 service：`web`、`db`与 `proxy`，分别定义了它们的镜像、映射端口、环境变量与数据卷。

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"

  db:
    image: postgres:13
    environment:
      POSTGRES_USER: example
      POSTGRES_DB: exampledb
      
  proxy:
    image: nginx
    volumes:
      - type: bind
        source: ./proxy/nginx.conf
        target: /etc/nginx/conf.d/default.conf
        read_only: true
    ports:
      - 80:80
```

## 2.3 Network

网络允许服务相互通信。默认情况下，Compose会为应用程序设置单个网络。服务的每个容器都加入默认网络，该网络上的其他容器都可以访问。

如下配置定义了两个自定义网络：`frontend` 和 `backend` ，`proxy` 加入 `frontend` 网络，`db` 加入 `backend` 网络。`app` 同时加入了这两个网络，意味着它可以同时访问 `proxy` 与 `db` 。

```yaml
services:
  proxy:
    build: ./proxy
    networks:
      - frontend
  app:
    build: ./app
    networks:
      - frontend
      - backend
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.host_binding_ipv4: "127.0.0.1"
  backend:
    driver: custom-driver
```

## 2.4 Volumes

`volumes` 允许提前声明一个命名卷，并提供给 `services` 挂载，也可以直接在 `services` 的容器中使用 `bind` 卷。

如下配置使用`volumes` 提前创建了 `db-data` 命名卷，映射到容器路径为：`/etc/data` 和`/var/lib/backup/data`

```yaml
services:
  backend:
    image: example/database
    volumes:
      - db-data:/etc/data

  backup:
    image: backup-service
    volumes:
      - db-data:/var/lib/backup/data

volumes:
  db-data:
```

## 2.5 Config

通过 `configs` 字段，可以创建配置，以提供给 `services` 使用。

```yaml
configs:
  http_config:
    file: ./httpd.conf
```

## 2.6 Secret

`Secret` 与 `configs` 字段类似，不过它存储的一般是加密后密钥文件。

```yaml
services:
   db:
     image: mysql:latest
     volumes:
       - db_data:/var/lib/mysql
     environment:
       MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
       MYSQL_DATABASE: wordpress
       MYSQL_USER: wordpress
       MYSQL_PASSWORD_FILE: /run/secrets/db_password
     secrets:
       - db_root_password
       - db_password

   wordpress:
     depends_on:
       - db
     image: wordpress:latest
     ports:
       - "8000:80"
     environment:
       WORDPRESS_DB_HOST: db:3306
       WORDPRESS_DB_USER: wordpress
       WORDPRESS_DB_PASSWORD_FILE: /run/secrets/db_password
     secrets:
       - db_password


secrets:
   db_password:
     file: db_password.txt
   db_root_password:
     file: db_root_password.txt

volumes:
    db_data:
```

# 三、Docker Compose 操作

## 3.1 客户端命令

```bash
# 创建和启动容器
docker compose up [OPTIONS] [SERVICE...]
# 后台启动容器
docker compose up -d [SERVICE...]
# 停止并移除容器、网络
docker compose down [OPTIONS] [SERVICES]
# 查看运行中的容器
docker compose ps [OPTIONS] [SERVICE...]
# 启动服务
docker compose start [SERVICE...]
# 停止服务
docker compose stop [OPTIONS] [SERVICE...]
```

## 3.2 LAMP 架构部署示例

```yaml
services:
  db:
    image: mysql:8.0.29-oracle
    container_name: db
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_ROOT_PASSWORD=123456
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=123456
    volumes:
	  - dbdata:/var/lib/mysql
    networks:
      - wordpress-network

  wordpress:
    depends_on:
      - db
    image: wordpress:php7.4-apache
    container_name: wordpress
	restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=123456
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - wordpress:/var/www/html
    networks:
      - wordpress-network
volumes:
  wordpress:
  dbdata:
networks:
  wordpress-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.30.0.0/16
```



## 3.3 转换docker命令为compose文件

工具网站：`https://www.composerize.com/`，该网站可以将`docker run` 命令转换为 `compose` 文件指令。

![image-20250318160943089](./08-Docker%20Compose%E7%BC%96%E6%8E%92/image-20250318160943089.png)

例如：启动`wordpress`容器命令转换成compose文件

```bash
docker run --name wordpress -d -p 8080:80 --network wordpress-net -v /data/wordpress:/var/www/html --restart=always wordpress:php7.4-apache

docker run --name mysql -d --network wordpress-net -e MYSQL_ROOT_PASSWORD=123456 -e MYSQL_DATABASE=wordpress -e MYSQL_USER=wordpress -e MYSQL_PASSWORD=123456 -v /data/mysql:/var/lib/mysql --restart=always mysql:8.0.29-oracle
```

转换后

```yaml
name: <your project name>
services:
    wordpress:
        container_name: wordpress
        ports:
            - 8080:80
        networks:
            - wordpress-net
        volumes:
            - /data/wordpress:/var/www/html
        restart: always
        image: wordpress:php7.4-apache
    mysql:
        container_name: mysql
        networks:
            - wordpress-net
        environment:
            - MYSQL_ROOT_PASSWORD=123456
            - MYSQL_DATABASE=wordpress
            - MYSQL_USER=wordpress
            - MYSQL_PASSWORD=123456
        volumes:
            - /data/mysql:/var/lib/mysql
        restart: always
        image: mysql:8.0.29-oracle
networks:
    wordpress-net:
        external: true
        name: wordpress-net
```

