# 一、用户与用户组的概念

## 1.1 为什么要做用户与用户组管理

用户和用户组管理，就是添加用户和用户组，针对每个用户设置不同的密码。

服务器要添加多账户的作用：

- 针对不同用户分配不同的权限，不同权限可以限制用户可以访问到的系统资源
- 提高系统的安全性
- 帮助系统管理员对使用系统的用户进行跟踪



## 1.2 用户及用户组

###  1.2.1 多用户多任务

​        Linux 系统是一个**多用户多任务**的操作系统，所谓多用户多任务，是指支持多个用户在同一时间内登陆，不同用户可以执行不同的任务，并且互不影响。

​        例如：

​        小明所在的运维团队一共有四个人，分别有大毛，二毛，三毛，大毛负责网站，他的账户叫wangzhan， 二毛负责数据库，他的账户叫shujuku。

​        在同一时间，大毛和二毛都可以登录这台服务器，大毛可以查询网站的日志，二毛可以处理数据库的问题，他们之间互不影响。

​        由于我们设置了权限，大毛只能访问网站的日志，无法访问数据库；二毛可以处理数据库问题，但是不能访问网站的日志。这就实现了我们的多用户多任务的运行机制。



### 1.2.2 什么是用户

​        任何一个运维人员想要登录服务器，都必须先申请一个账号，然后以这个账号的身份进入系统，就像我们前面说的wangzhan这个账号。
​        每个账号都拥有一个唯一的用户名和各自的密码，用户在登录时输入正确的用户名和密码后，就能够进入系统，默认会进入到这个用户自己的主目录
​        

### 1.2.3 什么是用户组

​        用户组是具有相同特征用户的逻辑集合，简单来说，就是**具有相同权限的用户的集合**。
​        例如：人事部有20名员工，他们都需要访问一个文件夹，如果我们给这20个用户的账号分别设置权限，这样太麻烦了，所以我们会建立一个用户组叫HR，对这个组设置权限，将这20个用户加入这个组就可以了。



### 1.2.4 用户和用户组的关系

A：一个用户可以属于一个用户组，具有此用户组的权限  

​	HR 组可以访问 /hrfile 的文件夹，当 user01 属于 HR 组，那么 user01 就可以访问 /hrfile 这个文件夹

B：一个用户可以属于**多个用户组**，此时具有多个组的共同权限

​	HR 可以访问 /hrfile 的文件夹，运维可以访问 /yunweifile 的文件夹，当 user01 同时属于 HR 组和运维组，那么 user01 可以访问 /hrfile 和 /yunweifile

C：多个用户可以属于一个用户组，多个用户都具有此用户组的权限。



**主组**：指用户创建时默认所属的组，每个用户的主组只能有一个。创建用户时会同时创建一个和用户名相同的组

​	例如：添加用户xiaoming，在建立用户 xiaoming 的同时，就会建立 xiaoming 组作为 xiaoming 用户的初始组。

**附加组**：每个用户只能有一个主组，除主组外，用户再加入其他的用户组，这些用户组就是这个用户**的附加**组。
	每个用户的附加组可以有多个，而且用户可以有这些附加组的权限。

通常用户和用户组的管理，包含以下工作：

☆ 用户组的管理

☆ 用户账号的添加、删除、修改以及用户密码的管理

注意三个文件：

☆ /etc/passwd   用户配置文件，存储用户的基本信息

☆ /etc/group      存储用户组的信息

☆ /etc/shadow   存储用户的密码信息

## 1.3 用户的类别

1. root 超级管理员，在 Linux 系统中拥有至高无上的权力。

2. 系统用户，CentOS6=> 1 ~ 499，CentOS7=> 1 ~ 999，系统账号默认不允许登录

```bash
useradd -s /sbin/nologin 系统用户
```

3. 普通用户，大部分是由root管理员创建的，UID的取值范围：CentOS6=> 500 ~ 60000，CentOS7=> 1000 ~ 60000，对系统进行有限的管理维护操作

# 二、用户和用户组管理

## 2.1 用户组管理

### 2.1.1 用户组添加

命令：groupadd

作用：添加组

语法：`groupadd [参数选项 选项值] 用户组名`

选项：-g：设置用户组 ID 数字，如果不指定，则默认从1000 之后递增（1-999系统组）

```bash
groupadd hr
含义：新建一个组叫做 hr
```

存储用户组信息的文件：/etc/group 文件结构：

```bash
hr : x : 1000 : xxxxx
用户组名 : 密码(占位符) : 用户组ID : 这个组包含的用户(附属组)
```

### 2.1.2 用户组修改

命令：groupmod

语法：`groupmod [选项 选项值] 用户组名`

选项：

-g  ：gid 缩写，设置一个自定义的用户组 ID 数字

-n  ：name 缩写，设置新的用户组的名称

```bash
groupmod -g 1100 -n bjhr hr
含义：将 hr 组的组 ID 改成 1100，组名改成 bjhr
```

### 2.1.3 用户组删除

命令：groupdel

语法：`groupdel 用户组名`

案例：删除 bjhr 组

```bash
groupdel bjhr
含义：将 bjhr 组删除
```

## 2.2 用户管理

### 2.2.1 添加用户

命令：useradd

作用：添加用户

语法：`useradd [选项 选项的值] 用户名`

选项：

- -g：表示指定用户的用户主（主要）组，选项值可以是用户组 ID，也可以是组名

- -G：表示指定用户的用户附加（额外）组，选项值可以是用户组 ID，也可以是组名

- -u：uid，用户的 id（用户的标识符），系统默认会从 500 或 1000 之后按顺序分配 uid，如果不想使用系统分配的，可以通过该选项自定义

- -c：comment，添加注释（选择是否添加）

- -s：指定用户登入后所使用的 shell 解释器，默认 /bin/bash，如果不想让其登录，则可以设置为 /sbin/nologin

- -d：指定用户登入时的启始目录（家目录位置）

- -n：取消建立以用户名称为名的群组（了解）

- -r：指定用户为系统用户，如创建一个系统账号 mysql

```bash
# 创建用户 zhangsan，不带任何选项。
useradd zhangsan
```

>  注意：不用任何参数，创建用户，系统会默认执行以下操作：
>
> 1. 在 /etc/passwd 文件中创建一行关于 zhangsan 用户的数据
>
> 2. 在 /etc/shadow 文件中新增了一行关于 zhangsan 密码的数据
>
> 3. 在 /etc/group 文件中创建一行与用户名相同的组，例如 zhangsan
>
> 4. 在 /etc/gshadow 文件中新增一行与新增群组相关的密码信息，例如 zhangsan
>
> 5. 自动创建用户的家目录，默认在 /home 下，与用户名同名

```bash
# 创建一个账号lisi，指定用户的家目录为/rhome/lisi
useradd -d /rhome/lisi lisi
```

> 当我们为用户自定义家目录时，其上级目录必须是真实存在的，如 /rhome

```bash
# 在 Linux 系统中创建一个 mysql 账号，要求真实存在的，但是其不允许登录操作系统
useradd mysql -s /sbin/nologin
```

```bash
# 在 Linux 系统中创建一个 mysql 系统账号，要求真实存在，但是不允许登录操作系统
useradd -r -s /sbin/nologin mysql
```



### 2.2.2 用户信息的文件

使用 vim 命令打开 /etc/passwd文件：

```bash
root  : x   : 0     : 0       : root : /root : /bin/bash
用户名 : 密码 : 用户ID : 用户组ID : 注释 : 家目录 : 解释器 shell
```

- **用户名**：登录 linux 时使用的用户名
- **密码**：此密码位置一般情况都是"x"，表示密码的占位，真实密码存储在 /etc/shadow
- **用户ID**：用户的识别符，每个用户都有唯一的 UID
- **用户组ID**：该用户所属的主组 ID
- **注释**：解释该用户是做什么用的 
- **家目录**：用户登录进入系统之后默认的位置
- **解释器shell**：等待用户进入系统之后，用户输入指令之后，该解释器会收集用户输入的指令，转换成机器语言，传递给内核处理；如果解释器是 /bin/bash 表示用户可以登录到系统，/sbin/nologin表示该用户不能登录到系统

```bash
# 创建用户lisi，默认 lisi 属于自己同名的主组，让 lisi 属于附加组 gzhr，用户ID 1200，注释为"hruser lisi"，解释器为不允许登录系统
useradd -G gzhr -u 1200 -s /sbin/nologin -c "gzuser lisi" lisi
```

### 2.2.3 查看用户信息

命令：id

作用：查看一个用户的一些基本信息（包含用户 id，用户组 id，附加组 id…），该指令如果不指定用户则默认当前用户。

语法：

`id`  默认显示当前执行该命令的用户的基本信息

`id 用户名`  显示指定用户的基本信息

### 2.2.4 修改用户属性

命令：usermod(user modify)

语法：`usermod [选项 选项的值] 用户名`

作用：修改用户的各种属性

选项：

- -g：表示指定用户的用户主组，选项的值可以是用户组的ID，也可以是组名

- -G：表示指定用户的用户附加组，选项的值可以是用户组的ID，也可以是组名

- -u：uid，用户的 id（用户的标识符），系统默认会从500 之后按顺序分配uid，如果不想使用系统分配的，可以通过该选项自定义

- -L：锁定用户，锁定后用户无法登陆系统

- -U：解锁用户 unlock

- -c：修改用户帐号的备注文字

- -d：修改用户登入时的目录

- -s：修改用户登入后所使用的 shell
- -m：迁移家目录时，把环境变量配置文件一起迁移到新的家目录

```bash
# 创建了某个账号，但是不希望这个账号登录操作系统
usermod -s /sbin/nologin 用户名称
```

```bash
# 修改用户 zhangsan 的家目录为 /rhome/zhangsan
usermod -md /rhome/zhangsan zhangsan
```

### 2.2.5  修改用户密码

Linux 不允许没有密码的用户登录到系统，因此前面创建的用户目前都处于锁定状态，需要设置密码之后才能登录计算机。

命令：passwd

语法：`passwd 用户名`【如果不指定用户名则默认修改自己的密码】

```bash
# 为 wangwu 账户设置密码
[root@ecs-d886 ~]# passwd wangwu
Changing password for user wangwu.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.
```

命令：`--stdin`

语法：`echo "密码" | passwd --stdin 用户名`

```bash
[root@ecs-d886 ~]# echo "123456@yszc" | passwd --stdin wangwu
Changing password for user wangwu.
passwd: all authentication tokens updated successfully.
```

> 注意：以上方式操作非常简单，但是以上命令会留在 history 历史命令中！使用 `history -c` 清除历史命令。

### 2.2.6 切换用户

​	在设置用户密码之后就可以使用此账号进行登录系统了，如果系统处于已登录状态，则可以使用 su 命令进行切换用户。

​	为了系统安全，企业中通常不会允许 root 用户直接登录计算机，但是工作需要，我们又需要使用 root 权限，这时候，我们就可以先使用一个普通用户登录计算机，再通过 su 命令切换到 root 权限。

命令：su

语法：`su [-] 账号`

作用：切换用户

```bash
su root
含义：切换到 root 权限
```

注意：

​	从 root 往普通用户切换不需要密码，但是反之则需要 root 密码

​	切换用户之后前后的工作路径是不变的，添加了选项[-]会自动切换到用户的家

​	普通用户没有办法访问 root 用户家目录，但是反之则可以

### 2.2.7 启用 wheel 组

使用 vim 编辑器打开 /etc/pam.d/su 文件，去掉 `auth required pam_wheel.so use_uid`这一行前面的 #，使这一行配置生效

```bash
auth            required        pam_wheel.so use_uid
```

这时，只有在wheel组内的用户才可以su到root

### 2.2.8 删除用户

命令：userdel

语法：`userdel 选项 用户名`

作用：删除账户及其对应家目录

选项：

- -r：表示删除用户的同时，删除其家目录 /home下的对应文件夹
- -f：强制删除用户（即使用户处于登录状态）

```bash
# 删除 zhangsan 这个账号
userdel zhangsan
```

```bash
# 删除 zhangsan 这个账号，同时删除这个账号的家
userdel -r zhangsan
```

```bash
# 删除某个正在使用的账号（强制删除）
userdel -f zhangsan
```

### 2.2.9 更改用户密码规则

功能：chage 命令用于更改用户密码的过期时间和账户信息的相关设置。它可以修改用户的密码有效期、账户锁定时间、账户过期时间等。

语法：`chage [选项] 用户名`

选项：

- -l：列出用户的详细密码状态;
- -d 日期：修改 /etc/shadow 文件中指定用户密码信息的第3个字段，也就是最后一次修改密码的日期，格式为 YYYY-MM-DD;
- -m 天数：修改密码最短保留的天数，也就是 /etc/shadow 文件中的第4个字段;
  - 注：几天后才能修改一次密码
- -M 天数：修改密码的有效期，也就是 /etc/shadow 文件中的第5个字段;
  - 注：每隔多少天更新一次密码
- -W 天数：修改密码到期前的警告天数，也就是 /etc/shadow 文件中的第6个字段;

- -i 天数：修改密码过期后的宽限天数，也就是 /etc/shadow 文件中的第7个字段;
  - 注：过期后还可以使用的天数，达到这个天数后，账号失效

- -E 日期：修改账号失效日期，格式为 YYYY-MM-DD，也就是 /etc/shadow 文件中的第8个字段;

```bash
# 查看 wangwu 的详细状态
# chage -l wangwu
Last password change				: Sep 12, 2023
Password expires					: never
Password inactive					: never
Account expires						: never
Minimum number of days between password change		: 0
Maximum number of days between password change		: 99999
Number of days of warning before password expires	: 7
```

```bash
# 要求用户 lamp 第一次登陆后必须强制修改密码。
# 把密码的最后修改时间重置为 0
chage -d 0 lamp
```

```bash
# 设置 lamp 账号的过期时间为 2025-04-10
[root@ecs-d886 ~]# chage -E "2025-04-10" lamp
[root@ecs-d886 ~]# chage -l lamp
Last password change				: password must be changed
Password expires					: password must be changed
Password inactive					: password must be changed
Account expires						: Apr 10, 2025
Minimum number of days between password change		: 0
Maximum number of days between password change		: 99999
Number of days of warning before password expires	: 7
```

```bash
# 设置 lamp 账号的 10 天后过期
[root@ecs-d886 ~]# chage -E $(date +%F -d '+10 days') lamp
[root@ecs-d886 ~]# chage -l lamp
Last password change				: password must be changed
Password expires					: password must be changed
Password inactive					: password must be changed
Account expires						: Sep 22, 2023
Minimum number of days between password change		: 0
Maximum number of days between password change		: 99999
Number of days of warning before password expires	: 7
```

```bash
# 设置 mysql 用户 60 天后密码过期，至少 7 天后才能修改密码，密码过期前 7 天开始收到告警信息
chage -M 60 -W 7 -m 7 mysql 
```

