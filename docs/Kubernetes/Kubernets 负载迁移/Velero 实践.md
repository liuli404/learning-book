# 一、迁移示意图

![img](img\zh-cn_image_0000001172392670.png)

| 对象          | 源端          | 目标端        | CCE         |
| ------------- | ------------- | ------------- | ----------- |
| minio·        | 10.11.113.166 | 10.11.141.101 | 10.11.130.9 |
| k8s 集群      | 10.11.113.161 | 10.11.141.101 | 10.11.130.6 |
| k8s 版本      | v1.23.4       | v1.23.5       | v1.19.5     |
| 容器运行时    | containerd    | docker        | docker      |
| 安装方式      | 二进制        | kubeadm       | cce         |
| velero 客户端 | 10.11.113.161 | 10.11.141.101 | 10.11.130.6 |

集群架构图

![image-20220629164010293](img\image-20220629164010293.png)

# 二、前期准备



- k8s 集群安装完毕
  - 二进制
  - kubeadm
  - CCE
- k8s 对接 harbor 镜像仓库
  - containerd
  - docker



# 三、minio 安装

## 3.1 docker 安装

```shell
# 10.11.113.166 源端
docker run -d \
 -p 9000:9000 \
 -p 9001:9001 \
 -v /opt/minio:/data \
 --name minio-source \
 --restart always \
 -v /opt/minio:/data \
 minio/minio \
 server /data --console-address ":9001"

# 10.11.141.101 目标端
docker run -d \
 -p 9000:9000 \
 -p 9001:9001 \
 -v /opt/minio:/data \
 --name minio-dest \
 --restart always \
 minio/minio \
 server /data --console-address ":9001"
 
# 10.11.130.9 CCE端
docker run -d \
 -p 9000:9000 \
 -p 9001:9001 \
 -v /opt/minio:/data \
 --name minio-cce \
 --restart always \
 minio/minio \
 server /data --console-address ":9001"
```

## 3.2 创建 velero 桶

登陆地址：ip:9001

默认密码：minioadmin/minioadmin

![image-20220628111920224](img\image-20220628111920224.png)

![image-20220628111956681](img\image-20220628111956681.png)

![image-20220628112008297](img\image-20220628112008297.png)

## 3.3 创建 minio 凭证

![image-20220628112043858](img\image-20220628112043858.png)

![image-20220628112118904](img\image-20220628112118904.png)

**目标端、CCE 端同理操作，获取 ak\sk**

# 四、rclone 安装

## 4.1 脚本安装

**安装在同时可以访问 源端、目标端、CCE 端的 minio 跳板机服务器上**

```shell
curl https://rclone.org/install.sh | sudo bash
```

## 4.2 rclone 配置

```shell
vim /root/.config/rclone/rclone.conf
```

修改 **access_key_id、secret_access_key、endpoint** 值

```shell
[minio-source]
 type = s3
 provider = Minio
 env_auth = false
 access_key_id = jEpCHHTfIanjtHOS
 secret_access_key = uvJHIYbi8TNDJdQKpN7TehGyHcnCbSMi
 region = cn-east-1
 endpoint = http://10.11.113.166:9000
 location_constraint =
 server_side_encryption =

 [minio-dest]
 type = s3
 provider = Minio
 env_auth = false
 access_key_id = PRFMYJT1KYIPKHXQ7XNJ
 secret_access_key = sHp6rm75rGG1Yi5tgUg+SAHVZYTX1aBPjCPHEIrQ
 region = cn-east-1
 endpoint = http://10.11.141.101:9000
 location_constraint =
 server_side_encryption =

 [minio-cce]
 type = s3
 provider = Minio
 env_auth = false
 access_key_id = LLPo0XSXrfiP1Cul
 secret_access_key = ymEO90JhuceTejlOsUNR6DyP6TwOf5od
 region = cn-east-1
 endpoint = http://10.11.130.9:9000
 location_constraint =
 server_side_encryption =
```

# 五、Velero 安装

## 5.1 安装客户端

客户端用于将服务端安装在 k8s 集群中。所以需要安装在可以控制 k8s 集群的主机上，类似 kubectl 功能

```shell
wget https://github.com/vmware-tanzu/velero/releases/download/v1.9.0/velero-v1.9.0-linux-amd64.tar.gz
tar -zxvf velero-v1.9.0-linux-amd64.tar.gz
mv velero-v1.9.0-linux-amd64/velero /usr/local/bin/
```

查看版本

```shell
[root@master01 ~]# velero version
Client:
	Version: v1.9.0
	Git commit: 6021f148c4d7721285e815a3e1af761262bff029
<error getting server version: no matches for kind "ServerStatusRequest" in version "velero.io/v1">
```

不同版本插件

![image-20220627174002707](img\image-20220627174002707.png)

## 5.2 安装服务端

**每个 k8s 集群需要安装服务端（注意修改成自己的 minio 密钥、与 minio s3Url）**

创建 minio 对象存储访问密钥文件 credentials-velero

```shell
vim ~/.credentials-velero

[default]
aws_access_key_id=4MBOSTTNB6N85ZXJURUY
aws_secret_access_key=bgVo6O27XaitqZOqEdAe+p6bj1355VM2TilXjbse
```

部署 Velero 服务端。注意其中 `--bucket` 参数需要修改为已创建的对象存储桶名称，本例中为 **velero**。

```shell
velero install \
   --provider aws \
   --bucket velero \
   --image velero/velero:v1.9.0 \
   --plugins velero/velero-plugin-for-aws:v1.5.0 \
   --secret-file ~/.credentials-velero \
   --use-volume-snapshots=false \
   --use-restic \
   --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://10.11.141.101:9000 \
   --kubeconfig /root/kubeconfig.json
```

| 安装参数                 | 参数说明                                                     |
| ------------------------ | ------------------------------------------------------------ |
| --provider               | 声明使用“aws”提供的插件类型。                                |
| --plugins                | 使用AWS S3兼容的API组件，本文使用的OBS和MinIO对象存储均支持该S3协议。 |
| --bucket                 | 用于存放备份文件的对象存储桶名称，需提前创建。               |
| --secret-file            | 访问对象存储的密钥文件，即创建的“credentials-velero”文件。   |
| --use-restic             | 使用Restic工具支持PV数据备份，建议开启，否则将无法备份存储卷资源。 |
| --use-volume-snapshots   | 是否创建 VolumeSnapshotLocation 对象进行PV快照，需要提供快照程序支持。该值设为false。 |
| --backup-location-config | 对象存储桶相关配置，包括region、s3ForcePathStyle、s3Url等。  |
| region                   | 对象存储桶所在区域。OBS：请根据实际区域填写，如“cn-north-4”。MinIO：参数值为minio。 |
| s3ForcePathStyle         | 参数值为“true”，表示使用S3文件路径格式。                     |
| s3Url                    | 对象存储桶的API访问地址。                                    |

查看服务端是否安装成功，所有 pod 需要为 Running

```shell
kubectl get pod -n velero
```

查看后端存储桶连接状态

```bash
velero backup-location get 
```

状态为 Available

```c
NAME      PROVIDER   BUCKET/PREFIX   PHASE       LAST VALIDATED                  ACCESS MODE   DEFAULT
default   aws        velero          Available   2022-07-25 11:55:48 +0800 CST   ReadWrite     true
```

**注**：CCE 敏捷版中 kubelet pod 的位置是 `/mnt/paas/kubernetes/kubelet/pods`

```shell
kubectl edit daemonsets restic -n velero
```

![image-20220628110858877](img\image-20220628110858877.png)

查看所有 restic 状态为 Running

```shell
[root@master01 ~]# kubectl get pod -n velero 
restic-kcjj4              1/1     Running   0          3m15s
restic-pbf4h              1/1     Running   0          3m15s
restic-wq5rt              1/1     Running   0          3m18s
restic-xxzc5              1/1     Running   0          3m12s
velero-77f7fbb456-bt5cp   1/1     Running   0          6m42s
```

# 六、迁移实战

> - 原集群应用备份
>
>   当用户执行备份时，首先通过 Velero 工具在原集群中创建 Backup 对象，并查询集群相关的数据和资源进行备份，并将数据打包上传至 S3 协议兼容的对象存储中（minio），各类集群资源将以 JSON 格式文件进行存储。
>
> - 目标集群应用恢复
>
>   在目标集群中进行还原时，Velero 将指定之前存储备份数据的临时对象桶，并把备份的数据下载至新集群，再根据 JSON 文件对资源进行重新部署。



## 6.1 无状态应用

源端集群创建 Nginx 服务

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nginx-space
  labels:
    name: nginx-space
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-server
  namespace: nginx-space
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
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: nginx-space
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

```shell
kubectl apply -f nginx.yaml
```

```shell
[root@master01 ~]# kubectl get pod -n nginx-space
NAME                            READY   STATUS    RESTARTS   AGE
nginx-server-58774f6d44-49rxj   1/1     Running   0          73s
nginx-server-58774f6d44-75c92   1/1     Running   0          73s
nginx-server-58774f6d44-cpbhb   1/1     Running   0          73s
```

### 6.1.1 本机备份恢复

对 nginx-space 命名空间备份

```shell
# 执行备份
velero backup create nginx-space-backup --include-namespaces nginx-space 

# 查看备份，Status 为 Completed
velero backup get
```

参数解释：

```yml
--include-namespaces: 用于指定 namespace 下的资源进行备份。
--default-volumes-to-restic: 表示使用 Restic 工具对 Pod 挂载的所有存储卷进行备份，不支持 HostPath 类型的存储卷。如不指定该参数，将默认对 annotation 指定的存储卷进行备份。此参数仅在安装Velero时指定“--use-restic”后可用。
```

删除 kubernetes-dashboard 命名空间

```shell
kubectl delete namespaces nginx-space
```

恢复 kubernetes-dashboard 

```shell
velero restore create --from-backup nginx-space-backup
```

### 6.1.2 迁移至自建集群

源端集群备份

```shell
velero backup create nginx-space-backup-$(date +%Y%m%d%H%M) --include-namespaces nginx-space
```

查看备份任务是否完成

```shell
velero backup get
```

rclone 迁移备份文件

```shell
rclone sync minio-source:velero minio-dest:velero -P
```

目标端查看是否有备份文件

```shell
velero backup get
```

目标端恢复

```shell
velero restore create --from-backup nginx-space-backup-202206301429
```

### 6.1.3 迁移至 CCE 集群

CCE 集群需要在 UI 控制端提前创建 nginx-space 项目，写入数据库，命令行创建的资源不受 CCE UI 管理。

![image-20220630114840326](img\image-20220630114840326.png)

创建项目（命名空间），并授权

![image-20220630115034097](img\image-20220630115034097.png)

源端集群备份

```shell
velero backup create nginx-space-backup-$(date +%Y%m%d%H%M ) --include-namespaces nginx-space
```

查看备份任务是否完成

```shell
velero backup get 
```

rclone 迁移备份文件

```shell
rclone sync minio-source:velero minio-cce:velero -P
```

CCE 端查看是否有备份文件

```shell
velero backup get --kubeconfig /root/kubeconfig.json
```

CCE 端恢复

```shell
velero restore create --from-backup nginx-space-backup-202206301429 --kubeconfig /root/kubeconfig.json
```

## 6.2 有状态应用

源端集群创建 Wordpress 服务

```yaml
# rbac
apiVersion: v1                              
kind: ServiceAccount                                                     
metadata:                                                                
  name: nfs-provisioner                                                  
  namespace: nfs                                             
---                                                                      
apiVersion: rbac.authorization.k8s.io/v1               
kind: ClusterRole                                                        
metadata:                                                                
  name: nfs-provisioner-runner                                           
  namespace: nfs                                             
rules:                                                                   
   -  apiGroups: [""]                                                    
      resources: ["persistentvolumes"]                                   
      verbs: ["get", "list", "watch", "create", "delete"]                
   -  apiGroups: [""]                                                    
      resources: ["persistentvolumeclaims"]                              
      verbs: ["get", "list", "watch", "update"]                          
   -  apiGroups: ["storage.k8s.io"]                                      
      resources: ["storageclasses"]                                      
      verbs: ["get", "list", "watch"]                                    
   -  apiGroups: [""]                                                    
      resources: ["events"]                                              
      verbs: ["watch", "create", "update", "patch"]                      
   -  apiGroups: [""]                                                    
      resources: ["services", "endpoints"]                               
      verbs: ["get","create","list", "watch","update"]                   
   -  apiGroups: ["extensions"]                                          
      resources: ["podsecuritypolicies"]                                 
      resourceNames: ["nfs-provisioner"]                                 
      verbs: ["use"]                                                     
---                                     
kind: ClusterRoleBinding                
apiVersion: rbac.authorization.k8s.io/v1                                 
metadata:                                                                
  name: run-nfs-provisioner                                              
subjects:                                                                
  - kind: ServiceAccount                                                 
    name: nfs-provisioner                                                
    namespace: nfs                                           
roleRef:                                                                 
  kind: ClusterRole                                                      
  name: nfs-provisioner-runner                                           
  apiGroup: rbac.authorization.k8s.io
---
# nfs-client-provisioner
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  namespace: nfs
spec:
  replicas: 1 
  selector:
    matchLabels:
      app: nfs-client-provisioner                             
  strategy:
    type: Recreate                      
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccount: nfs-provisioner            
      containers:
        - name: nfs-client-provisioner
          image: harbor.test.digitalchina.com/test2/nfs-client-provisioner:latest     
          volumeMounts:
            - name: nfs-client-root
              mountPath:  /persistentvolumes             
          env:
            - name: PROVISIONER_NAME           
              value: nfs-test 
            - name: NFS_SERVER                      
              value: 10.11.113.166
            - name: NFS_PATH                       
              value: /opt/wwwroot/datanfs
      volumes:                                                
        - name: nfs-client-root
          nfs:
            server: 10.11.113.166
            path: /opt/wwwroot/datanfs
---
# storageclass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: stateful-nfs
  namespace: nfs
provisioner: nfs-test                  #这个要和nfs-client-provisioner的env环境变量中的PROVISIONER_NAME的value值对应。
reclaimPolicy: Retain
---
# namespace
apiVersion: v1
kind: Namespace
metadata:
  name: wordpress-space
  labels:
    name: wordpress-space
---
# config
apiVersion: v1
kind: ConfigMap
metadata:
    name: mysql-config
    namespace: wordpress-space
data:
    db-name: wordpress
    #可以设置多组数据，数值类型一定要使用""引起来，否则会报错
    userage: "18"
    dbuser: root
---
# secret
apiVersion: v1
kind: Secret
metadata:
    name: mysql-pass
    namespace: wordpress-space
type: Opaque
#Opaque 隐藏，该类型使用kubectl的任何查看命令都看不到下面data部分定义的密码数据
data:
    #敏感数据通过base64编码处理echo -n $str | base64
    #password: root 
    password: cm9vdA==
    #可以设置多组数据
---
# pvc
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: mysql-pv-claim
    namespace: wordpress-space
spec:
    storageClassName: stateful-nfs
    accessModes: ["ReadWriteOnce"]
    resources:
        requests:
            storage: 2Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: wordpress-pv-claim
    namespace: wordpress-space
spec:
    storageClassName: stateful-nfs
    accessModes: ["ReadWriteOnce","ReadWriteMany"]
    resources:
        requests:
            storage: 1Gi
---
# mysql
#api版本
apiVersion: apps/v1
kind: Deployment
metadata:
    #deployment的名称
    name: wordpress-mysql
    namespace: wordpress-space
    #mysql deployment本身的label
    labels:
        app: wordpress
        tier: mysql
spec:
    selector:
        #deployment选择有下面两个标签的pod配置信息进行部署
        matchLabels:
            app: wordpress
            tier: mysql-pod
   # nodeName: master01
    strategy:
        #配置deployment的升级方式
        type: Recreate
    #pod的配置信息    
    template:
        metadata:
            #pod的label，与上面selector配置项的label对应
            labels:
                app: wordpress
                tier: mysql-pod
        spec:
            #pod内container相关配置信息
            containers:
              #container使用的镜像信息
              - image: mysql:5.7
                #container名称
                name: mysql
                #container使用的一些参数配置
                env:
                  #MYSQL_ROOT_PASSWORD参数配置信息，这些参数在镜像说明文档里会有介绍
                  - name: MYSQL_ROOT_PASSWORD
                    valueFrom:
                    #从名称为mysql-pass的secret对象读取password这个key对应的value信息，将其作为MYSQL_ROOT_PASSWORD的值传给container.
                        secretKeyRef:
                        #找到mysql-pass
                            name: mysql-pass
                            key: password
                  - name: MYSQL_DATABASE
                    valueFrom:
                    #从名称为mysql-config的configmap对象读取key为db-name的值，将其作为MYSQL_DATABASE的值传给container
                        configMapKeyRef:
                        #找到mysql-config
                            name: mysql-config
                            key: db-name
                #这里对ports进行命名，具体映射container端口到clusterip在service配置文件的selector已经选中这个pod进行映射了
                ports:
                  - containerPort: 3306
                    name: mysql
                #数据持久化信息
                volumeMounts:
                 #使用名称为mysql-persistent-storage的volumes配置进行数据持久化
                  - name: mysql-persistent-storage
                    #container中需要进行数据持久化的路径
                    mountPath: /var/lib/mysql
            #持久化存储配置
            volumes:
              #配置名，与上面volumeMounts中的name对应
              - name: mysql-persistent-storage
                #使用哪个pvc进行数据持久化，之前已经进行了pv和pvc的配置了，这里直接使用
                persistentVolumeClaim:
                    claimName: mysql-pv-claim
---
# wordpress
apiVersion: apps/v1
kind: Deployment
metadata:
    name: wordpress
    namespace: wordpress-space
    labels:
        app: wordpress
        tier: frontend
spec:
    selector:
        matchLabels:
            app: wordpress
            tier: frontend-pod
    strategy:
        type: Recreate 
        #升级方式 还有rollingUpdate
    template:
        metadata:
            labels:
                app: wordpress
                tier: frontend-pod
        spec:
            containers:
              - image: harbor.test.digitalchina.com/lamp/wordpress:latest
                name: wordpress
                env:
                  - name: WORDPRESS_DB_HOST
                    #这里是将名称为mysql的service的ip传给container的WORDPRESS_DB_HOST变量。env没有配置valuefrom就是从service获取对应的配置
                    value: mysql
                  - name: WORDPRESS_DB_PASSWORD
                    valueFrom:
                        secretKeyRef:
                            #mysql 密码,通过指定secret资源对象的name和对象的key来获取
                            name: mysql-pass
                            key: password
                  - name: WORDPRESS_DB_USER
                    valueFrom:
                        configMapKeyRef:
                            #mysql 密码,通过指定secret资源对象的name和对象的key来获取
                            name: mysql-config
                            key: dbuser
                ports:
                  - containerPort: 80
                    name: wordpress
                volumeMounts:
                  - name: wordpress-persistent-storage
                    mountPath: /var/www/html
            volumes:
              - name: wordpress-persistent-storage
                persistentVolumeClaim:
                    claimName: wordpress-pv-claim
```

### 6.2.1 迁移至自建集群

**原集群应用备份**

1. 如果需要对 Pod 中指定的存储卷数据进行备份，需对 Pod 添加 annotation ，标记模板如下：

   ```shell
   kubectl -n <namespace> annotate <pod/pod_name> backup.velero.io/backup-volumes=<volume_name_1>,<volume_name_2>,...
   ```

   ```yaml
   <namespace>: Pod 所在的 namespace
   <pod_name>: Pod 名称
   <volume_name>: Pod 挂载的持久卷名称。可通过 describe 语句查询 Pod 信息，Volume 字段下即为该 Pod 挂载的所有持久卷名称
   ```

   对 Wordpress 和 MySQL 的 Pod 添加 annotation

   ```shell
   kubectl annotate pod/wordpress-6dbf944cb8-lbmzh backup.velero.io/backup-volumes=wordpress-pv-claim -n wordpress-space  --overwrite
   
   kubectl annotate pod/wordpress-mysql-688bf7f698-74xsm backup.velero.io/backup-volumes=mysql-pv-claim -n wordpress-space  --overwrite
   ```

2. 对应用进行备份。备份时可以根据参数指定资源，若不添加任何参数，则默认对整个集群资源进行备份

   ```yaml
   --default-volumes-to-restic: 表示使用 Restic 工具对 Pod 挂载的所有存储卷进行备份，不支持 HostPath 类型的存储卷。如不指定该参数，将默认对 annotation 指定的存储卷进行备份。此参数仅在安装Velero时指定“--use-restic”后可用。
   --include-namespaces: 用于指定 namespace 下的资源进行备份。
   ```

   本文指定 wordpress-space 命名空间下的资源进行备份，wordpress-backup 为备份名称，进行应用恢复时也需指定相同的备份名称

   ```shell
   velero backup create wordpress-space-backup-$(date +%Y%m%d%H%M) --include-namespaces wordpress-space --default-volumes-to-restic
   ```

3. 查看备份情况。

   ```bash
   velero backup get
   ```

**迁移minio数据**

```shell
rclone sync minio-source:velero minio-dest:velero -P
```

**目标集群应用恢复**

1. 查看备份文件

   ```shell
   velero backup get --kubeconfig
   ```

2. 这里创建一个原集群中相同名称 StorageClass 来完成适配。

   ```shell
   # 创建 nfs 存储目录
   mkdir -p /opt/nfs
   
   # 添加权限
   vi /etc/exports
   /opt/nfs *(rw,sync,no_wdelay,no_root_squash,insecure)
   
   # 目录授权
   chown -R nfsnobody:nfsnobody /opt/nfs
   
   # 重启 nfs 服务
   systemctl restart nfs
   
   # 查看 nfs 服务
   showmount -e
   ```

   创建 StorageClass 

   

   ```yaml
   # rbac-rolebind.yaml
   apiVersion: v1
   kind: Namespace                 
   metadata:                                                                
     name: nfs                                                  
   ---
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: nfs-provisioner
     namespace: nfs
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: nfs-provisioner-runner
     namespace: nfs
   rules:
      -  apiGroups: [""]
         resources: ["persistentvolumes"]
         verbs: ["get", "list", "watch", "create", "delete"]
      -  apiGroups: [""]
         resources: ["persistentvolumeclaims"]
         verbs: ["get", "list", "watch", "update"]
      -  apiGroups: ["storage.k8s.io"]
         resources: ["storageclasses"]
         verbs: ["get", "list", "watch"]
      -  apiGroups: [""]
         resources: ["events"]
         verbs: ["watch", "create", "update", "patch"]
      -  apiGroups: [""]
         resources: ["services", "endpoints"]
         verbs: ["get","create","list", "watch","update"]
      -  apiGroups: ["extensions"]
         resources: ["podsecuritypolicies"]
         resourceNames: ["nfs-provisioner"]
         verbs: ["use"]
   ---                                     
   kind: ClusterRoleBinding
   apiVersion: rbac.authorization.k8s.io/v1
   metadata:
     name: run-nfs-provisioner
   subjects:
     - kind: ServiceAccount
       name: nfs-provisioner
       namespace: nfs
   roleRef:
     kind: ClusterRole
     name: nfs-provisioner-runner
     apiGroup: rbac.authorization.k8s.io
   
   # nfs-deployment.yaml  
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nfs-client-provisioner
     namespace: nfs
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nfs-client-provisioner
     strategy:
       type: Recreate
     template:
       metadata:
         labels:
           app: nfs-client-provisioner
       spec:
         serviceAccount: nfs-provisioner
         containers:
           - name: nfs-client-provisioner
             image: quay.io/external_storage/nfs-client-provisioner:latest
             volumeMounts:
               - name: nfs-client-root
                 mountPath: /persistentvolumes
             env:
               - name: PROVISIONER_NAME
                 value: nfs-test
               - name: NFS_SERVER
                 value: 192.168.0.55
               - name: NFS_PATH
                 value: /opt/nfs
         volumes:
           - name: nfs-client-root
             nfs:
               server: 192.168.0.55
               path: /opt/nfs
   
   # storageclass.yaml
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: stateful-nfs
     namespace: nfs
   provisioner: nfs-test
   reclaimPolicy: Retain
   ```

   

3. 在集群中创建如下所示的 ConfigMap，将原集群使用的 StorageClass 映射到 CCE 集群默认的 StorageClass

   ```shell
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: change-storageclass-plugin-config
     namespace: velero
     labels:
       app.kubernetes.io/name: velero
       velero.io/plugin-config: "true"
       velero.io/change-storage-class: RestoreItemAction
   data:
     stateful-nfs: stateful-nfs
     # 原集群StorageClass name01: 目标集群StorageClass name01
   ```

   ```shell
   kubectl create -f change-storage-class.yaml
   ```

4. 指定名称为 wordpress-backup 的备份，将 Wordpress 应用恢复至自建集群

   ```shell
   velero restore create --from-backup wordpress-space-backup-202206301618
   ```

```bash
apiVersion: v1
kind: Secret
metadata:
  labels:
    backup.everest.io/secret: 'true'
  name: secret-secure-opaque
  namespace: velero
type: cfe/secure-opaque
data:
  cloud: SFVBV0VJX0NMT1VEX0FDQ0VTU19LRVlfSUQ9UEoxREQ0OUpHWVFERkpBUktITlAKSFVBV0VJX0NMT1VEX1NFQ1JFVF9BQ0NFU1NfS0VZPXBud1I5enh4VFlnODB0Uk4wMkFzWkc5ZG1MczUyclFWbDFYUmNsQkMK
```



### 6.2.2 增量数据迁移

# 七、velero 卸载

```shell
[root@cce-test-68401 ~]# velero uninstall --kubeconfig kubeconfig.json 
You are about to uninstall Velero.
Are you sure you want to continue (Y/N)? y
Waiting for velero namespace "velero" to be deleted
.............................................................................................................................................
Velero namespace "velero" deleted
Velero uninstalled ⛵
```



# 报错

![image-20220707115915393](img\image-20220707115325239.png)

```shell
time="2022-07-07T03:58:17Z" level=info msg="Validating BackupStorageLocation" backup-storage-location=velero/default controller=backup-storage-location logSource="pkg/controller/backup_storage_location_controller.go:130"

time="2022-07-07T03:58:17Z" level=info msg="BackupStorageLocations is valid, marking as available" backup-storage-location=velero/default controller=backup-storage-location logSource="pkg/controller/backup_storage_location_controller.go:115"

time="2022-07-07T03:58:17Z" level=error msg="Current BackupStorageLocations available/unavailable/unknown: 0/0/1)" controller=backup-storage-location logSource="pkg/controller/backup_storage_location_controller.go:172"

time="2022-07-07T03:58:18Z" level=info msg="Found 1 backups in the backup location that do not exist in the cluster and need to be synced" backupLocation=default controller=backup-sync logSource="pkg/controller/backup_sync_controller.go:211"

time="2022-07-07T03:58:18Z" level=info msg="Attempting to sync backup into cluster" backup=nginx-space-backup-202207071126 backupLocation=default controller=backup-sync logSource="pkg/controller/backup_sync_controller.go:219"

time="2022-07-07T03:58:18Z" level=error msg="Error syncing backup into cluster" backup=nginx-space-backup-202207071126 backupLocation=default controller=backup-sync error="Backup.velero.io \"nginx-space-backup-202207071126\" is invalid: spec.runMode: Required value" error.file="/go/src/github.com/vmware-tanzu/velero/pkg/controller/backup_sync_controller.go:246" error.function="github.com/vmware-tanzu/velero/pkg/controller.(*backupSyncController).run" logSource="pkg/controller/backup_sync_controller.go:246"
```

查看 velero 服务端与 minio 连接是否正常
