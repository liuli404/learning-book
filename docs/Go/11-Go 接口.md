# 一、接口定义

Go 语言提供了另外一种数据类型即接口，它把所有的具有共性的方法定义在一起，任何其他类型只要实现了这些方法就是实现了这个接口。

接口可以让我们将不同的类型绑定到一组公共的方法上，从而实现多态和灵活的设计。

Go 语言中的接口是隐式实现的，也就是说，如果一个类型实现了一个接口定义的所有方法，那么它就自动地实现了该接口。因此，我们可以通过将接口作为参数来实现对不同类型的调用，从而实现多态。

```go
/* 定义接口 */
type 接口名 interface {
    方法1 (参数列表1) 返回值列表1
    方法2 (参数列表2) 返回值列表2
    ...
}

/* 定义结构体 */
type struct_name struct {
   /* variables */
}

/* 实现接口方法 */
func (struct_name_variable struct_name) method_name1() [return_type] {
   /* 方法实现 */
}
...
func (struct_name_variable struct_name) method_namen() [return_type] {
   /* 方法实现*/
}
```

- 接口命名习惯在接口名后面加上er后缀
- 参数列表、返回值列表参数名可以不写
- 如果要在包外使用接口，接口名应该首字母大写，方法要在包外使用，方法名首字母也要大写
- 接口中的方法应该设计合理，不要太多

Go语言的接口设计是非侵入式的，接口编写者无需知道接口会被哪些类型实现。而接口实现者只需知道 实现的是什么样子的接口，但无需指明实现哪一个接口。编译器知道最终编译时使用哪个类型实现哪个 接口，或者接口应该由谁来实现。

```go
package main

import "fmt"

// 如果一个结构体实现了一个接口声明的所有方法，就说结构体实现了该接口。
type Phoner interface {
	act()
	call()
}

type Nokia struct {
}

type IPhone struct {
}

func (n Nokia) act() {
	fmt.Println("我是诺基亚，我可以砸核桃")
}

func (n Nokia) call() {
	fmt.Println("我是诺基亚，可以打电话")
}

func (i IPhone) act() {
	fmt.Println("我是苹果，我可以打视频")
}

func (i IPhone) call() {
	fmt.Println("我是苹果卫星通话")
}

func main() {
	var phone Phoner
	phone = new(Nokia)
	phone.act()

	phone = new(IPhone)
	phone.act()
}
```

运行结果

```go
我是诺基亚，我可以砸核桃
我是苹果，我可以打视频
```

# 二、接口嵌套

除了结构体可以嵌套，接口也可以。接口嵌套组合成了新接口。

```GO
type Reader interface {
	Read(p []byte) (n int, err error)
}
type Closer interface {
	Close() error
}
// ReadCloser接口是Reader、Closer接口组合而成，也就是说它拥有Read、Close方法声明。
type ReadCloser interface {
	Reader
	Closer
}
```

# 三、空接口

空接口，实际上是空接口类型，写作 `interface {}`。

为了方便使用，Go语言为它定义一个别名 any 类型，即 `type any = interface{} `。

空接口，没有任何方法声明，因此，任何类型都无需显式实现空接口的方法，因为任何类型都满足这个 空接口的要求。那么，任何类型的值都可以看做是空接口类型。

```go
package main

import "fmt"

func main() {
	var a = 3
	var b interface{} // 空接口类型可以适合接收任意类型的值
	b = a
	fmt.Printf("b:%T, %[1]v\n", b)

	var c = "abcd"
	b = c
	fmt.Printf("b:%T, %[1]v\n", b)
}
```

# 四、接口类型断言

接口类型断言（Type Assertions）可以将接口转换成另外一种接口，也可以将接口转换成另外的类型。 接口类型断言格式 `t := i.(T)`

- i 代表接口变量
- T 表示转换目标类型
- t 代表转换后的变量
- 断言失败，也就是说 i 没有实现 T 接口的方法则panic
- `t, ok := i.(T)`，则断言失败不 panic，通过 ok 是 true 或 false 判断 i 是否是 T 类型接口

```go
package main

import "fmt"

func main() {
	var b interface{} = 10
	if s, ok := b.(int); ok {
		fmt.Println(s)
	} else {
		fmt.Println("接口类型转换失败！")
	}
}
```

可以使用特殊格式`type-switch`来对接口做多种类型的断言。

```go
package main

import "fmt"

func main() {
	var b interface{} = 10
	// i.(type) 只能用在switch中。
	switch v := b.(type) {
	case nil:
		fmt.Println("nil", v)
	case string:
		fmt.Println("string", v)
	case int:
		fmt.Println("int", v)
	default:
		fmt.Println("其他类型", v)
	}
}
```

