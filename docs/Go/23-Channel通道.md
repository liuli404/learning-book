

# 一、channel 基础

<img src="./23-Channel%E9%80%9A%E9%81%93/go-channels.png" alt="Understanding Go Channels: An Overview for Beginners" style="zoom:67%;" />

Channel 是 Go 中的一个核心类型，你可以把它看成一个管道，通过它并发核心单元就可以发送或者接收数据进行通讯(communication)。它的操作符是箭头`<-` （箭头的指向就是数据的流向）。

```go
ch <- v    // 发送值v到Channel ch中
v := <-ch  // 从Channel ch中接收数据，并将数据赋值给v
```

与 map 和 slice 数据类型一样，channel 必须先创建再使用：

```go
// make(chan 元素类型, [缓冲大小])
make(chan int, 8) // 有缓冲通道，容量为8，可塞入8个int类型的数据，超出容量就阻塞，直到前面数据被取走，可将数据塞入。
make(chan int, 0) or make(chan int) // 无缓冲通道，容量为0，塞入数据就阻塞，直到数据被别人取走；取数据就阻塞，直到有人塞数据。
```

**nil通道**：chan零值是nil，即可以理解未被初始化通道这个容器。nil通道可以认为是一个只要操作就阻 塞当前协程的容器。这种通道不要创建和使用，阻塞后无法解除，底层源码中写明了无法解除。

```go
var c1 chan int
```

# 二、channel 操作

```go
chan int        // 双向通道，可以接收和发送类型为 int 的数据
chan<- float64  // 只可以用来发送(send) float64 类型的数据
<-chan rune     // 只可以用来接收(receive) rune 类型的数据
```

## 2.1 双向通道

```go
func main() {
	ch := make(chan int, 4)
	// 塞入数据，先进先出
	ch <- 4
	ch <- 3
	ch <- 2
	ch <- 1
	// 读取数据，先进先出
	fmt.Println(<-ch) // 4
	fmt.Println(<-ch) // 3
	fmt.Println(<-ch) // 2
	fmt.Println(<-ch) // 1
}
```

## 2.2 单向通道

```go
// 只写通道
func sender(ch chan int) {
	for {
		ch <- rand.Intn(9)
		time.Sleep(time.Second * 1)
	}
}

// 只读通道
func reciver(ch chan int) {
	for {
		fmt.Println(<-ch)
	}
}

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	ch := make(chan int)
	go sender(ch)
	go reciver(ch)
	wg.Wait()
	wg.Done()
}
```

## 2.3 通道关闭

通过调用内置的 close 函数来关闭通道

```go
close(ch)
```

关于关闭通道需要注意的事情是，只有在通知接收方goroutine所有的数据都发送完毕的时候才需要关闭通道。通道是可以被垃圾回收机制回收的，它和关闭文件是不一样的，在结束操作之后关闭文件是必须要做的，但关闭通道不是必须的。

1. 对一个关闭的通道再发送值就会导致panic
2. 关闭一个已经关闭的通道会导致panic
3. 对一个关闭的通道进行**接收**会一直获取值直到通道为空
4. 对一个关闭的并且没有值的通道执行接收操作会得到对应类型的零值

只有发送方才能关闭通道，但接收者依然可以访问关闭的通道而不阻塞，接收方可以通过`t, ok := <-ch`，ok 的布尔值判断通道是否被关闭。

- 如果通道内还有剩余数据，ok为true，接收数据
- 如果通道内剩余的数据被拿完了，继续接收不阻塞，ok为false，返回零值

```go
func main() {
	ch := make(chan int)
	go func(chan int) {
		for i := 0; i < 5; i++ {
			ch <- i
		}
		close(ch)
	}(ch)

	for {
		data, ok := <-ch
		if !ok {
			break
		}
		fmt.Println(data)
	}
}
```



# 三、channel 缓冲

## 3.1 无缓冲通道

<img src="./23-Channel%E9%80%9A%E9%81%93/3.png" alt="img" style="zoom: 67%;" />

```go
func main() {
    ch := make(chan int)
    ch <- 10
    fmt.Println("发送成功")
}
```

无缓冲通道又称阻塞通道、同步通道，以上代码编译后运行会出现死锁错误。

```go
fatal error: all goroutines are asleep - deadlock!
```

因为 `ch := make(chan int)` 创建了一个容量为0的通道，只有在有人接收值的的时候才能发送值，否则将一直阻塞在这里，而当前程序只有一个 main 协程，所以整个程序都将被阻塞。

无缓冲通道就像你住的小区没有快递柜，快递员给你打电话必须要把这个快递送到你的手中，否则快递无人取，就被阻塞住了。

解决方案：我们可以提前起一个 goroutine 去接收这个 channel 就可以了（起的协程阻塞并不会影响main协程）。

```go
func main() {
	ch := make(chan int)
	// 先启动一个协程接收阻塞状态
	go func(chan int) {
		t := <-ch
		fmt.Println("接收成功：", t)
	}(ch)
	// 只要塞入数据，就被之前的协程接收
	ch <- 10
	fmt.Println("发送成功")
}
```

## 3.2 有缓冲通道

<img src="./23-Channel%E9%80%9A%E9%81%93/4.png" alt="img" style="zoom:67%;" />

只要通道的容量大于零，那么该通道就是有缓冲的通道，通道的容量表示通道中能存放元素的数量。

```go
func main() {
    ch := make(chan int, 3) // 创建一个容量为3的有缓冲区通道
    ch <- 10
    fmt.Println("发送成功")
}
```

有缓冲通道就像你小区的快递柜只有那么个多格子，格子满了就装不下了，就阻塞了，等到别人取走一个快递员就能往里面放一个。

# 四、channel 遍历

## 4.1 有缓冲、未关闭通道

相当于一个无限元素的通道，迭代不完，阻塞在等下一个元素到达，死锁。

```go
func main() {
	ch := make(chan int, 4)
	ch <- 1
	ch <- 2
	ch <- 3

	for v := range ch {
		fmt.Println(v)
	}
	fmt.Println("通道遍历结束")
}
```

运行结果

```go
1
2
3
fatal error: all goroutines are asleep - deadlock!
```



## 4.2 有缓冲、关闭的通道

关闭后，通道不能再进入新的元素，那么相当于遍历有限个元素容器，遍历完就结束了。

```go
func main() {
	ch := make(chan int, 4)
	ch <- 1
	ch <- 2
	ch <- 3
	close(ch)
	for v := range ch {
		fmt.Println(v)
	}
	fmt.Println("通道遍历结束")
}
```

运行结果

```go
1
2
3
通道遍历结束
```

## 4.3 无缓冲、未关闭通道

相当于一个无限元素的通道，迭代不完，阻塞在等下一个元素到达。

```go
func main() {
	ch := make(chan int)

	go func() {
		ch <- 1
		ch <- 2
		ch <- 3
	}()

	for v := range ch {
		fmt.Println(v)
	}
	fmt.Println("通道遍历结束")
}
```

运行结果

```go
1
2
3
fatal error: all goroutines are asleep - deadlock!
```

## 4.4 无缓冲、关闭的通道

关闭后，通道不能在进入新的元素，那么相当于遍历有限个元素容器，遍历完就结束了。

```go
func main() {
	ch := make(chan int)

	go func() {
		ch <- 1
		ch <- 2
		ch <- 3
		close(ch)
	}()

	for v := range ch {
		fmt.Println(v)
	}
	fmt.Println("通道遍历结束")
}
```

运行结果

```go
1
2
3
通道遍历结束
```

# 五、定时器

通过定时器可以延时定时执行

- Timer：时间到了，执行只执行1次

```go
func main() {
	t := time.NewTimer(2 * time.Second)
	for {
		fmt.Println(<-t.C) // 通道阻塞2秒后只能接收一次
	}
}
```

- Ticker：时间到了，多次执行

```go
func main() {
	t := time.NewTicker(2 * time.Second)
	for {
		fmt.Println(<-t.C) // 通道每阻塞2秒就接收一次
	}
}
```

# 六、struct{}型通道

如果一个结构体类型就是struct{}，说明该结构体的实例没有数据成员，也就是实例内存占用为0。

这种类型数据构成的通道，非常节约内存，仅仅是为了传递一个信号标志。

```go
func main() {
	ch := make(chan struct{})

	go func(chan struct{}) {
		time.Sleep(3 * time.Second)
		ch <- struct{}{}
		close(ch)
	}(ch)

	signal := <-ch

	fmt.Println("收到信号！", signal)
}
```

# 七、channel 多路复用

go语言使用`select`来同时监听多个 channel。

```go
func main() {
	ch := make(chan int, 5)
	signal := make(chan struct{})

	go func() {
		defer func() {
			signal <- struct{}{}
		}()
		defer close(ch)
		for i := 0; i < 5; i++ {
			time.Sleep(time.Second)
			ch <- i
		}
	}()
	
	for {
        // select 监听两个 channel 谁不阻塞输出谁
		select {
		case n := <-ch:
			fmt.Println(n)
		case <-signal:
			fmt.Println("结束")
			goto END
		}
	}

END:
	fmt.Println("Done")
}
```

# 八、channel 并发

Go语言采用并发同步模型叫做CSP（Communication Sequential Process）通讯顺序进程，这是一种消息传递模型，在goroutine间传递消息， 而不是内存共享对数据进行加锁来实现同步访问。

在goroutine之间使用channel来同步和传递数据。

- 多个协程之间通讯的管道
- 一端推入数据，一端拿走数据
- 同一时间，只有一个协程可以访问通道的数据
- 协调协程的执行顺序

如果多个线程都使用了同一个数据，就会出现竞争问题。因为线程的切换不会听从程序员的意志，时间片用完就切换了。解决办法往往需要**加锁**，让其他线程不能对共享数据进行修改，从而保证逻辑正确。 但锁的引入严重**影响并行效率**。



有一个全局数count，初始为0。编写一个函数inc，对count增加100万次。执行5次inc函数，请问最终count值是多少？

## 8.1 串行

```go
package main

import (
	"fmt"
	"runtime"
	"time"
)

var count int64 = 0

func inc() {
	for i := 0; i < 1000000; i++ {
		count++
	}
}

func main() {
	start := time.Now()
	inc()
	inc()
	inc()
	inc()
	inc()
	fmt.Printf("协程数量：%d \n", runtime.NumGoroutine())
	fmt.Printf("计算用时：%d \n", time.Since(start).Microseconds())
	fmt.Printf("计算结果：%d \n", count)
}
```

运行结果

```go
协程数量：1 
计算用时：4548 
计算结果：5000000 
```

## 8.2 goroutine 并行

```go
package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

var count int64 = 0
var wg sync.WaitGroup

func inc() {
	defer wg.Done()
	for i := 0; i < 1000000; i++ {
		count++
	}
}

func main() {
	wg.Add(5)
	start := time.Now()
	for i := 0; i < 5; i++ {
		go inc()
	}
	fmt.Printf("协程数量：%d \n", runtime.NumGoroutine())
	wg.Wait()
	fmt.Printf("计算用时：%d \n", time.Since(start).Microseconds())
	fmt.Printf("计算结果：%d \n", count)
}
```

运行结果
```go
协程数量：6 
计算用时：26913 
计算结果：1314586
```

## 8.3 atomic 原子并行

代码中的加锁操作因为涉及内核态的上下文切换会比较耗时、代价比较高。针对基本数据类型我们还可以使用原子操作来保证并发安全，因为原子操作是Go语言提供的方法它在用户态就可以完成，因此性能比加锁操作更好。Go语言中原子操作由内置的标准库sync/atomic提供。

```go
package main

import (
	"fmt"
	"runtime"
	"sync"
	"sync/atomic"
	"time"
)

var count int64 = 0
var wg sync.WaitGroup

func inc() {
	defer wg.Done()
	for i := 0; i < 1000000; i++ {
		atomic.AddInt64(&count, 1)
	}
}

func main() {
	wg.Add(5)
	start := time.Now()
	for i := 0; i < 5; i++ {
		go inc()
	}
	fmt.Printf("协程数量：%d \n", runtime.NumGoroutine())
	wg.Wait()
	fmt.Printf("计算用时：%d \n", time.Since(start).Microseconds())
	fmt.Printf("计算结果：%d \n", count)
}
```

运行结果

```go
协程数量：6 
计算用时：59157 
计算结果：5000000 
```

## 8.3 mutex 互斥锁并行

互斥锁是一种常用的控制共享资源访问的方法，它能够保证同时只有一个goroutine可以访问共享资源。Go语言中使用sync包的Mutex类型来实现互斥锁。

使用互斥锁能够保证同一时间有且只有一个goroutine进入临界区，其他的goroutine则在等待锁；当互斥锁释放后，等待的goroutine才可以获取锁进入临界区，多个goroutine同时等待一个锁时，唤醒的策略是随机的。

```go
package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

var count int64 = 0
var wg sync.WaitGroup
var mx sync.Mutex

func inc() {
	defer wg.Done()
	for i := 0; i < 1000000; i++ {
		mx.Lock()
		count++
		mx.Unlock()
	}
}

func main() {
	wg.Add(5)
	start := time.Now()
	for i := 0; i < 5; i++ {
		go inc()
	}
	fmt.Printf("协程数量：%d \n", runtime.NumGoroutine())
	wg.Wait()
	fmt.Printf("计算用时：%d \n", time.Since(start).Microseconds())
	fmt.Printf("计算结果：%d \n", count)
}
```

运行结果

```go
协程数量：6 
计算用时：146164 
计算结果：5000000
```



## 8.4 channel 协程并行

```go
package main

import (
	"fmt"
	"runtime"
	"sync"
	"time"
)

var wg sync.WaitGroup
var ch = make(chan int64, 1)

func inc() {
	defer wg.Done()
	for i := 0; i < 1000000; i++ {
		t := <-ch
		t++
		ch <- t
	}
}

func main() {
	wg.Add(5)
	start := time.Now()
	ch <- 0
	for i := 0; i < 5; i++ {
		go inc()
	}
	fmt.Printf("协程数量：%d \n", runtime.NumGoroutine())
	wg.Wait()
	fmt.Printf("计算用时：%d \n", time.Since(start).Microseconds())
	fmt.Printf("计算结果：%d \n", <-ch)
}
```

运行结果

```go
协程数量：6 
计算用时：1238739 
计算结果：5000000 
```



## 8.5 并行方法总结

|           | 耗时 / us                | 说明                                                       |
| --------- | ------------------------ | ---------------------------------------------------------- |
| 串行      | 4548                     | 串行，没有用到并发                                         |
| goroutine | 26913 （快，但结果错了） | count++不是原子操作，会被打断，即使使用goroutine也会有竞争 |
| atomic    | 59157                    | atomic这种共享内存的方式执行时长明显增加                   |
| mutex     | 146164                   | mutex互斥锁也能保证count++的原子性操作                     |
| channel   | 1238739                  | channel通道可以保证每次通道内只有1个计算数                 |

上例是计算密集型，对同一个数据进行争抢，不是能发挥并行计算优势的例子，也不适合使用通道，用锁实现更有效率，更有优势。

通道适合数据流动的场景：

- 如同管道一样，一级一级处理，一个协程处理完后，发送给其他协程
- 生产者、消费者模型，M:N
