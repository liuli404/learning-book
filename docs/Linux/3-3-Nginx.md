# 一、简介
Nginx 是一款轻量级的 Web 服务器/反向代理服务器及电子邮件（IMAP/POP3）代理服务器，并在一个BSD-like 协议下发行。由俄罗斯的程序设计师 Igor Sysoev 所开发，供俄国大型的入口网站及搜索引擎Rambler（俄文：Рамблер）使用。其特点是占有内存少，并发能力强，事实上 nginx 的并发能力确实在同类型的网页服务器中表现较好，中国大陆使用 nginx 网站用户有：百度、京东、新浪、网易、腾讯、淘宝等。

**常见用法：**

1. web 服务器软件（httpd http协议）
> 同类的 web 服务器软件：apache、nginx（俄罗斯）、IIS（微软 fastcgi）、lighttpd（德国）

2. 代理服务器（反向代理）

3. 邮箱代理服务器（IMAP POP3 SMTP）

4. 负载均衡功能（LB  loadblance）

**Nginx架构的特点：**

- **高可靠**：master 进程管理调度请求分发到哪一个 worker=> worker 进程响应请求，单 master 多 worker 架构
> 具有很高的可靠性
- **热部署** ：（1）平滑升级、（2）可以快速重载配置
>热部署：nginx 在修改配置文件之后，不需要重启。
- **高并发**：可以同时响应更多的请求、事件
> 可以高并发连接：相同配置的服务器，nginx 比 apache 能接受的连接多很多。
- **响应快**：尤其在处理静态文件上，响应速度很快

>处理响应请求很快：nginx 处理静态文件的时候，响应速度很快。
- **低消耗**：低 CPU 和内存占用
>低的内存消耗：相同的服务器，nginx 比 apache 低的消耗
- **分布式支持** ：反向代理、七层负载均衡

# 二、发行版本

## 1、Nginx
<https://nginx.org>

> 开源社区版本

## 2、Nginx plus
<https://www.nginx.com>
> 商业授权版本，功能多，有技术支持
## 3、Tengine
<https://tengine.taobao.org>

> tengine 是 alibaba 公司，在 Nginx 的基础上，开发定制，更加服务自己业务的服务器软件。后来进行了开源。

```bash
#解压编译安装
shell > wget http://tengine.taobao.org/download/tengine-2.3.0.tar.gz
shell > tar xvf tengine-2.3.0.tar.gz
shell > cd tengine-2.3.0
shell > ./configure --prefix=/usr/local/tengine
shell > make && make install
# 查看默认加载的模块和参数信息
shell > /usr/local/tengine/sbin/nginx -V
# tengine 默认提供 -m 参数，查看已经编译加载的模块
```
## 4、OpenResty
<https://openresty.org/cn>

> openresty 在 Nginx 的基础上，结合 lua 脚本实现高并发的 web 平台。
> WAF nginx+lua+redis  实现应用型防火墙，动态把IP加入黑名。



**编译安装步骤：**

```shell
#解压编译并安装
shell > wget https://openresty.org/download/openresty-1.15.8.1.tar.gz
shell > tar xvf openresty-1.15.8.1.tar.gz
shell > cd openresty-1.15.8.1
shell > ./configure --prefix=/usr/local/openresty
shell > make && make install
#查看默认编译参数及其模块
shell > /usr/local/openresty/sbin/openresty -V
```

# 三、安装
## 1、脚本安装
```bash
#!/bin/bash
# CentOS 7.9 Nginx 一键安装脚本

# 创建软件运行用户
`id www` &>> /dev/null
if [ $? -ne 0 ];then
   useradd -s/sbin/nologin -M www
fi

# 安装依赖
yum install -y openssl openssl-devel zlib zlib-devel pcre pcre-devel make gcc gcc-c++

# 配置
wget http://nginx.org/download/nginx-1.20.1.tar.gz
tar xvf nginx-1.20.1.tar.gz
cd nginx-1.20.1
./configure \
--prefix=/usr/local/nginx \
--user=www \
--group=www \
--with-compat \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' \
--with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'

# 编译安装
make -j `cat /proc/cpuinfo | grep 'processor' | wc -l`&& make install

# vim 语法高亮
cp -r contrib/vim/* /usr/share/vim/vim74/

# 软链接到系统命令
ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx

# 启动脚本
cat > /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=nginx
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/sh -c "/bin/kill -s HUP $(/bin/cat /usr/local/nginx/logs/nginx.pid)"
ExecStop=/bin/sh -c "/bin/kill -s TERM $(/bin/cat /usr/local/nginx/logs/nginx.pid)"

[Install]
WantedBy=multi-user.target
EOF

# 启动并设置开机自启
systemctl start nginx.service && systemctl enable nginx.service
```
## 2、目录结构
查看安装目录 /usr/local/nginx

| 目录 | 作用                                 |
| ---- | ------------------------------------ |
| conf | 配置文件                             |
| html | 网站默认目录                         |
| logs | 日志                                 |
| sbin | 可执行文件  [软件的启动 停止 重启等] |

## 3、命令参数
```bash
Options:
#查看帮助
  -?,-h         : this help
#查看版本并退出
  -v            : show version and exit
#查看版本和配置选项并退出
  -V            : show version and configure options then exit
#检测配置文件语法并退出
  -t            : test configuration and exit
#检测配置文件语法打印它并退出
  -T            : test configuration, dump it and exit
#在配置测试期间禁止显示非错误信息
  -q            : suppress non-error messages during configuration testing
#发送信号给主进程  stop强制退出  quit优雅的退出  reopen重开日志   reload重载配置
  -s signal     : send signal to a master process: stop, quit, reopen, reload
#设置nginx目录  $prefix路径
  -p prefix     : set prefix path (default: /usr/local/nginx/)
#指定启动使用的配置文件
  -c filename   : set configuration file (default: conf/nginx.conf)
#在配置文件之外设置全局指令
  -g directives : set global directives out of configuration file
```

## 4、配置文件
```yaml
# nginx子进程启动用户
#user  nobody;
#子进程数量  一般调整为cpu核数或者倍数
worker_processes  1;
#错误日志定义
#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#进程pid 存储文件
#pid        logs/nginx.pid;

#事件
events {
    #每个子进程的连接数         nginx当前并发量  worker_processes * worker_connections
    worker_connections  1024;
}

#http协议段
http {
    #引入  文件扩展名和与文件类型映射表
    include       mime.types;
    #默认文件类型   
    default_type  application/octet-stream;
    #访问日志access.log的格式
    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';
    #访问日志存储路径
    #access_log  logs/access.log  main;
    #linux内核  提供文件读写的机制
    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    #长连接超时时间  单位为s
    keepalive_timeout  65;
    #gzip压缩
    #gzip  on;
    #server虚拟主机的配置
    server {
        #监听端口
        listen       80;
        #域名  可以有多个 用空格分隔
        server_name  localhost;
        #默认编码
        #charset koi8-r;

        #access_log  logs/host.access.log  main;
        #location 用来匹配url
        location / {
            #默认访问的网站路径
            root   html;
            #默认访问页面 从前往后的顺序查找
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}
```




# 四、企业中常见使用方式

## 1、server 配置
在实际生产业务环境中，一台 web 服务器，需要使用多个网站部署。搭建 vhost 虚拟机主机实现不同域名，解析绑定到不同的目录。

```yaml
server {
	# 监听端口
    listen 80;
    # 绑定域名
    server_name shop.lnmp.com;
    # 网站目录
    root html/shop;
    # 默认访问页面
    index index.php index.html;
    # 这段一定不要忘了配置，需要解析php使用到
    location ~ \.php$ {
    	# php-fpm 的 ip:port
    	fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
	}
}
```


## 2、默认官方模块

### 2.1、Gzip 压缩

压缩文件，使文件变小，传输更快了。目前市场上大部分浏览器是支持 GZIP 的。

**官方文档**：<http://nginx.org/en/docs/http/ngx_http_gzip_module.html>

**示例语法：**

```python
# 配置到 http 段里，使整个 http 服务都启用 gzip 压缩
# 开启 gzip 压缩模块
gzip on;
# 设置用于压缩响应的缓冲区的数量和大小
gzip_buffers 16 8k;
# 设置 gzip 压缩级别，值在 1 到 9 之间（值越大，压缩级别越高）
gzip_comp_level 9;
# IE 浏览器不开启 gzip，IE6 以下会乱码
gzip_disable 'MSIE [1-6].';
# 设置压缩所需的最小 HTTP 版本
gzip_http_version 1.0;
# 设置将被压缩的返回值的最小长度
gzip_min_length 20;
# 需要压缩的文件的格式
gzip_types text/plain application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;
gzip_vary off;
```


### 2.2、客户端缓存

告知浏览器获取的信息是在某个区间时间段是有效的。

**官方文档**：<https://nginx.org/en/docs/http/ngx_http_headers_module.html>

**示例语法：**

```yaml
# 缓存常见格式的图片
location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|svg|webm)$
    # 单位参数：d 天 | H 小时 | M 分
    expires 1h;
}
```

### 2.3、基于 IP 的访问控制

基于各种原因，我们要进行访问控制。比如说，一般网站的后台都不能让外部访问，所以要添加 IP 限制，通常只允许公司的 IP 访问。


**官方文档**：<http://nginx.org/en/docs/http/ngx_http_access_module.html>

**示例语法：**

```bash
location / {
	# 禁止 192.168.1.1 访问
    deny 192.168.1.1;
    # 允许某个网段访问
    allow 192.168.1.0/24;
    allow 10.1.1.0/16;
    allow 2001:0db8::/32;
    # 禁止所有访问
    deny all;
}
```

### 2.4、基于用户的访问控制
验证用户名和密码来限制对资源的访问。

**官方文档**：<http://nginx.org/en/docs/http/ngx_http_auth_basic_module.html>

**配置实现：**

```bash
# 安装 htpasswd 工具
yum install -y httpd-tools
# 创建用户名和密码存储文件
htpasswd -c /etc/nginx/passwd.db test_user
```

**示例语法：**
```bash
location / {
	# 登录框显示的标题提示
    auth_basic "closed site";
    # 加载用户名称和密码校验文件
    auth_basic_user_file /etc/nginx/passwd.db; 
}
```

### 2.5、目录列表显示

显示文件列表，或者需要做一个下载列表

官方文档：<https://nginx.org/en/docs/http/ngx_http_autoindex_module.html>

**示例语法：**

```bash
# 开启目录列表显示
autoindex on;
```

###  2.6、正反代理

- **正向代理**

客户知道自己使用了代理，需要填写代理服务器的 IP 等相关连接信息，**常见于代理客户端上网等操作。**

![在这里插入图片描述](https://img-blog.csdnimg.cn/4508416ddf0c46f98d4aba7e9c64e25f.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)

- **反向代理**

用户是无感知的，不知道使用了代理服务器。反向代理服务器是和真实访问的服务器是在一起的，有关联的。
![在这里插入图片描述](https://img-blog.csdnimg.cn/34a5ed882a1b41c3b735dac685dfae9e.png?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_11,color_FFFFFF,t_70,g_se,x_16)



作用：
- 可以根据实际业务需求，分发代理页面到不同的解释器
- 可以隐藏真实服务器的路径，**常见于代理后端服务器**

**官方文档**：<http://nginx.org/en/docs/http/ngx_http_proxy_module.html>

```bash
server {
	listen 80;
	# 监听地址
    server_name  lnmp.server;
	location / {
		# 请求转向
		proxy_pass http://127.0.0.1:8080;
	}
}
```
## 3、第三方模块使用
Nginx 官方没有的功能，开源开发者定制开发一些功能，把代码公布出来，可以通过**编译加载第三方模块**的方式，**使用新的功能**。

第三方模块网址：<https://www.nginx.com/resources/wiki/modules>

### 3.1、编译安装第三方模块方式
重新编译 nginx ，编译时通过 `--add-module` 添加第三方模块

```bash
# echo
wget https://github.com/openresty/echo-nginx-module/archive/refs/tags/v0.62.tar.gz
# fancyindex
wget https://github.com/aperezdc/ngx-fancyindex/releases/download/v0.5.2/ngx-fancyindex-0.5.2.tar.xz
```

```bash
tar -zxvf v0.62.tar.gz;tar -xvf ngx-fancyindex-0.5.2.tar.xz
```

```bash
./configure \
--prefix=/usr/local/nginx \
--user=www \
--group=www \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--add-module=/root/echo-nginx-module-0.62 \
--add-module=/root/ngx-fancyindex-0.5.2
```

```bash
make && make install && make upgrade
```

### 3.2、fancy-index
**fancy-index 模块美化列表效果**
![在这里插入图片描述](https://img-blog.csdnimg.cn/1c8d04689eee4b29bd9e7094c7fc9dec.jpg)
**配置实现**

```bash
# 可以配置到 http、server、location 等下。推荐配置到 server 下
# 开启 fancyindexes 列表显示功能
fancyindex on;
# 显示更为可读的文件大小
fancyindex_exact_size off;
```

### 3.3、echo

**echo 模块常用来进行调试用，比如输出打印 Nginx 默认系统变量**

**配置实现**

```bash
location / {
    # 输出为文本类型
    default_type text/plain;
    # 打印输出查看变量信息，验证是否一下 $document_root 是否和 root 设定的值一致
    echo $document_root;
}
```
## 4、负载均衡

### 4.1、主机架构
![在这里插入图片描述](https://img-blog.csdnimg.cn/d7b94cb4fd4146eabf92b08d94669006.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)
|主机名| ip | 角色
|--|--| --|
|server01 | 192.168.1.6| web1
|server02 | 192.168.1.7| web2
|server03 | 192.168.1.8| web3
|server04 | 192.168.1.9| load balance  
|server05 | 192.168.1.10| load balance 备用


### 4.2、负载均衡技术

负载均衡技术（load blance）是一种概念，把资源的使用进行平均分配。

负载均衡：分发流量、请求到不同的服务器。使流量平均分配（理想的状态的）

**作用：**

服务器容灾   流量分发

**主要作用：**

① 流量分发、请求平均、降低单例压力

**其他作用：**

② 安全、隐藏后端真实服务

③ 屏蔽非法请求（七层负载均衡）

### 4.3、负载均衡分类
![请添加图片描述](https://img-blog.csdnimg.cn/c7e4d339e71a410887bf84802066c024.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)


**1）二层负载均衡（mac）**

根据OSI模型分的二层进行负载，一般是用虚拟mac地址方式，外部对虚拟MAC地址请求，负载均衡接收后，再分配后端实际的MAC地址响应 

**2）三层负载均衡（ip）**

一般采用虚拟IP地址方式，外部对虚拟的ip地址请求，负载均衡接收后，再分配后端实际的IP地址响应

**3）四层负载均衡（tcp）**  网络运输层面的负载均衡

在三层负载均衡的基础上，用ip+port接收请求，再转发到对应的机器

**4）七层负载均衡（http）**  智能型负载均衡

根据虚拟的url或IP，主机接收请求，再转向（反向代理）相应的处理服务器

### 4.4、常见实现方式

| OSI分层 | 实现方式                         |
| ------- | -------------------------------- |
| 七层    | Nginx、HAProxy                   |
| 四层    | LVS、HAProxy、Nginx（1.9版本后） |

![请添加图片描述](https://img-blog.csdnimg.cn/87cd3f67034a40dab616311c86bae55d.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_11,color_FFFFFF,t_70,g_se,x_16)


**四层和七层对比:**
![在这里插入图片描述](https://img-blog.csdnimg.cn/f58ed0afe5c141ab8bcd01f73a03c7a4.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_17,color_FFFFFF,t_70,g_se,x_16)

### 4.5、Nginx 七层负载均衡配置

**官方文档**：<http://nginx.org/en/docs/http/ngx_http_upstream_module.html>

**架构分析：**

1. 用户访问请求 Nginx 负载均衡服务器
2. Nginx 负载均衡服务器再分发请求到 web 服务器

**实现步骤：**

① 将域名（`www.liuli.com`）解析到负载均衡服务器

② 修改负载均衡服务器的 Nginx 配置

**配置文件示例**：

```yaml
http {
	····
	# 分发请求到后端服务器
    upstream backend {
        # web1 server01
        server 192.168.1.6;
        # web2 server02
        server 192.168.1.7;
        # web3 server03
        server 192.168.1.8;
    }
    # 修改 server 段配置
    server {
        listen 80;
        server_name www.liuli.com;
		location / {
        # 代理转发到 backend 段  匹配到上面的 upstream
        proxy_pass http://backend;
        # 传输域名给后端服务器  进行识别，方便匹配对应 server 虚拟主机
        proxy_set_header Host $host;
        # 发送客户端 IP 给后端 backend 服务器，用来方便 backend 服务器识别客户端真实 IP
        proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

**③ 重载负载均衡服务器 Nginx 配置测试查看效果**

可以停掉其中一台 web 服务器进行测试

### 4.6、获取客户端真实 IP

> 负载均衡之后，在后端的 web 服务器获取到的是负载均衡服务器的 IP，而不能够获取到客户端的真实 IP 

需要进行以下特殊配置：

1. 首先在负载均衡服务器中配置，转发客户端 IP 给后端 web 服务器：`proxy_set_header X-Real-IP $remote_addr;`
2. 后端 web 服务器需要配置，识别从负载均衡服务器传输过来的客户端真实 IP：`set_real_ip_from  192.168.1.9`

**官方网址**：<http://nginx.org/en/docs/http/ngx_http_realip_module.html>

**使用 `ngx_http_realip_module` 模块提供的 `set_real_ip_from` 语法，默认此模块没有安装，需要编译时添加编译参数**

**示例配置：**

```yaml
# 此配置在 web 服务器上的 nginx
# 可配置到 http、server、location 中，推荐配置到 server 中
set_real_ip_from  192.168.1.9;
```

### 4.7、upstream 关键字

upstream 中的分发之后的几个关键字

- `backup`：备用服务器，没有 backup 标识的后端服务器都无响应后，才分发流量到 backup 服务器
- `down`：标记此条配置后，后端服务器将不会被分发流量

```yaml
    upstream backend {
        # web1 server01
        server 192.168.1.6;
        # web2 server02
        server 192.168.1.7;
        # web3 server03，备用服务器，只有 web1、web2 全都挂掉才会启用该服务器
        server 192.168.1.8 backup;
    }
```

### 4.8、session 一致性问题

**访问管理后端页面，登录发现验证码不通过**
![在这里插入图片描述](https://img-blog.csdnimg.cn/58436acd7fda4b8da3c84817165b338e.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)


**分析原因：**

① 登录时分发到 web1 服务器，生成验证码，存储到 session 中，默认在服务器本地

② 再次校验的时候，请求分发到 web2 服务器了，所有验证码一直校验不通过

**解决方案思路：**

① 生成和验证 session 都请求同一台服务器（ip_hash 负载均衡算法）

② 使用共享 session 软件，memcached、redis

### 4.9、Nginx 的负载均衡算法

**Nginx 官方默认3种负载均衡的算法**

- Round-Robin  RR轮询（默认）：一次一个的来（理论上的，实际实验可能会有间隔）
- weight 权重：权重高多分发一些，服务器硬件更好的设置权重更高一些
- ip_hash：同一个IP，所有的访问都分发到同一个 web 服务器

**第三方模块实现的调度算法（需要编译安装第三方模块）**

- fair：根据后端服务器的繁忙程度，将请求发到非繁忙的后端服务器
- url_hash：如果客户端访问的 url 是同一个，将转发到同一台后端服务器

**加权轮询算法**

```yaml
    upstream backend {
        # web1 server01
        server 192.168.1.6 weight=5;
        # web2 server02
        server 192.168.1.7 weight=3;
        # web3 server03
        server 192.168.1.8 weight=2;
    }
```

**ip 一致性算法**


```yaml
    upstream backend {
    	# ip hash 一致性算法配置，设置此项，weight 就失效了
        ip_hash;
        # web1 server01
        server 192.168.1.6 weight=5;
        # web2 server02
        server 192.168.1.7 weight=3;
        # web3 server03
        server 192.168.1.8 weight=2;
    }
```

### 4.10、实现负载均衡高可用

所有的请求流量，都要经过负载均衡服务器，负载均衡服务器压力很大，防止它宕机，导致后端服务所有都不可用，需要对负载均衡服务器，做高可用。

给负载均衡服务器 server04 做一台备用服务器 server05，通过 keepalived 实现高可用。
![在这里插入图片描述](https://img-blog.csdnimg.cn/80dbf607219343aaaa6c979c4ab059bf.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)

主负载均衡的keepalived配置

```shell
vrrp_instance VI_1 {
    state master
    interface ens33
    # 虚拟路由 ID 新 ID 不要之前的冲突
    virtual_router_id 52
    priority 100
    nopreempt
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        # VIP
        192.168.1.100
    }
    track_script {
        check_nginx
    }
}
```

备负载均衡的keepalived配置

```shell
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    # 修改route_id
    virtual_router_id 52
    priority 99
    nopreempt
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        # VIP
        192.168.1.100
    }
    track_script {
        check_nginx
    }
}

```


# 五、日志管理
## 1、访问日志
`access.log` 访问日志，查看统计用户的访问信息、流量

官方文档：<http://nginx.org/en/docs/http/ngx_http_log_module.html>

查看访问日志相关参数

```bash
# 定义日志格式、格式命名、详细格式参数
log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';

# 访问日志的存储路径配置、调用的日志格式
access_log  /var/log/nginx/access.log  main;
```


| 参数                  | 意义                                                 |
| :-------------------- | :---------------------------------------------------- |
| **$remote_addr**      | 客户端的ip地址(代理服务器，显示代理服务ip)           |
| $remote_user          | 用于记录远程客户端的用户名称（一般为“-”）            |
| **$time_local**           | 用于记录访问时间和时区                               |
| **$request**        | 用于记录请求的url以及请求方法                        |
| $status           | 响应状态码，例如：200成功、404页面找不到等。         |
| $body_bytes_sent      | 给客户端发送的文件主体内容字节数                     |
| $http_referer         | 可以记录用户是从哪个链接访问过来的                   |
| **$http_user_agent**  | 用户所使用的代理（一般为浏览器）                     |
| $http_x_forwarded_for | 可以记录客户端IP，通过代理服务器来记录客户端的ip地址 |




## 2、错误日志
`error.log` 错误日志，记录一些启动和运行过程中的错误信息

官方文档：<http://nginx.org/en/docs/ngx_core_module.html#error_log>

```bash
# 定义开启错误日志、日志位置、日志级别
error_log /var/log/nginx/error.log;
error_log /var/log/nginx/error.log warn;
error_log /var/log/nginx/error.log info;

# 默认显示 error 级别，其他的级别 debug, info, notice, warn, error, crit, alert, emerg。
```
## 3、自定义日志格式

```bash
# 自定义日志格式、定义 http 块里
log_format  mylogs  '[$remote_addr] - [$time_local] - [$http_user_agent]';
```

## 4、基于域名日志分割
```bash
# 在 server 段里面配置、也就是在当前 server 里的访问日志，会被写入定义的这里
# 访问日志的存储路径配置、调用的日志格式
access_log  logs/$host.access.log  mylogs;
```

# 六、URL 匹配之 location
Location 配置语法：<http://nginx.org/en/docs/http/ngx_http_core_module.html#location>

## 
location 块用于匹配请求的 URI (Uniform Resource Identifier，URI)

URI 表示的是 web 上每一种可用的资源，如 HTML 文档、图像、视频片段、程序等都由一个 URI 进行定位的。

## 1、精确匹配

```nginx
location = / {
    # 规则
}
```
> 则匹配到 http://www.example.com/ 这种请求

## 2、区分大小写

```nginx
location ~ /Example/ {
    # 规则
}
```
> 请求示例
> http://www.example.com/Example/  [成功]
> http://www.example.com/example/  [失败]

## 3、忽略大小写

```nginx
location ~* /Example/ {
    # 规则
}
```
> 请求示例
> http://www.example.com/Example/  [成功]
> http://www.example.com/example/  [成功]

## 4、只匹配以 uri 开头

```nginx
location ^~ /img/ {
    # 规则
}
```
>请求实例
>以 /img/ 开头的请求，都会匹配上
>http://www.example.com/img/a.jpg   [成功]
>http://www.example.com/img/b.mp4 [成功]
>http://www.example.com/bimg/b.mp4 [失败]
>http://www.example.com/Img/b.mp4 [失败]

## 5、其他匹配都不成功，就匹配此项

```nginx
location / {
   # 规则
}
```

如果路径是资源文件是存在的，会优先获取资源文件

> **location匹配优先级**
>
> (location =) > (location 完整路径) > (location ^~ 路径) > (location ~,~* 正则顺序) > (location 部分起始路径) > (/)

## 6、location 匹配跳转

**@+name** nginx 内部跳转

```nginx
location /img/ {
    # 如果状态码是404  就指定404的页面
    error_page 404 = @img_err;
}    

location @img_err {    
    # 规则
    return  503；
}
```

>以 /img/ 开头的请求，如果链接的状态为 404。则会匹配到 @img_err 这条规则上

# 七、URL重写

> **ngx_http_rewrite_module** 模块用于使用 PCRE 正则表达式更改请求 URI，返回重定向，以及有条件地选择配置

**官方文档地址**：<http://nginx.org/en/docs/http/ngx_http_rewrite_module.html>

## 1、return

该指令用于结束规则的执行并返回状态码给客户端.

> 403 Forbidden.服务器已经理解请求,但是拒绝执行它
>
> 404 Not Found.请求失败,请求所希望得到的资源未在服务器上发现.404这个状态码被⼴泛应⽤于当服务器不想揭示为何请求被拒绝,或者没有其他适合的响应可⽤的情况下.
>
> 500 Internal Server Error.服务器遇到⼀个未曾预料的状况,导致它无法完成对请求的处理.⼀般来说,这个问题都会在服务器的程序码出错时出现.
>
> 502 Bad Gateway.作为网关或代理工作的服务器尝试执行请求时,从上游服务器接收到无效的响应.
>
> 503 Service Unavailable.由于临时的服务器维护或过载,服务器当前无法处理请求.这个状况是临时的,并且将在一段时间以后恢复.503状态码的存在并不意味着服务器在过载的时候必须使⽤它.某些服务器只不过是希望拒绝客户端的连接.
>
> 504 Gateway Timeout作为网关或代理工作的服务器尝试执行请求时,未能及时从上游服务器(URI标识出的服务器,例如HTTP,FTP,LDAP)或辅助服务器(例如DNS)收到响应。

请求状态码：

<https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status>

**示例语法：**

```bash
# 可以匹配到 server、location、if 中，推荐配置到 location 中
return 403;
```

## 2、rewrite

rewrite  匹配到请求 URI，重写到新的 URI

**官方文档地址**：<http://nginx.org/en/docs/http/ngx_http_rewrite_module.html#rewrite>

**示例语法：**

```bash
# 可以匹配到 server、location、if 中
rewrite '匹配规则' '替代内容' <flag>;
```



 flag 标记说明：

- **last**：本条规则匹配完成后，继续向下匹配新的 location URI 规则，客户端 URL 地址不会发生跳转

- **break**：本条规则匹配完成即终止，不再匹配后面的任何规则，客户端 URL 地址不会发生跳转

- **redirect**：返回 302 临时重定向，浏览器地址会显示跳转后的 URL 地址

- **permanent**：返回 301 永久重定向，浏览器地址栏会显示跳转后的 URL 地址


**匹配顺序**：多条rewrite，从上到下匹配，匹配到之后就不在匹配其他rewrite规则。


## 案例：资源重定向实现
**业务需求描述：**

-  实际业务不存在 index.html，需要重写访问 index.php
- URL为 index.html，而实际访问的是 index.php，对外被认为是 html 静态页面
- 以上方案就是seo优化伪静态的使用，把真实的后端的页面，伪装为静态 html 页面。

**示例配置：**

```nginx
rewrite /index.html /index.php last;
```


## 案例：域名重定向实现
**业务需求描述：**
- 网站的域名升级了，需要启用新的域名使用。

- 但是用户却不知道，还可能使用旧的域名访问网站。

- 需要把通过旧域名访问的来源，重定向到新的域名。

- 把 `shop.lnmp.com` 的请求全部重定向到新域名 `www.shop.com`

```nginx
rewrite / http://www.shop.com permanent;
```

**示例配置：**

```nginx
# shop.lnmp.com 的请求全部重定向到 www.shop.com 中
server {
	listen 80;
    server_name shop.lnmp.com;
    rewrite / http://www.shop.com permanent;
}
```
## 案例：防盗链原理和实现
![在这里插入图片描述](https://img-blog.csdnimg.cn/81b5f88341074c8eb19e917594171012.jpg?x-oss-process=image/watermark,type_ZHJvaWRzYW5zZmFsbGJhY2s,shadow_50,text_Q1NETiBA5YiY5p2ONDA0bm90IGZvdW5k,size_15,color_FFFFFF,t_70,g_se,x_16)


**业务需求描述：**

- 域名 A 的资源文件，经常被域名 B 直接调用访问

- 而用户经常访问域名 B，看到的资源（图片、视频）以为是域名 B 的，实际则是域名 A 的。

- 但是域名 A 没有从中获得任何收益，确要给域名 B 来源的访问耗费服务器资源和带宽。

- 所以，禁止域名 B 直接访问和调用域名 A 的资源的方式，就被称为"防止盗链"

```bash
# 图片、视频防盗链
location ~* \.(jpg|png|jpeg|gif|bmp|mp4)$ {
	# 定义允许盗链的域名，一般情况可以把google、baidu、sogou 等搜索引擎加入
    valid_referers *.shop.com *.google.com *.baidu.com;
    # 如果访问的域名不是 valid_referers 中定义的
	if ($invalid_referer) {
		# 全部重写到 404 图片
		#rewrite ^/ http://127.0.0.1/404.jpg;
		# 返回 404 状态码
  	    return 404;
	}
}
```
# 八、安全

## 1、反向代理

实现隐藏真实服务的操作，起到一定安全作用

```bash
server {
	listen 80;
	# 代理域名
    server_name lnmp.server;
	location / {
		# 真实服务
		proxy_pass http://real.server;
	}
}
```

## 2、隐藏版本号

Nginx 对外提供服务，为了避免被针对某个版本的漏洞进行攻击。经常做法是隐藏掉软件的版本信息。提供一定的安全性。

```nginx
# 将以下配置加入到http段配置中
server_tokens off
```

## 3、HTTPS 和 CA

```bash
server {
	listen 443 ssl;
    # 绑定好域名
    server_name web1.server.com;
    # 指定证书相关位置
    ssl_certificate      /ssl/web1.server.com.crt;
    ssl_certificate_key  /ssl/web1.server.com.key;
    ssl_session_cache    shared:SSL:1m;
    ssl_session_timeout  5m;
    ssl_ciphers  HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;

	location / {
    	root   html;
        index  index.html index.htm;
	}
}
# http 跳转到 https
server {
	listen 80;
	server_name web1.server.com;
	rewrite / https://web1.server.com permanent;
}
```


**Tip**：Nginx 支持 pathinfo 路径重写方式

需求

```php
http://www.shop.com/home/goods/index/cate_id/187.html  默认不支持访问
重写成为
http://www.shop.com/index.php?s=home/goods/index/cate_id/187.html
```

语法规则示例

```bash
location / {
   rewrite /index.html /index.php last;
   # 判断请求的路径 不存在
   if (!-e $request_filename) {
      # 捕获到所有路径信息   重写为 index.php 的 s 参数   last 需要匹配之后的 location 规则
      rewrite ^(.*)$   /index.php?s=$1 last;
   }
}
```
# 九、平滑升级
在实际业务场景中，需要使用软件新版本的功能、特性。就需要对原有软件进行升级或者重装操作。

## 1、信号参数

Kill  命令传输信号给进程 Nginx 的主进程

> TERM, INT（快速退出，当前的请求不执行完成就退出） -s stop
> QUIT （优雅退出，执行完当前的请求后退出）  -s quit
> HUP （重新加载配置文件，用新的配置文件启动新worker进程，并优雅的关闭旧的worker进程） -s reload
> USR1 （重新打开日志文件）  -s reopen
> USR2 （平滑的升级nginx二进制文件  拉起一个新的主进程  旧主进程不停止）
> WINCH （优雅的关闭worker进程）

以上几个信息命令都是发送给master主进程的

语法：

```bash
# 快速关闭
kill -INT pid
# 优雅关闭
kill -QUIT pid
```

## 2、平滑升级

升级软件版本之后，需要启动新的版本，启动不了，端口已经被占用

如果直接把旧版本的服务停止掉，会影响线上业务的使用


**最佳解决办法**：
> ① 旧的不先停掉
> ② 新的又可以起来
> ③ 旧的和新的同时提供服务，旧的请求完成之后，就停掉旧进程

使用信号
> -USR2 平滑启动一个进程（平滑升级）
> -WINCH 优雅的关闭子进程
> -QUIT 优雅关闭主进程

### 2.1、方法一
**① 编译安装新版本**

```shell
shell > tar xvf nginx-1.16.0.tar.gz
shell > cd nginx-1.16.0
# configure 配置前先使用 nginx -V 查看老版本的编译参数，新版本要与之相同或新增，不能漏了关键配置
shell > ./configure  --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module
shell > make && make install
# 以上操作完成之后，会把原来的旧版本备份为 nginx.old
```

**② 新旧版本同时运行**

```shell
shell > kill -USR2 主进程号
```

**③ 停止掉旧进程**

查看旧的主进程号，并使用 `kill -WINCH` 优雅的关闭子进程，再关闭旧的主进程

```shell
shell > kill -WINCH 旧的主进程号
shell > kill -QUIT 旧的主进程号
```
### 2.2、方法二（推荐使用）
在 nginx 中，默认提供了平滑升级的操作，只需要执行以下命令

```shell
# 注意需先 configure 配置后，然后在 nginx 源码包执行
shell > make && make install && make upgrade
```

> make upgrade : 相当于手动依次执行了 `kill -USR2`、`kill -WINCH`、`kill -QUIT` 命令

