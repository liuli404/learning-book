# 通道基本使用

## 定义

```go
package main

import "fmt"

func main() {
	// 无缓冲通道，容量为0，塞入数据就阻塞，直到数据被别人取走；取数据就阻塞，直到有人塞数据。
	// var c1 = make(chan int, 0)
	// 有缓冲通道，容量为8，可塞入8个int类型的数据，超出容量就阻塞，直到前面数据被取走，可将数据塞入。
	var c1 = make(chan int, 8)
	fmt.Println(cap(c1), len(c1), c1)
	// 塞入数据，先进先出
	c1 <- 110
	c1 <- 120
	c1 <- 130
	// 读取数据，先进先出
	fmt.Println(<-c1)
	fmt.Println(<-c1)
	fmt.Println(<-c1)
}
```

## 只读只写、同步通道

```go
package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

// 只写channel定义
func produce(ch chan<- int) {
	for {
		ch <- rand.Intn(10)
		time.Sleep(time.Second * 2)
	}
}

// 只读channel定义
func consume(ch <-chan int) {
	for {
		t := <-ch
		fmt.Printf("从生产者取到了数据：%d \n", t)
	}
}

func main() {
	var wg sync.WaitGroup
	wg.Add(1)
	c1 := make(chan int)
	go produce(c1)
	go consume(c1)
	wg.Wait()
}
```

