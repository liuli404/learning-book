# 一、什么是OpenStack？

OpenStack是一个云操作系统，它控制整个数据中心的大型计算、存储和网络资源池，所有这些资源都通过具有通用身份验证机制的API进行管理和配置。

除了标准的IaaS功能之外，其他组件还提供编排、故障管理和服务管理以及其他服务，以确保用户应用程序的高可用性。

![image-20240912103605434](./00-OpenStack%E7%AE%80%E4%BB%8B/image-20240912103605434.png)

# 二、OpenStack架构

OpenStack被分解成多个服务，根据需要即插即用组件。

![OpenStack Cloud landscape map](./00-OpenStack%E7%AE%80%E4%BB%8B/openstack-map-v20240401.png)

# 三、核心组件介绍

## 3.1 Nova 

Nova提供了一种配置计算实例（也称为虚拟服务器）的方法。Nova支持创建虚拟机、裸机服务器（通过使用ironic），并且对系统容器的支持有限。

## 3.2 Cinder

Cinder是OpenStack的块存储服务。它虚拟化了块存储设备的管理，并为最终用户提供了一个自助服务API来请求和使用这些资源

## 3.3 Neutron

Neutron是一个SDN网络项目，专注于在虚拟计算环境中提供网络即服务（NaaS）。

## 3.4 Keystone

Keystone是一种OpenStack服务，通过实现OpenStack的Identity API，提供API客户端身份认证、服务发现和分布式多租户授权。它支持LDAP、OAuth、OpenID Connect、SAML和SQL。

## 3.5 Glance

Glance image服务包括发现、注册和检索虚拟机映像。Glance有一个RESTful API，允许查询虚拟机映像元数据以及检索实际映像。

## 3.6 Placement

Placement是一项OpenStack服务，它提供了一个HTTP API来跟踪云资源库存和使用情况，以帮助其他服务有效地管理和分配其资源。