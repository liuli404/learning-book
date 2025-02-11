# K8S环境 Wordpress+MYSQL LAMP架构部署流程


使⽤kubernetes部署wordpress+MySQL, 并利⽤NFS去保存我们容器的源代码以及DB数据。搭建好nfs后任意node上的Pod访问db或者业务代码都会有相同的效果，数据只存储一份。

## 步骤：

首先在10.11.113.166 搭建nfs⽂件系统 并建立共享 /opt/wwwroot
创建PersistentVolumeClaims(PVC)和PersistentVolume(PV)
创建service
创建Secret（注⼊MySql密码等）
创建confifigMap（初始化数据库）
部署MySQL容器组（Deployment）
部署WordPress容器组（Deployment）

注：在K8S上部署⼀个WordPress和MySQL应⽤，其中WordPress和MySQL都使⽤PersistentVolume 和 PersistentVolumeClaim 存储数据。
PersistentVolume 是集群中可⽤的⼀⽚存储空间，通常由集群管理员⼿⼯提供，或者由Kubernetes 使⽤ StorageClass ⾃动提供。
PersistentVolumeClaim 代表了⽤户（应⽤程序）对存储空间的需求，此需求可由PersistentVolume 满⾜。

## 1.创建NFS文件系统及共享

此步骤省略



## 2.PV、PVC定义文件以及创建

​	PV（PersistentVolume）在声明的时候需要指定大小和续写模式:["ReadWriteMany","ReadWriteOnce","ReadOnlyMany"],pv是集群声明的存储资源。实际资源部署请求的存储空间，称为PVC(PersistentVolumeClaim)。 pvc声明时也需要指定读写模式和大小。pvc关联某个pv后这个pv就不能再和别的pvc关联了。k8s会根据pvc的大小和读写模式在可用的PV中匹配一个最佳的pv与pvc关联。



### 2.1 PV的创建

```
vi pv-mysql.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
    name: mysql-pv
spec:
    capacity:
        storage: 3Gi
    accessModes: ["ReadWriteOnce"]
    persistentVolumeReclaimPolicy: Recycle
    nfs:
        path: /opt/wwwroot/mysql
        server: 10.11.113.166

```

​	

```
vi pv-wordpress.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
    name: wordpress-pv
spec:
    capacity:
        storage: 1Gi
    accessModes: ["ReadWriteOnce","ReadWriteMany"]
    persistentVolumeReclaimPolicy: Recycle
    nfs:
        path: /opt/wwwroot/wp
        server: 10.11.113.166

```



```
kubectl apply -f pv-mysql.yaml
kubectl apply -f pv-wordpress.yaml

kubectl get pv

[root@master01 lixlo]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                            STORAGECLASS   REASON   AGE
my-pv1                                     30Gi       RWO            Recycle          Terminating   wordpress-space/wp-pv-claim                              19h
mysql-pv                                   3Gi        RWO            Recycle          Bound         wordpress-space/mysql-pv-claim                           18h
pvc-a3051666-b71e-4201-b50a-06ba492e2624   100Mi      RWX            Retain           Bound         xiaojiang-test/test-claim        stateful-nfs            16h
wordpress-pv                               1Gi        RWO,RWX        Recycle          Bound         default/wordpress-pv-claim                               18h

```



### 2.2 PVC的创建

```
vi mysql-pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: mysql-pv-claim
spec:
    accessModes: ["ReadWriteOnce"]
    resources:
        requests:
            storage: 2Gi
```

```
vi wordpress-pvc.yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: wordpress-pv-claim
spec:
    accessModes: ["ReadWriteOnce","ReadWriteMany"]
    resources:
        requests:
            storage: 1Gi
```

```
kubectl apply -f mysql-pvc.yaml
kubectl apply -f wordpress-pvc.yaml
kubectl get pvc -o wide


```



## 3. SVC SECRET CONFIGMAP的创建

### 3.1 SVC的创建

```
vi service.yaml

#api版本号
apiVersion: v1
#资源类型
kind: Service
metadata:
    #service自身的名称
    name: mysql
    #service自身的标签
    labels:
        app: mysql
spec:
    ports:
      #service对外开放的端口
      - port: 3306
        #service关联资源对应container的端口，该端口与上面的port是绑定关系
        targetPort: 3306
        protocol: TCP
    #service通过选择器配置的两个label选择符合这两个标签的pod，为这些pod提供对外服务
    selector:
        app: wordpress
        tier: mysql-pod
    #service类型，ClusterIp只对内部提供服务，nodePort类型可以对外提供服务
    type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
    name: wordpress
    labels:
        app: wordpress
spec:
    ports:
      - port: 80
        nodePort: 30008
        targetPort: 80
        protocol: TCP
    selector:
        app: wordpress
        tier: frontend-pod
    type: NodePort
```

```
kubectl apply -f service.yaml
```



### 3.2 SECRET的创建

```
vi secret.yaml

apiVersion: v1
kind: Secret
metadata:
    name: mysql-pass
type: Opaque
#Opaque 隐藏，该类型使用kubectl的任何查看命令都看不到下面data部分定义的密码数据
data:
    #敏感数据通过base64编码处理echo -n $str | base64
    #password: root 
    password: 123456
    #可以设置多组数据
```

```
kubectl apply -f secret.yaml
```



### 3.3 CONFIGMAP的创建

```
vi configmap.yaml

apiVersion: v1
kind: ConfigMap
metadata:
    name: mysql-config
data:
    db-name: wordpress
    #可以设置多组数据，数值类型一定要使用""引起来，否则会报错
    userage: "18"
    dbuser: root
```

```
kubectl apply -f configmap.yaml
```



## 4.Deployment的创建

### 4.1 mysql Deployment的创建

```
vi mysql.yaml

#api版本
apiVersion: apps/v1
kind: Deployment
metadata:
    #deployment的名称
    name: wordpress-mysql
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
              - image: harbor.test.digitalchina.com/lamp/mysql:5.7  #使用之前搭建好的harbor的镜像文件
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
```



### 4.2 Wordpress Deployment的创建



```
vi wordpress.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
    name: wordpress
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
              - image: harbor.test.digitalchina.com/lamp/wordpress:latest  #使用之前搭建好的harbor的镜像文件
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



```
kubectl apply -f mysql.yaml
kubectl apply -f wordpress.yaml


kubectl get pod -o wide -n wordpress-space
NAME                               READY   STATUS    RESTARTS      AGE   IP               NODE       NOMINATED NODE   READINESS GATES
wordpress-84975ff9cf-8cp4f         1/1     Running   6 (18h ago)   19h   172.21.231.147   node02     <none>           <none>
wordpress-mysql-658cb7884c-nfz7z   1/1     Running   0             19h   172.18.71.6      master03   <none>           <none>
[root@master01 lixlo]# 

```

