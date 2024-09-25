# 【DWS_01010】DWS集群状态异常
## 问题现象
OC运维平台产生【紧急告警】集群状态异常；DWS集群控制台紧急告警，但是没有集群实例信息。

## 问题原因
经排查“DWS_test”集群已经被删除，实例列表中也没有该集群。但是后台的集群状态监控组件还在对该集群持续监控，导致运维平台持续告警。初步定位该集群被非标操作删除，导致有配置没有更改。

## 解决方案

### 步骤一
登录到DWS-Gauss-DB01虚拟机（虚拟机IP可在serviceOM平台根据名称查到，服务器账号密码在账户一览表中搜虚拟机名称，使用opsadmin登录再切换root操作）。

### 步骤二
使用以下命令，连接gauss数据库，查询DWS实例列表。
```bash
[root@DWS-Gauss-DB01 ~]# su - dbadmin
[dbadmin@DWS-Gauss-DB01 ~]$ gsql -d dms -p 8635 -WMXXXXXXX3
DMS=# select * from DMS_META_CLUSTER;
```
查询到的实例列表，已经没有DWS_test集群实例：
 
### 步骤三
登录ECF-Common-DB01管理面虚拟机，连接MySQL数据库。
```bash
# 登陆数据库命令
su - mysql
mysql --defaults-file=/data/mysql/etc/my.cnf -uroot -hlocalhost -P7306 -pvXXXXXXXA
```
 
### 步骤四
切换monitor库，修改监控配置。
```sql
# 修改监控配置，注意insce_name 与 cluster_id 的值
mysql> use monitor;
mysql> select id,instance_orig_id,instance_name,cluster_id,monitor_id,monitored,monitor_switch,status,event_update_at,namespace from instance_monitor where insce_name like '%DWS_test%';
mysql> update instance_monitor set monitor_switch=0, monitored=0 where monitor_switch=1 and cluster_id='421c8fa8-d8eb-4f8b-8fe4-04b169f7b703';
mysql> select id,instance_orig_id,instance_name,cluster_id,monitor_id,monitored,monitor_switch,status,event_update_at,namespace from instance_monitor where insce_name like '%DWS_test%';
```

### 步骤五
切换event库，清除DWS控制台告警信息。
```sql
# 删除 console 面告警信息，注意resource_id与 occur_time 的值
mysql> use event;
mysql> select * from alarm_record where resource_id='9576f1eb-04e7-4c06-abc0-d1e58bdbbc79' order by occur_time desc limit 1;
mysql> delete from alarm_record where resource_id='9576f1eb-04e7-4c06-abc0-d1e58bdbbc79' and occur_time='2024-09-24 07:14:22';
```

### 步骤六
查看DWS集群控制台的紧急告警是否已被清除。
 
### 步骤七
手动清除OC平台的告警信息，并持续观察一段时间是否还会告警。

