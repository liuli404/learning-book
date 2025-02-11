# 一、软件信息

| 名称          | 版本   | 下载链接                                                     |
| ------------- | ------ | ------------------------------------------------------------ |
| elasticsearch | 7.15.2 | https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.15.2-linux-x86_64.tar.gz |
| kibana        | 7.15.2 | https://artifacts.elastic.co/downloads/kibana/kibana-7.15.2-linux-x86_64.tar.gz |

![c](img\image-20220712110429052.png)

# 二、ES 安装

## 2.1 系统资源配置

- 最大文件数

```bash
cat >> /etc/security/limits.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
es soft memlock unlimited
es hard memlock unlimited
EOF
```

- 内核参数

```bash
cat >> /etc/sysctl.conf << EOF
vm.max_map_count=655360
EOF
```

```bash
sysctl -p
```

## 2.2 修改配置

```bash
tar -zxvf elasticsearch-7.15.2-linux-x86_64.tar.gz -C /opt/
cd /opt/elasticsearch-7.15.2
```

```bash
cat > config/elasticsearch.yml << EOF
cluster.name: my-application
node.name: node-1
path.data: /opt/elasticsearch-7.15.2/es_data
path.logs: /opt/elasticsearch-7.15.2/es_logs
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["127.0.0.1"]
cluster.initial_master_nodes: ["node-1"]
EOF
```

创建数据、日志存储目录

```bash
mkdir /opt/elasticsearch-7.15.2/es_data
mkdir /opt/elasticsearch-7.15.2/es_logs
```

## 2.3 使用普通用户启动

```bash
useradd es
chown -R es /opt/elasticsearch-7.15.2
su - es
cd /opt/elasticsearch-7.15.2/
```

后台启动

```bash
nohup bin/elasticsearch >> es_logs/es.log 2>&1 &
```

访问 es

```bash
$ curl http://10.11.113.167:9200/
{
  "name" : "node-1",
  "cluster_name" : "my-application",
  "cluster_uuid" : "4mJpcpKTQkub85DNhWKfEQ",
  "version" : {
    "number" : "7.15.2",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "93d5a7f6192e8a1a12e154a2b81bf6fa7309da0c",
    "build_date" : "2021-11-04T14:04:42.515624022Z",
    "build_snapshot" : false,
    "lucene_version" : "8.9.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

# 三、Kibana 安装

```bash
tar -zxvf kibana-7.15.2-linux-x86_64.tar.gz -C /opt/
cd /opt/kibana-7.15.2-linux-x86_64/
```

## 3.1 修改配置

```bash
cat > config/kibana.yml << EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://10.11.113.167:9200"]
i18n.locale: "zh-CN"
EOF
```

## 3.2 启动服务

```bash
nohup bin/kibana --allow-root >> kibana.log 2>&1 &
```

访问 UI `http://10.11.113.167:5601`

# 四、pod 日志收集

## 4.1 方案选型

![1271786-20190427152903839-96635418](img\1271786-20190427152903839-96635418.png)

优缺点分析

![1271786-20190427153030350-1849795614](img\1271786-20190427153030350-1849795614.png)

## 4.2 收集 Nginx Pod 日志

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx-log-test
  labels:
    name: nginx-log-test
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-nginx-config
  namespace: nginx-log-test
data:
  filebeat.yml: |-
    filebeat.inputs:
      - type: log
        paths:
          - /var/log/nginx/access.log
        fields:
          app: nginx-server
          type: nginx-access
        fields_under_root: true

      - type: log
        paths:
          - /var/log/nginx/error.log
        fields:
          app: nginx-server
          type: nginx-error
        fields_under_root: true
    output.elasticsearch:
      hosts: ['10.11.113.167:9200']
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-server
  namespace: nginx-log-test
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: nginx-server
  template:
    metadata:
      labels:
        app: nginx-server
    spec:
      restartPolicy: Always
      containers:
      - name: nginx-container
        image: harbor.test.digitalchina.com/test2/anhx/nginx:v1
        imagePullPolicy: IfNotPresent
        ports:
        - name: nginx-port
          containerPort: 80
          protocol: TCP
        volumeMounts:
        - name: nginx-logs
          mountPath: /var/log/nginx/

      - name: filebeat
        image: harbor.test.digitalchina.com/google_imgs/filebeat:7.15.2
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 100Mi
        securityContext:
          runAsUser: 0
        volumeMounts:
        - name: filebeat-config
          mountPath: /etc/filebeat.yml
          subPath: filebeat.yml
        - name: nginx-logs
          mountPath: /var/log/nginx/

      volumes:
      - name: nginx-logs
        emptyDir: {}
      - name: filebeat-config
        configMap:
          name: filebeat-nginx-config

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: nginx-log-test
  labels:
    name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx-server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
```

```bash
kubectl apply -f nginx-log-test.yaml 
```

查看 es 索引， filebeat-7.15.2 为创建的默认日志采集索引

```bash
$ curl http://10.11.113.167:9200/_cat/indices?v
health status index            uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .geoip_databases B-QtSRbZSTCcc3a-LEAlCw   1   0         40            0     37.7mb         37.7mb
yellow open   filebeat-7.15.2  4fXBlmVHRxK21i85DCeZ0Q   1   1          1            0     13.8kb         13.8kb
```

## 4.3 收集主机日志

需要部署 DaemonSet 的 filebeat

```bash
apiVersion: v1
kind: Namespace
metadata:
  name: efk
  labels:
    name: efk

---

apiVersion: v1
kind: ConfigMap
metadata:
  name: k8s-logs-filebeat-config
  namespace: efk
 
data:
  filebeat.yml: |-
    filebeat.inputs:
      - type: log
        paths:
          - /messages
        fields:
          app: k8s
          type: module
        fields_under_root: true

    output.elasticsearch:
      hosts: ['10.11.113.167:9200']

---

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: k8s-logs
  namespace: efk
spec:
  selector:
    matchLabels:
      project: k8s
      app: filebeat
  template:
    metadata:
      labels:
        project: k8s
        app: filebeat
    spec:
      containers:
      - name: filebeat
        image: harbor.test.digitalchina.com/google_imgs/filebeat@:7.15.2
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 500m
            memory: 500Mi
        securityContext:
          runAsUser: 0
        volumeMounts:
        - name: filebeat-config
          mountPath: /etc/filebeat.yml
          subPath: filebeat.yml
        - name: k8s-logs
          mountPath: /messages
      volumes:
      - name: k8s-logs
        hostPath:
          path: /var/log/messages
          type: File
      - name: filebeat-config
        configMap:
          name: k8s-logs-filebeat-config
```

# 五、kibana 接入索引

![image-20220712155921460](img\image-20220712155921460.png)

![image-20220712160027176](img\image-20220712160027176.png)

![image-20220712160131420](img\image-20220712160131420.png)

![image-20220712160318934](img\image-20220712160318934.png)