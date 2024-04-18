# 一、定义与初始化

Map 是一种无序的键值对的集合，底层采用哈希表实现。

Map 最重要的一点是通过 key 来快速检索数据，key 类似于索引，指向数据的值。

Map 是一种集合，所以我们可以像迭代数组和切片那样迭代它。不过，Map 是无序不重复的，遍历 Map 时返回的键值对的顺序是不确定的。

在获取 Map 的值时，如果键不存在，返回该类型的零值，例如 int 类型的零值是 0，string 类型的零值是 ""。

Map 是**引用类型**，如果将一个 Map 传递给一个函数或赋值给另一个变量，它们都指向同一个底层数据结构，因此对 Map 的修改会影响到所有引用它的变量。

## 1.1 定义Map

```go
map_variable := make(map[KeyType]ValueType, initialCapacity)
```

- KeyType 是键的类型
- ValueType 是值的类型
- initialCapacity 是可选的参数，用于指定 Map 的初始容量。

Map 的容量是指 Map 中可以保存的键值对的数量，当 Map 中的键值对数量达到容量时，Map 会自动扩容。如果不指定 initialCapacity，Go 语言会根据实际情况选择一个合适的值。

## 1.2 声明初始化

```go
package main

import "fmt"

// map_variable := make(map[KeyType]ValueType, initialCapacity)

func main() {
	// 声明一个空的 Map
	m1 := make(map[int]string)
	// 声明一个初始容量为 10 的 Map
	m2 := make(map[string]string, 10)
	// 字面量创建
	m3 := map[int]string{
		1: "小红",
		2: "小明",
		3: "小刚",
	}
	fmt.Printf("m1: %v\n", m1)
	fmt.Printf("m2: %v\n", m2)
	fmt.Printf("m3: %v\n", m3)
}
```

运行结果

```go
m1: map[]
m2: map[]
m3: map[1:小红 2:小明 3:小刚]
```

# 二、集合操作

## 2.1 查找元素

使用key来查找，时间复杂度为O(1)，效率最高。

```go
package main

import "fmt"

func main() {
	m1 := map[int]string{
		1: "小红",
		2: "小明",
		3: "小刚",
	}
	fmt.Printf("m1[1]: %v\n", m1[3])
	v2, ok := m1[4] // 如果键不存在，ok 的值为 false，v2 的值为该类型的零值
	if ok {
		fmt.Println(v2)
	} else {
		fmt.Println("该键值不存在")
	}
}
```

运行结果

```go
m1[1]: 小刚
该值不存在
```

## 2.2 修改元素

```go
package main

import "fmt"

func main() {
	m1 := map[int]string{
		1: "小红",
		2: "小明",
		3: "小刚",
	}
	m1[3] = "张三"
	fmt.Printf("m1[3]: %v\n", m1[3])
}
```

运行结果

```go
m1[1]: 张三
```

## 2.3 遍历集合

```go
package main

import "fmt"

func main() {
	m1 := map[int]string{
		1: "小红",
		2: "小明",
		3: "小刚",
	}
	for k, v := range m1 {
		fmt.Println(k, v)
	}
}
```

运行结果

```go
1 小红
2 小明
3 小刚
```

## 2.4 删除元素

```go
package main

import "fmt"

func main() {
	m1 := map[int]string{
		1: "小红",
		2: "小明",
		3: "小刚",
	}
	fmt.Println(m1)
	delete(m1, 2)
	fmt.Println(m1)
}
```

运行结果

```go
map[1:小红 2:小明 3:小刚]
map[1:小红 3:小刚]
```

