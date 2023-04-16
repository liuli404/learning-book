# 一、数组初始化

​	数组就是有序数据的集合。而数组中的每个元素都属于同一个数据类型。数组按照元素类型，可分为数值数组、字符数组、指针数组、结构数组等。

​	可以使用格式为 "variable[element(s)]" 的形式来对数组进行初始化。初始化，是指在内存中开辟一块存储空间，并指定数组的数据类型以及数组变量的元素个数。

​	对数组进行定义时，允许不指定数组中变量的个数，且在访问变量是可以动态改变数组中变量的个数。

​	对数组访问时，用数组变量的名称和指定下标，就可以访问指定的数组。

​	在内存中刚刚创建一块存储空间时，就形成了空数组。在脚本程序中，可以使用 declare 来指定一个数组。

## 1.1 一维数组

​	在 shell 中定义一堆数组，数组元素个数没有限定，而对数组的初始化有很多种方法。

初始化定义：

```bash
[root@192 ~]# array[a]=33
[root@192 ~]# value[b]=44
[root@192 ~]# city[c]=beijing
[root@192 ~]# echo ${array[a]}
33
[root@192 ~]# echo ${value[b]}
44
[root@192 ~]# echo ${city[c]}
beijing
```

declare 定义：

```bash
[root@192 ~]# declare array[A]=22
[root@192 ~]# declare value[B]=11
[root@192 ~]# declare city[b]=nanjing
[root@192 ~]# echo ${array[A]}
22
[root@192 ~]# echo ${value[B]}
11
[root@192 ~]# echo ${city[b]}
nanjing
```

赋值组合定义：

```bash
[root@192 ~]# city_list=(beijing shanghai gangzhou shenzhen)
[root@192 ~]# echo ${city_list[0]} ${city_list[1]} ${city_list[2]} ${city_list[3]}
beijing shanghai gangzhou shenzhen
```

通过下标输出所有元素

```bash
[root@192 ~]# echo ${city_list[@]}
beijing shanghai gangzhou shenzhen
[root@192 ~]# echo ${city_list[*]}
beijing shanghai gangzhou shenzhen
```

## 1.2 二维数组

​	在 shell 中，一般只支持一维数组。不过可以使用一些技巧来模拟二维数组。二维数组在本质上等同于一维数组，只不过增加了使用行和列的位置来引用和操作元素寻址。

```bash
#!/bin/bash

array1=(A B C)
array2=(D E F)
array3=(G H I)

for i in {1..4}
do
	eval value=\${array${i}[*]}
	for element in ${value}
	do
		echo -e ${value}
		continue 2
	done
done
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
A B C
D E F
G H I
```

## 1.3 空数组

​	空数组即不经过初始化定义的数组，它不占用任何内存空间。空数组中不含有数组元素。不过在空数组的使用上，还需要注意空数组与含有空元素的数组区别。

```bash
#!/bin/bash

array1=(hello linux)
array2=()
array3=(' ')

echo "array1: ${array1[@]}."
echo "array2: ${array2[@]}."
echo "array3: ${array3[@]}."
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
array1: hello linux.
array2: .
array3:  .
```

# 二、数组基本使用

## 2.1 数组元素

​	shell 可以对元素的长度、个数、元素中的字符以及字符串进行引用。

**1、元素提取**

```bash
#!/bin/bash

week=(Monday Tuesday Wendesday Thursday Friday)
# 读取第一个元素
echo ${week[0]}
# 从第一个元素的第 1 个字符读取
echo ${week:0}
# 从第一个元素的第 2 个字符读取
echo ${week:1}
echo
# 计算数组中第一个字符的长度
echo ${#week}
# 从第一个元素的第 1 个字符计算字符串长度
echo ${#week[0]}
# 从第一个元素的第 2 个字符计算字符串长度
echo ${#week[1]}
echo
# 计算元素的个数
echo ${#week[@]}
echo ${#week[*]}
```

​	运行结果

```bash
[root@192 ~]# bash test.sh
Monday
Monday
onday

6
6
7

5
5
```

**2、元素替换**

```bash
#!/bin/bash

week=(Monday Tuesday Wendesday Thursday Friday)

echo ${week[@]/Monday/First_day}
echo ${week[@]/T*/vacation}
echo ${week[@]/*iday/Day_Five}
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
First_day Tuesday Wendesday Thursday Friday
Monday vacation Wendesday vacation Friday
Monday Tuesday Wendesday Thursday Day_Five
```

**3、删改元素**

​	若是对元素进行删除，则不需要指定任何字符，若是为数组元素添加字符，则只需在数组后指定要添加的字符即可。

```bash
#!/bin/bash

week=(Monday Tuesday Wendesday Thursday Friday)
echo "<--delete character-->"
echo ${week[@]#M*y}
echo ${week[@]##F*y}
echo ${week[@]%Th*y}
echo ${week[@]%%W*y}

echo "<--add character-->"
echo ${week[@]/%/36}
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
<--delete character-->
Tuesday Wendesday Thursday Friday
Monday Tuesday Wendesday Thursday
Monday Tuesday Wendesday Friday
Monday Tuesday Thursday Friday
<--add character-->
Monday36 Tuesday36 Wendesday36 Thursday36 Friday36
```

## 2.2 内嵌数组

​	在一个数组内再嵌入一个数组，就得到内嵌数组。内嵌数组实际上是一个多维数组。

```bash
#!/bin/bash

array1=(
    var_a=element1
    var_b=element2
    var_c=element3
)

array2=(
    "${array1[*]}"
    "var_d=element4 var_e=element5 var_f=element6"
)

print (){
    echo ${array2[*]}
}

print
exit 0
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
var_a=element1 var_b=element2 var_c=element3 var_d=element4 var_e=element5 var_f=element6
```

## 2.3 数组与字符串

​	在 shell 中，可以将变量作为数组来操作。

```bash
#!/bin/bash

array=(This is a array)
string=abcdef1234

echo ${array[0]}
echo ${string[0]}

echo ${#array[@]}
echo ${#string[@]}
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
This
abcdef1234
4
1
```

# 三、数组的应用

​	数组占据着连续的存储单元，最低地址对应数组的第一个元素，最高的地址则对应最后一个元素。

## 3.1 数组的复制与连接

​	在 bash 中可以对数组进行复制和连接，在对变量的操作中，可以使用带有选项 -a 的 declare 指令来加快数组的操作速度。

```bash
#!/bin/bash

declare -a array1=(this is A)
declare -a array2=()

array2=${array1[@]}

declare -a array3=(${array1[@]} ${array2[@]})

echo ${array2[@]}
echo ${array3[@]}
```

​	运行结果

```bash
[root@192 ~]# bash test.sh 
this is A
this is A this is A
```