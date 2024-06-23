# 一、VLAN

## 1.1 给交换机创建不同的VLAN

VLAN技术可以把一个LAN划分成多个逻辑的VLAN。通过划分不同的虚拟局域网，VLAN内的主机间通信就和在一个LAN内一样，而VLAN间则不能直接互通，广播报文就被限制在一个VLAN内。

VLAN具备以下优点：

- **限制广播域**：广播域被限制在一个VLAN内，节省了带宽，提高了网络处理能力。
- **增强局域网的安全性**：不同VLAN内的报文在传输时相互隔离，即一个VLAN内的用户不能和其它VLAN内的用户直接通信。
- **提高了网络的健壮性**：故障被限制在一个VLAN内，本VLAN内的故障不会影响其他VLAN的正常工作。
- **灵活构建虚拟工作组**：用VLAN可以划分不同的用户到不同的工作组，同一工作组的用户也不必局限于某一固定的物理范围，网络构建和维护更方便灵活。

![VLAN的作用](./03-Vlan%E4%B8%8EACL/download.png)

| 功能                          | 命令                               |
| ----------------------------- | ---------------------------------- |
| 进入系统配置视图              | system-view                        |
| 创建VLAN                      | vlan \<vlan_id>                    |
| 查看存在的VLAN列表            | display vlan                       |
| 进入接口                      | interface GigabitEthernet <接口号> |
| 把当前接口的模式设置成 access | port link-type \<模式>             |
| 把当前接口加入VLAN            | port default  vlan \<vlan_id>      |
| 退到系统视图                  | quit                               |

交换机的接口模式：

1. access：常用于接入链路，即能识别VLAN标识的连接PC机，终端设备和路由器的接口
2. trunk：常用于中继链路，即两台交换机之间相连的链路
3. hybrid：混杂模式，用于任意场景，但Hybrid的灵活性很高不易于配置

![image-20240623162339090](./03-Vlan%E4%B8%8EACL/image-20240623162339090.png)

- 创建vlan

```cmd
<Huawei>system-view 
Enter system view, return user view with Ctrl+Z.

[Huawei]vlan 10
[Huawei]vlan 20
[Huawei-vlan20]display vlan
The total number of vlans is : 3
--------------------------------------------------------------------------------
U: Up;         D: Down;         TG: Tagged;         UT: Untagged;
MP: Vlan-mapping;               ST: Vlan-stacking;
#: ProtocolTransparent-vlan;    *: Management-vlan;
--------------------------------------------------------------------------------

VID  Type    Ports                                                          
--------------------------------------------------------------------------------
1    common  UT:GE0/0/1(U)      GE0/0/2(U)      GE0/0/3(D)      GE0/0/4(D)      
                GE0/0/5(D)      GE0/0/6(D)      GE0/0/7(D)      GE0/0/8(D)      
                GE0/0/9(D)      GE0/0/10(D)     GE0/0/11(D)     GE0/0/12(D)     
                GE0/0/13(D)     GE0/0/14(D)     GE0/0/15(D)     GE0/0/16(D)     
                GE0/0/17(D)     GE0/0/18(D)     GE0/0/19(D)     GE0/0/20(D)     
                GE0/0/21(D)     GE0/0/22(D)     GE0/0/23(D)     GE0/0/24(D)     

10   common  
20   common  

VID  Status  Property      MAC-LRN Statistics Description      
--------------------------------------------------------------------------------
1    enable  default       enable  disable    VLAN 0001                         
10   enable  default       enable  disable    VLAN 0010                         
20   enable  default       enable  disable    VLAN 0020
```

- 将接口加入vlan

```cmd
[Huawei]interface GigabitEthernet 0/0/1
[Huawei-GigabitEthernet0/0/1]port link-type access
[Huawei-GigabitEthernet0/0/1]port default vlan 10
[Huawei-GigabitEthernet0/0/1]quit
[Huawei]interface GigabitEthernet 0/0/2
[Huawei-GigabitEthernet0/0/2]port link-type access
[Huawei-GigabitEthernet0/0/2]port default vlan 20
[Huawei-GigabitEthernet0/0/2]quit
[Huawei]display vlan
The total number of vlans is : 3
--------------------------------------------------------------------------------
U: Up;         D: Down;         TG: Tagged;         UT: Untagged;
MP: Vlan-mapping;               ST: Vlan-stacking;
#: ProtocolTransparent-vlan;    *: Management-vlan;
--------------------------------------------------------------------------------

VID  Type    Ports                                                          
--------------------------------------------------------------------------------
1    common  UT:GE0/0/3(D)      GE0/0/4(D)      GE0/0/5(D)      GE0/0/6(D)      
                GE0/0/7(D)      GE0/0/8(D)      GE0/0/9(D)      GE0/0/10(D)     
                GE0/0/11(D)     GE0/0/12(D)     GE0/0/13(D)     GE0/0/14(D)     
                GE0/0/15(D)     GE0/0/16(D)     GE0/0/17(D)     GE0/0/18(D)     
                GE0/0/19(D)     GE0/0/20(D)     GE0/0/21(D)     GE0/0/22(D)     
                GE0/0/23(D)     GE0/0/24(D)                                     

10   common  UT:GE0/0/1(U)                                                      
20   common  UT:GE0/0/2(U)                                                      

VID  Status  Property      MAC-LRN Statistics Description      
--------------------------------------------------------------------------------
1    enable  default       enable  disable    VLAN 0001                         
10   enable  default       enable  disable    VLAN 0010                         
20   enable  default       enable  disable    VLAN 0020   
```

## 1.2 配置跨交换机同VLAN通信

通过给两个交换机之间的接口配置 trunk 模式，可以实现不同交换机同 VLAN 通信。

![image-20240623165936797](./03-Vlan%E4%B8%8EACL/image-20240623165936797.png)

| 功能                                | 命令                                  |
| ----------------------------------- | ------------------------------------- |
| 进入系统配置视图                    | system-view                           |
| 进入接口                            | interface GigabitEthernet <接口号>    |
| 把当前接口的模式设置成 access\trunk | port link-type <模式>                 |
| 把当前接口加入VLAN                  | port default  vlan \<vlan_id>         |
| 设置当前接口允许通过的VLAN          | port trunk allow-pass vlan \<vlan_id> |
| 退到系统视图                        | quit                                  |

LSW2 创建配置 VLAN 的步骤与 LSW1一样，这里省略....

- LSW1 0/0/3 接口配置 trunk 模式

```cmd
[Huawei]interface GigabitEthernet 0/0/3
[Huawei-GigabitEthernet0/0/3]port link-type trunk 
[Huawei-GigabitEthernet0/0/3]port trunk allow-pass vlan 10
[Huawei-GigabitEthernet0/0/3]port trunk allow-pass vlan 20
```

- LSW2 0/0/1 接口配置 trunk 模式

```cmd
[Huawei]interface GigabitEthernet 0/0/1
[Huawei-GigabitEthernet0/0/1]port link-type trunk 
[Huawei-GigabitEthernet0/0/1]port trunk allow-pass vlan 10
[Huawei-GigabitEthernet0/0/1]port trunk allow-pass vlan 20
```

经过以上配置，同VLAN不同交换机下的主机就可以通信了。

## 1.3 配置三层交换连通不同的VLAN

在三层交换机配置vlanif，来打通两个不同vlan的网络。

![image-20240623182957497](./03-Vlan%E4%B8%8EACL/image-20240623182957497.png)

| 功能                                | 命令                                  |
| ----------------------------------- | ------------------------------------- |
| 进入系统配置视图                    | system-view                           |
| 进入接口                            | interface GigabitEthernet <接口号>    |
| 把当前接口的模式设置成 access\trunk | port link-type <模式>                 |
| 把当前接口加入VLAN                  | port default  vlan \<vlan_id>         |
| 设置当前接口允许通过的VLAN          | port trunk allow-pass vlan \<vlan_id> |
| 进入 VLANIF 接口                    | interface vlanif  \<vlan_id>          |
| 配置IP地址                          | ip  addr \<ip> \<mask>                |
| 退到系统视图                        | quit                                  |

LSW1、LSW2的 vlan 与 trunk 配置见以上步骤，以下只配置与 LSW3 新增的配置....

- LSW1 0/0/4 接口配置trunk

```cmd
[Huawei]interface GigabitEthernet 0/0/4
[Huawei-GigabitEthernet0/0/4]port link-type trunk 
[Huawei-GigabitEthernet0/0/4]port trunk allow-pass vlan 10
[Huawei-GigabitEthernet0/0/4]port trunk allow-pass vlan 20
```

- LSW2 0/0/4 接口配置trunk

```cmd
[Huawei]interface GigabitEthernet 0/0/4
[Huawei-GigabitEthernet0/0/4]port link-type trunk 
[Huawei-GigabitEthernet0/0/4]port trunk allow-pass vlan 10
[Huawei-GigabitEthernet0/0/4]port trunk allow-pass vlan 20
```

- LSW3 0/0/1、0/0/2接口创建vlan10、20并配置trunk、ip

VLANIF接口是网络层接口，创建VLANIF接口前要先创建了对应的VLAN，才可以配置IP地址。借助VLANIF接口，交换机就能与其它网络层的设备互相通信

```cmd
# 创建vlan
[Huawei]vlan 10
[Huawei]vlan 20

# 配置接口1的trunk
[Huawei]interface GigabitEthernet 0/0/1
[Huawei-GigabitEthernet0/0/1]port link-type trunk 
[Huawei-GigabitEthernet0/0/1]port trunk allow-pass vlan 10
[Huawei-GigabitEthernet0/0/1]port trunk allow-pass vlan 20

# 配置接口2的trunk
[Huawei]interface GigabitEthernet 0/0/2
[Huawei-GigabitEthernet0/0/2]port link-type trunk 
[Huawei-GigabitEthernet0/0/2]port trunk allow-pass vlan 10
[Huawei-GigabitEthernet0/0/2]port trunk allow-pass vlan 20

# vlanif 接口配置
[Huawei]interface vlanif 10
[Huawei-Vlanif10]ip addr 192.168.1.254 255.255.255.0

[Huawei]interface vlanif 20
[Huawei-Vlanif20]ip addr 192.168.2.254 255.255.255.0
```

