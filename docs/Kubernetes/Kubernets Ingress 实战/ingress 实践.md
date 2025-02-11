# 一、Ingress 简介

Ingress 可为 Service 提供外部可访问的 URL、负载均衡流量、SSL/TLS，以及基于名称的虚拟托管。相当于 nginx、haproxy 等负载均衡代理服务器

Ingress Controller 可以理解为一个监听器，通过不断地监听 kube-apiserver，实时的感知后端 Service、Pod 的变化，当得到这些信息变化后，Ingress Controller 再结合 Ingress 的配置，更新反向代理负载均衡，达到服务发现的作用。

![ingress](img\ingress.svg)

# 二、Ingress 安装

本文档使用 `ingress-nginx` 组件

官网：https://kubernetes.github.io/ingress-nginx/

github：https://github.com/kubernetes/ingress-nginx

**注意点**：

1. 官方给出的 yaml 文件中拉取的镜像在 `k8s.gcr.io` 中，所以在国内我们拉取就会报错：`ErrImagePull`

```shell
wget -O ingress-nginx-controller.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/1.23/deploy.yaml
```

将 `registry.k8s.io/ingress-nginx` 改为 `registry.cn-hangzhou.aliyuncs.com/google_imgs`

```shell
sed -i 's#registry.k8s.io/ingress-nginx#registry.cn-hangzhou.aliyuncs.com/google_imgs#g' ingress-nginx-controller.yaml
sed -i 's/@sha256:.*$//' ingress-nginx-controller.yaml
```

2. Ingress Controller 中指定使用主机网络 `hostNetwork `位置位于 `spec.tmplate.spec` 下。

```yaml
# 修改成 hostNetwork 模式直接共享服务器的网络名称空间
hostNetwork: true
```

apply 部署 `ingress-nginx-controller`

```shell
kubectl apply -f ingress-nginx-controller.yaml
```

验证 Nginx Ingress 控制器处于运行状态

```shell
$ kubectl get pod -n ingress-nginx 
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-td8fk       0/1     Completed   0          32s
ingress-nginx-admission-patch-gmdq6        0/1     Completed   2          32s
ingress-nginx-controller-d4bc88445-lwthr   1/1     Running     0          32s
```

# 三、Ingress 类型

## 3.1 样例

Ingress 需要指定 `apiVersion`、`kind`、 `metadata`和 `spec` 字段。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

## 3.2 路由匹配

![image-20220705145759989](img\image-20220705145759989.png)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-fanout-example
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /foo
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 4200
      - path: /bar
        pathType: Prefix
        backend:
          service:
            name: service2
            port:
              number: 8080
```

## 3.3 基于名称的虚拟托管

![image-20220705150128941](img\image-20220705150128941.png)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: name-virtual-host-ingress
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service1
            port:
              number: 80
  - host: bar.foo.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service2
            port:
              number: 80
```

如果你创建的 Ingress 资源没有在 `rules` 中定义的任何 `hosts`，则可以匹配指向 Ingress 控制器 IP 地址的任何网络流量，而无需基于名称的虚拟主机。

例如，以下 Ingress 会将请求 `first.bar.com` 的流量路由到 `service1`，将请求 `second.bar.com` 的流量路由到 `service2`，而所有其他流量都会被路由到 `service3`。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: name-virtual-host-ingress-no-third-host
spec:
  rules:
  - host: first.bar.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service1
            port:
              number: 80
  - host: second.bar.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service2
            port:
              number: 80
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: service3
            port:
              number: 80
```

## 3.4 TLS

你可以通过设定包含 TLS 私钥和证书的 Secret 来保护 Ingress。

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: testsecret-tls
  namespace: default
data:
  tls.crt: base64 encoded cert
  tls.key: base64 encoded key
type: kubernetes.io/tls
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
  tls:
  - hosts:
      - https-example.foo.com
    secretName: testsecret-tls
  rules:
  - host: https-example.foo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 80
```

# 四、Ingress 实战

## 4.1 创建工作负载

应用部署

```shell
kubectl apply -f 01-storageclass
kubectl apply -f 02-wordpress
kubectl apply -f 03-nginx
```

查看资源

```shell
$ kubectl get sc
NAME           PROVISIONER       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
stateful-nfs   nfs-provisioner   Retain          Immediate           false                  2m

$ kubectl get pod,svc -n wordpress-space
NAME                                   READY   STATUS    RESTARTS   AGE
pod/wordpress-6dbf944cb8-8bz7b         1/1     Running   0          49s
pod/wordpress-mysql-688bf7f698-d26bt   1/1     Running   0          47s

NAME                TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
service/mysql       ClusterIP   10.2.216.65   <none>        3306/TCP   49s
service/wordpress   ClusterIP   10.2.22.11    <none>        80/TCP     49s

$ kubectl get pod,svc -n nginx-space
NAME                              READY   STATUS    RESTARTS   AGE
pod/nginx-web1-64b675577d-8zlcr   1/1     Running   0          6m28s
pod/nginx-web1-64b675577d-frzkg   1/1     Running   0          6m28s
pod/nginx-web1-64b675577d-kzs64   1/1     Running   0          6m28s
pod/nginx-web2-5b9957f5c5-465vd   1/1     Running   0          6m28s
pod/nginx-web2-5b9957f5c5-jjdzf   1/1     Running   0          6m28s
pod/nginx-web2-5b9957f5c5-v27w6   1/1     Running   0          6m28s

NAME                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/nginx-web1-service   ClusterIP   10.2.207.150   <none>        80/TCP    6m28s
service/nginx-web2-service   ClusterIP   10.2.57.34     <none>        80/TCP    6m28s
```

## 4.2 创建 ingress

```yaml
cat > example-ingress.yaml << "EOF"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: wordpress-space
spec:
  ingressClassName: nginx
  rules:
    - host: wordpress.ingress.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: wordpress
                port:
                  number: 80
EOF
```

```bash
kubectl apply -f example-ingress.yaml
```

查看 ingress 绑定的 IP（初次使用，需要等待 2-3 分钟才会显示 ADDRESS）

```shell
$ kubectl get ingress -n wordpress-space
NAME              CLASS   HOSTS                   ADDRESS         PORTS   AGE
example-ingress   nginx   wordpress.ingress.com   10.11.141.102   80      17s
```

查看详细信息

```bash
$ kubectl describe -n wordpress-space ingress example-ingress
Name:             example-ingress
Labels:           <none>
Namespace:        wordpress-space
Address:          10.11.141.102
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host                   Path  Backends
  ----                   ----  --------
  wordpress.ingress.com  
                         /   wordpress:80 (10.244.1.133:80)
Annotations:             <none>
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    21s (x2 over 32s)  nginx-ingress-controller  Scheduled for sync
```

本地 hosts 解析添加

```
10.11.141.102 wordpress.ingress.com
```
```bash
http://wordpress.ingress.com/
```



## 4.3 Ingres 配置 TLS

生成自签域名证书

```shell
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout tls.key \
-out tls.cert \
-subj "/CN=wordpress.ingress.com/O=wordpress.ingress.com"
```

生成 Secret 

```shell
kubectl create secret tls ca-cert --key tls.key --cert tls.cert -n wordpress-space
```

查看 secret

```shell
$ kubectl get secrets -n wordpress-space
NAME                  TYPE                                  DATA   AGE
ca-cert               kubernetes.io/tls                     2      15s
default-token-svjjs   kubernetes.io/service-account-token   3      31m
mysql-pass            Opaque                                1      31m
```

```yaml
cat > tls-ingress.yaml << "EOF"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-example-ingress
  namespace: wordpress-space
spec:
  ingressClassName: nginx
  tls:
  - hosts:
      - wordpress.ingress.com
    secretName: ca-cert
  rules:
    - host: wordpress.ingress.com
      http:
        paths:
          - path: "/"
            pathType: Prefix
            backend:
              service:
                name: wordpress
                port:
                  number: 80
EOF
```

```bash
kubectl delete ingress --all -n wordpress-space
```

```shell
kubectl apply -f tls-ingress.yaml
```

查看 ingress 绑定的 IP

```shell
$ kubectl get -n wordpress-space ingress tls-example-ingress
NAME                  CLASS   HOSTS                   ADDRESS         PORTS     AGE
tls-example-ingress   nginx   wordpress.ingress.com   10.11.141.102   80, 443   2m
```

查看详细路由规则

```shell
$ kubectl describe -n wordpress-space ingress tls-example-ingress
Name:             tls-example-ingress
Labels:           <none>
Namespace:        wordpress-space
Address:          10.11.141.102
Ingress Class:    nginx
Default backend:  <default>
TLS:
  ca-cert terminates wordpress.ingress.com
Rules:
  Host                   Path  Backends
  ----                   ----  --------
  wordpress.ingress.com  
                         /   wordpress:80 (10.244.1.133:80)
Annotations:             nginx.ingress.kubernetes.io/rewrite-target: /$1
                         nginx.ingress.kubernetes.io/ssl-redirect: false
Events:
  Type    Reason  Age                  From                      Message
  ----    ------  ----                 ----                      -------
  Normal  Sync    84s (x2 over 2m16s)  nginx-ingress-controller  Scheduled for sync
```

```bash
https://wordpress.ingress.com
```

## 4.4 多虚拟主机 ingress

```yaml
cat > virtual-host-ingress.yaml << "EOF"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: virtual-host-ingress
  namespace: nginx-space
spec:
  ingressClassName: nginx
  rules:
  - host: game.ingress.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: nginx-web1-service
            port:
              number: 80
  - host: web.ingress.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: nginx-web2-service
            port:
              number: 80
EOF
```

```bash
kubectl apply -f virtual-host-ingress.yaml
```

查看 ingress 绑定的 IP

```shell
$ kubectl get -n nginx-space ingress virtual-host-ingress
NAME                   CLASS   HOSTS                              ADDRESS         PORTS   AGE
virtual-host-ingress   nginx   web.ingress.com,game.ingress.com   10.11.141.102   80      105s
```

查看详细路由规则

```shell
$ kubectl describe -n nginx-space ingress virtual-host-ingress
Name:             virtual-host-ingress
Labels:           <none>
Namespace:        nginx-space
Address:          10.11.141.102
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host              Path  Backends
  ----              ----  --------
  game.ingress.com   
                    /   nginx-web1-service:80 (10.244.1.119:80,10.244.1.121:80,10.244.1.122:80)
  web.ingress.com  
                    /   nginx-web2-service:80 (10.244.1.120:80,10.244.1.123:80,10.244.1.124:80)
Annotations:        <none>
Events:
  Type    Reason  Age                 From                      Message
  ----    ------  ----                ----                      -------
  Normal  Sync    98s (x2 over 2m9s)  nginx-ingress-controller  Scheduled for sync
```

本地 hosts 解析添加

```shell
10.11.141.102 web.ingress.com
10.11.141.102 game.ingress.com
```

```bash
http://web.ingress.com
http://game.ingress.com
```

## 4.5 路由匹配 ingress

```yaml
cat > fanout-ingress.yaml << "EOF"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fanout-ingress
  namespace: nginx-space
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: nginx.ingress.com
    http:
      paths:
      - path: /game(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: nginx-web1-service
            port:
              number: 80
      - path: /web(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: nginx-web2-service
            port:
              number: 80
EOF
```

```bash
kubectl delete ingress --all -n nginx-space
```

```bash
kubectl apply -f fanout-ingress.yaml
```

查看 ingress 绑定的 IP

```shell
$ kubectl get ingress -n nginx-space
NAME             CLASS   HOSTS               ADDRESS         PORTS   AGE
fanout-ingress   nginx   nginx.ingress.com   10.11.141.102   80      12s
```

查看详细路由规则

```shell
$ kubectl describe -n nginx-space ingress fanout-ingress
Name:             fanout-ingress
Labels:           <none>
Namespace:        nginx-space
Address:          10.11.141.102
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host               Path  Backends
  ----               ----  --------
  nginx.ingress.com  
                     /game(/|$)(.*)   nginx-web1-service:80 (10.244.1.152:80,10.244.1.153:80,10.244.1.154:80)
                     /web(/|$)(.*)    nginx-web2-service:80 (10.244.1.151:80,10.244.1.155:80,10.244.1.156:80)
Annotations:         nginx.ingress.kubernetes.io/rewrite-target: /$2
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    18s (x2 over 28s)  nginx-ingress-controller  Scheduled for sync
```

```bash
10.11.141.102 nginx.ingress.com
```

```bash
http://nginx.ingress.com/web/
http://nginx.ingress.com/game/
```

## 4.6 负载均衡
