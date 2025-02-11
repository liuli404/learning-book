# һ��NFS ׼��

## 1.1 ��װ nfs

```bash
yum install -y nfs-utils rpcbind
```

## 1.2 ���� nfs ����Ŀ¼

�� nfs-server ���ϴ���

```bash
mkdir -p /data/nfs
```

## 1.3 �޸�Ȩ��

�༭  `/etc/exports` �����ļ������һ������

```bash
/data/nfs *(rw,sync,no_wdelay,no_root_squash,insecure)
```

Ŀ¼��Ȩ

```bash
chown -R nfsnobody:nfsnobody /data/nfs
```

## 1.4 ���� nfs ����

```bash
systemctl start rpcbind && systemctl enable rpcbind
systemctl restart nfs && systemctl enable nfs
```

## 1.5  �鿴���ص�

```bash
$ showmount -e
Export list for harbor:
/data/nfs *
```

# �������� StorageClass

## 2.1 rbac-rolebind.yaml

```YAML
kind: Namespace                 
apiVersion: v1                                                           
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
```

## 2.2 nfs-provisioner.yaml

```yaml
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
              value: nfs-provisioner
            - name: NFS_SERVER
              value: 10.11.141.102
            - name: NFS_PATH
              value: /data/nfs
      volumes:
        - name: nfs-client-root
          nfs:
            server: 10.11.141.102
            path: /data/nfs
```

## 2.3 storageclass.yaml

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: stateful-nfs
  namespace: nfs
provisioner: nfs-provisioner
reclaimPolicy: Retain
```

```bash
kubectl apply -f rbac-rolebind.yaml
kubectl apply -f nfs-provisioner.yaml
kubectl apply -f storageclass.yaml 
```

## 2.4 �鿴�洢��

```bash
$ kubectl get pod -n nfs 
NAME                                     READY   STATUS    RESTARTS   AGE
nfs-client-provisioner-bd4f954cd-vbtx2   1/1     Running   0          6m43s

$ kubectl get sc
NAME           PROVISIONER       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
stateful-nfs   nfs-provisioner   Retain          Immediate           false                  6m44s
```

# ��������

## 3.1 ���� PVC

- pvc-test.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
    name: pv1-claim
spec:
    storageClassName: stateful-nfs
    accessModes: ["ReadWriteOnce"]
    resources:
        requests:
            storage: 2Gi
```

```bash
kubectl apply -f pvc-test.yaml
```

## 3.2 �鿴����

```bash
$ kubectl get pvc
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pv1-claim   Bound    pvc-4a808986-fad5-44f1-8744-af28e72dfbf2   2Gi        RWO            stateful-nfs   8s
```



