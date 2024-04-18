# 一、错误信息

Go 的设计者认为其它语言异常处理太过消耗资源，且设计和处理复杂，导致使用者不能很好的处理错误，甚至觉得异常和错误处理起来麻烦而被忽视、忽略掉，从而导致程序崩溃。

为了解决这些问题，Go将错误处理设计的非常简单

- 函数调用，返回值可以返回多值，一般最后一个值可以是error接口类型的值
  - 如果函数调用产生错误，则这个值是一个error接口类型的错误
  - 如果函数调用成功，则该值是`nil`
- 检查函数返回值中的错误是否是`nil`，如果不是`nil`，进行必要的错误处理

error 类型是一个接口类型，这是它的定义：

```go
type error interface {
    Error() string
}
```

所有实现 `Error() string` 签名的方法，都可以实现错误接口。用`Error()`方法返回错误的具体描述。

## 1.1 通过实现 Error() 方法

```go
package main

import "fmt"

// 定义结构体
type errString struct {
	s string
}

// 实现 Error 接口
func (e *errString) Error() string {
	return e.s
}

func NewErr(text string) error {
	return &errString{text}
}

func main() {
	var e = errString{"错误理由1"}
	fmt.Println(e, e.Error(), &e, (&e).Error()) // {错误理由1} 错误理由1 错误理由1 错误理由1

	var err = NewErr("错误理由2")
	fmt.Println(err, err.Error(), &err) // 错误理由2 错误理由2 0xc000088280
}
```

## 1.2 通过 errors 包的 New 方法

```go
package main

import (
	"errors"
	"fmt"
)

// 构造一个自定义的错误实例
var ErrDivisionByZero = errors.New("Division By Zero Error!")

// 除法函数
func div(a, b int) (int, error) {
	if b == 0 {
		return 0, ErrDivisionByZero
	}
	return a / b, nil
}

func main() {
	r, err := div(2, 0)
	if err != nil {
		fmt.Println(err)  // Division By Zero Error!
	} else {
		fmt.Println(r)
	}
}
```

# 二、panic、recover 

panic 与 recover 是 Go 的两个内置函数，这两个内置函数用于处理 Go 运行时的错误，panic 用于主动抛出错误，recover 用来捕获 panic 抛出的错误。

- panic：崩溃，宕机。是不好的，因为它发生时，往往会造成程序崩溃、服务终止等后果，所以没人希望它发生。但是， 如果在错误发生时，不及时panic而终止程序运行，继续运行程序恐怕造成更大的损失，付出更加惨痛的代价。所以，有时候，panic 导致的程序崩溃实际上可以及时止损，只能两害相权取其轻。
- recover：恢复，defer 和 recover 结合起来，在 defer 中调用 recover 来实现对错误的捕获和恢复，让代码在发生 panic 后通过处理能够继续运行。类似其它语言中 try/catch。

## 2.1 painc 产生

引发`panic`有两种情况

- 一是程序 runtime 运行时错误抛出，比如数组越界、除零错误。

```go
package main

import "fmt"

func div(a, b int) int {
	res := a / b // runtime 运行时有可能产生除零错误，painc抛出错误
	return res
}
func main() {
	fmt.Printf("div(4, 0): %v\n", div(4, 0))
}
```

运行结果

```go
panic: runtime error: integer divide by zero
```

- 二是主动手动调用panic(reason)，这个reason可以是任意类型。

```go
package main

import "fmt"

func div(a, b int) int {
	if b == 0 {
		panic("除数为0了") // 主动调用 panic(reason)
	}
	res := a / b
	return res
}
func main() {
	fmt.Printf("div(4, 0): %v\n", div(4, 0))
}
```

运行结果

```go
panic: 除数为0了
```

## 2.2 painc 执行

- 发生`panic`后，程序会从调用`panic`的函数位置或发生`panic`的地方立即返回，逐层向上执行函数的`defer`语句，然后逐层打印函数调用堆栈，直到被`recover`捕获或运行到最外层函数。

- `panic`不但可以在函数正常流程中抛出，在`defer`逻辑里也可以再次调用`panic`或抛出`panic`。`defer`里面的`panic`能够被后续执行的`defer`捕获。
- `recover`用来捕获`panic`，阻止`panic`继续向上传递。`recover()`和`defer`一起使用，但是`defer`只有在后面的函数体内直接被掉用才能捕获`panic`来终止异常，否则返回`nil`，异常继续向外传递。

```go
package main

import (
	"errors"
	"fmt"
	"runtime"
)

/*
一旦在某函数中 panic，当前函数 panic 之后的语句将不再执行，开始执行 defer。
如果在 defer 中错误被 recover 后，就相当于当前函数产生的错误得到了处理。
当前函数执行完 defer，当前函数退出执行，程序还可以从当前函数之后继续执行。
*/

// 自定义错误提示信息
var ErrDivisionByZero = errors.New("除零异常")

func div(a, b int) int {
	defer fmt.Println("start")
	defer fmt.Println(a, b)
	defer func() {
		err := recover() // 一旦recover了，就相当处理过了错误
		fmt.Printf("%+v,%[1]T,%v\n", err, ErrDivisionByZero)
		switch v := err.(type) { // 类型断言
		case runtime.Error:
			fmt.Printf("原因：%T, %#[1]v\n", v)
		case []int:
			fmt.Println("原因：切片")
		}
		fmt.Println("离开recover处理")
	}()
	r := a / b
	return r
}
func main() {
	fmt.Println("计算结果：", div(5, 0))
}
```

运行结果

```go
runtime error: integer divide by zero,runtime.errorString,除零异常
原因：runtime.errorString, "integer divide by zero"
离开recover处理
5 0
start
计算结果： 0
```



可以观察到panic和recover有如下

- 有panic，一路向外抛出，但没有一处进行recover，也就是说没有地方处理错误，程序崩溃
- 有painc，有recover来捕获，相当于错误被处理掉了，当前函数defer执行完后，退出当前函数， 从当前函数之后继续执行
